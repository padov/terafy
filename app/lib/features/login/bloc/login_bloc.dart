import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/services/auth_service.dart';
import 'package:terafy/core/services/secure_storage_service.dart';
import 'package:terafy/core/domain/entities/auth_result.dart';
import 'package:terafy/core/domain/usecases/auth/login_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/logout_usecase.dart';
import 'package:common/common.dart';
import 'login_bloc_models.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final LogoutUseCase logoutUseCase;
  final SecureStorageService secureStorageService;
  final AuthService authService;

  LoginBloc({
    required this.loginUseCase,
    required this.signInWithGoogleUseCase,
    required this.getCurrentUserUseCase,
    required this.refreshTokenUseCase,
    required this.logoutUseCase,
    required this.secureStorageService,
    required this.authService,
  }) : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<LoginWithBiometrics>(_onLoginWithBiometrics);
    on<LoginWithGooglePressed>(_onLoginWithGooglePressed);
    on<CheckBiometricLogin>(_onCheckBiometricLogin);
    on<CheckTokenValidity>(_onCheckTokenValidity);
    on<BiometricsPreferenceChanged>(_onBiometricsPreferenceChanged);
    on<LogoutPressed>(_onLogoutPressed);

    // Verifica automaticamente se deve tentar login biométrico ou validar token ao inicializar
    // Usa Future.microtask para garantir que seja executado após a inicialização completa
    Future.microtask(() => add(CheckBiometricLogin()));
  }

  Future<void> _onBiometricsPreferenceChanged(
    BiometricsPreferenceChanged event,
    Emitter<LoginState> emit,
  ) async {
    AppLogger.func();
    AppLogger.info(
      '🛠️ EVENTO BiometricsPreferenceChanged -> enabled: ${event.enabled}',
    );

    if (!event.enabled) {
      AppLogger.info('🧹 Removendo userIdentifier do storage (biometria off)');
      await secureStorageService.deleteUserIdentifier();
    }
  }

  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    log(
      'Evento LoginButtonPressed recebido no Bloc com email: ${event.email}',
      name: 'LoginBloc',
    );
    emit(LoginLoading());
    try {
      final AuthResult authResult = await loginUseCase(
        event.email,
        event.password,
      );

      if (authResult.error != null) {
        emit(LoginFailure(error: authResult.error!));
        return;
      }

      if (authResult.client != null && authResult.authToken != null) {
        final client = authResult.client!;

        // Só salva o token no storage se o cadastro estiver completo (accountId != null)
        // Se accountId == null, salva temporariamente em memória para permitir completar o perfil
        if (client.accountId != null) {
          await secureStorageService.saveToken(authResult.authToken!);
          // Salva refresh token se disponível
          if (authResult.refreshAuthToken != null) {
            await secureStorageService.saveRefreshToken(
              authResult.refreshAuthToken!,
            );
          }
        } else {
          // Cadastro incompleto: salva token temporariamente em memória (não persiste)
          // Isso permite que o CompleteProfileBloc faça requisições para carregar dados
          // O token será salvo no storage apenas após completar o perfil
          secureStorageService.saveTemporaryToken(authResult.authToken!);
          if (authResult.refreshAuthToken != null) {
            secureStorageService.saveTemporaryRefreshToken(
              authResult.refreshAuthToken!,
            );
          }
          AppLogger.info(
            '⚠️ Cadastro incompleto (accountId == null). Token salvo temporariamente em memória.',
          );
        }

        if (event.isBiometricsEnabled) {
          AppLogger.info('✅ Biometria habilitada pelo usuário');
          // Verifica se o dispositivo suporta biometria antes de tentar salvar
          final canCheckBiometrics = await authService.canCheckBiometrics();
          AppLogger.variable(
            'canCheckBiometrics',
            canCheckBiometrics.toString(),
          );

          if (canCheckBiometrics) {
            // Salva o identificador do usuário para biometria
            AppLogger.info('💾 Salvando userIdentifier...');
            await secureStorageService.saveUserIdentifier(event.email);

            // Solicita autenticação biométrica imediatamente para confirmar/ativar
            try {
              AppLogger.info(
                '📞 CHAMANDO authService.authenticate() após login...',
              );
              final isAuthenticated = await authService.authenticate();
              AppLogger.variable(
                'isAuthenticated resultado',
                isAuthenticated.toString(),
              );

              final requiresCompletion = client.accountId == null;
              if (isAuthenticated) {
                // Biometria confirmada com sucesso, finaliza o login
                emit(
                  LoginSuccess(
                    client: client,
                    requiresProfileCompletion: requiresCompletion,
                  ),
                );
              } else {
                // Usuário cancelou a biometria, mas já está logado
                // Mantém a biometria salva para próximas vezes e finaliza o login
                emit(
                  LoginSuccess(
                    client: client,
                    requiresProfileCompletion: requiresCompletion,
                  ),
                );
              }
            } catch (e) {
              // Em caso de erro na biometria, mantém a biometria salva e finaliza o login
              log(
                'Erro ao solicitar biometria após login: $e',
                name: 'LoginBloc',
              );
              emit(
                LoginSuccess(
                  client: client,
                  requiresProfileCompletion: client.accountId == null,
                ),
              );
            }
          } else {
            // Dispositivo não suporta biometria ou não está configurada
            // Não salva o userIdentifier e finaliza o login normalmente
            await secureStorageService.deleteUserIdentifier();
            log(
              'Biometria não disponível no dispositivo. Login concluído sem biometria.',
              name: 'LoginBloc',
            );
            emit(
              LoginSuccess(
                client: client,
                requiresProfileCompletion: client.accountId == null,
              ),
            );
          }
        } else {
          await secureStorageService.deleteUserIdentifier();
          emit(
            LoginSuccess(
              client: client,
              requiresProfileCompletion: client.accountId == null,
            ),
          );
        }
      } else {
        throw Exception('Resposta de autenticação inválida.');
      }
    } catch (e) {
      emit(LoginFailure(error: e.toString()));
    }
  }

  Future<void> _onLoginWithGooglePressed(
    LoginWithGooglePressed event,
    Emitter<LoginState> emit,
  ) async {
    log('Evento LoginWithGooglePressed recebido no Bloc.', name: 'LoginBloc');
    emit(LoginLoading());
    try {
      final AuthResult authResult = await signInWithGoogleUseCase();

      if (authResult.error != null) {
        emit(LoginFailure(error: authResult.error!));
        return;
      }

      if (authResult.client != null && authResult.authToken != null) {
        await secureStorageService.saveToken(authResult.authToken!);
        // Salva refresh token se disponível
        if (authResult.refreshAuthToken != null) {
          await secureStorageService.saveRefreshToken(
            authResult.refreshAuthToken!,
          );
        }
        // Para login social, não salvaremos o identificador para biometria
        // a menos que o usuário explicitamente habilite em outro lugar.
        await secureStorageService.deleteUserIdentifier();
        emit(LoginSuccess(client: authResult.client!));
      } else {
        throw Exception('Resposta de autenticação inválida.');
      }
    } catch (e) {
      emit(LoginFailure(error: e.toString()));
    }
  }

  Future<void> _onCheckBiometricLogin(
    CheckBiometricLogin event,
    Emitter<LoginState> emit,
  ) async {
    AppLogger.func();
    AppLogger.info('🔍 EVENTO CheckBiometricLogin - Verificando condições...');
    // Verifica se há credenciais de biometria salvas e se o dispositivo suporta
    try {
      final token = await secureStorageService.getToken();
      final refreshToken = await secureStorageService.getRefreshToken();
      final userIdentifier = await secureStorageService.getUserIdentifier();
      final canCheckBiometrics = await authService.canCheckBiometrics();

      AppLogger.variable('token existe?', (token != null).toString());
      AppLogger.variable(
        'refreshToken existe?',
        (refreshToken != null).toString(),
      );
      AppLogger.variable(
        'userIdentifier existe?',
        (userIdentifier != null).toString(),
      );
      AppLogger.variable('userIdentifier valor', userIdentifier ?? 'null');
      AppLogger.variable('canCheckBiometrics', canCheckBiometrics.toString());

      // Se todas as condições são atendidas, tenta login biométrico automaticamente
      if (token != null && userIdentifier != null && canCheckBiometrics) {
        AppLogger.info(
          '✅ Todas as condições OK! Disparando LoginWithBiometrics...',
        );
        // Dispara o login biométrico automaticamente
        add(LoginWithBiometrics());
      } else {
        AppLogger.warning(
          '⚠️ Condições não atendidas. Não disparando login biométrico.',
        );
        AppLogger.variable('token != null?', (token != null).toString());
        AppLogger.variable(
          'userIdentifier != null?',
          (userIdentifier != null).toString(),
        );
        AppLogger.variable(
          'canCheckBiometrics?',
          canCheckBiometrics.toString(),
        );

        // Se tem token mas não tem biometria configurada,
        // tenta validar o token diretamente
        if (token != null && (userIdentifier == null || !canCheckBiometrics)) {
          AppLogger.info(
            '🔍 Token encontrado mas sem biometria. Tentando validar token...',
          );
          add(CheckTokenValidity());
        }

        // Se não há access token mas temos refresh token, tenta renovar
        if (token == null && refreshToken != null) {
          AppLogger.info(
            '🔄 Nenhum access token, mas refresh token disponível. Tentando renovar...',
          );
          add(CheckTokenValidity());
        }
      }
    } catch (e) {
      // Em caso de erro na verificação, apenas mantém o estado inicial
      log('Erro ao verificar login biométrico: $e', name: 'LoginBloc');
    }
  }

  Future<void> _onCheckTokenValidity(
    CheckTokenValidity event,
    Emitter<LoginState> emit,
  ) async {
    AppLogger.func();
    AppLogger.info('🔍 EVENTO CheckTokenValidity - Verificando token...');

    try {
      final token = await secureStorageService.getToken();
      final refreshToken = await secureStorageService.getRefreshToken();

      // Se não tem token, tenta usar refresh token
      if (token == null) {
        if (refreshToken != null) {
          AppLogger.info(
            'ℹ️ Nenhum access token, mas refresh token disponível. Tentando refresh...',
          );
          await _tryRefreshToken(refreshToken, emit);
        } else {
          AppLogger.info(
            'ℹ️ Nenhum access token ou refresh token encontrado. Mantendo tela de login.',
          );
        }
        return;
      }

      AppLogger.info('🔍 Token encontrado. Tentando validar...');

      // Tenta validar o token atual chamando /auth/me
      try {
        final authResult = await getCurrentUserUseCase();

        if (authResult.error != null) {
          // Token inválido, tenta refresh
          AppLogger.warning('⚠️ Token inválido. Tentando refresh...');
          await _tryRefreshToken(refreshToken, emit);
          return;
        }

        if (authResult.client != null) {
          final client = authResult.client!;

          // Se o token é válido mas o perfil não está completo (accountId == null),
          // isso não deveria acontecer (tokens sem accountId não são salvos),
          // mas por segurança, limpa o token e mantém na tela de login
          if (client.accountId == null) {
            AppLogger.warning(
              '⚠️ Token válido mas perfil incompleto (accountId == null). '
              'Isso não deveria acontecer. Limpando token e mantendo na tela de login.',
            );
            await secureStorageService.deleteToken();
            await secureStorageService.deleteRefreshToken();
            await secureStorageService.deleteUserIdentifier();
            secureStorageService.clearTemporaryTokens();
            // Mantém na tela de login - não faz auto-login
            return;
          }

          // Token válido e perfil completo! Usuário já está autenticado
          AppLogger.info('✅ Token válido! Usuário autenticado.');
          emit(LoginSuccess(client: client, requiresProfileCompletion: false));
          return;
        }
      } catch (e) {
        // Erro ao validar token, tenta refresh
        AppLogger.warning('⚠️ Erro ao validar token: $e. Tentando refresh...');
        await _tryRefreshToken(refreshToken, emit);
        return;
      }
    } catch (e) {
      AppLogger.warning('❌ Erro ao verificar validade do token: $e');
      // Em caso de erro, mantém na tela de login
    }
  }

  /// Tenta renovar o token usando refresh token
  Future<void> _tryRefreshToken(
    String? refreshToken,
    Emitter<LoginState> emit,
  ) async {
    AppLogger.func();

    if (refreshToken == null) {
      AppLogger.warning('⚠️ Refresh token não disponível. Limpando tokens...');
      await secureStorageService.deleteToken();
      await secureStorageService.deleteRefreshToken();
      await secureStorageService.deleteUserIdentifier();
      return;
    }

    try {
      AppLogger.info('🔄 Tentando renovar token com refresh token...');
      final result = await refreshTokenUseCase.call(refreshToken);

      // Salva novos tokens
      if (result.authToken != null) {
        await secureStorageService.saveToken(result.authToken!);
        AppLogger.info('✅ Novo access token salvo');
      }
      if (result.refreshAuthToken != null) {
        await secureStorageService.saveRefreshToken(result.refreshAuthToken!);
        AppLogger.info('✅ Novo refresh token salvo');
      }

      // Agora tenta obter dados do usuário com o novo token
      final authResult = await getCurrentUserUseCase();

      if (authResult.client != null) {
        final client = authResult.client!;

        // Se o perfil não está completo (accountId == null),
        // isso não deveria acontecer (tokens sem accountId não são salvos),
        // mas por segurança, limpa o token e mantém na tela de login
        if (client.accountId == null) {
          AppLogger.warning(
            '⚠️ Token renovado mas perfil incompleto (accountId == null). '
            'Isso não deveria acontecer. Limpando token e mantendo na tela de login.',
          );
          await secureStorageService.deleteToken();
          await secureStorageService.deleteRefreshToken();
          await secureStorageService.deleteUserIdentifier();
          secureStorageService.clearTemporaryTokens();
          // Mantém na tela de login - não faz auto-login
          return;
        }

        AppLogger.info('✅ Token renovado e usuário autenticado!');
        emit(LoginSuccess(client: client, requiresProfileCompletion: false));
      } else {
        throw Exception('Não foi possível obter dados do usuário após refresh');
      }
    } catch (e) {
      AppLogger.warning('❌ Falha ao renovar token: $e');
      // Refresh falhou, limpa tokens e mantém na tela de login
      await secureStorageService.deleteToken();
      await secureStorageService.deleteRefreshToken();
      await secureStorageService.deleteUserIdentifier();
    }
  }

  Future<void> _onLoginWithBiometrics(
    LoginWithBiometrics event,
    Emitter<LoginState> emit,
  ) async {
    AppLogger.func();
    AppLogger.info('🔐 EVENTO LoginWithBiometrics recebido!');
    emit(LoginLoading());
    try {
      // Primeiro verifica se temos token e identificador salvos
      AppLogger.info('🔍 Verificando credenciais salvas...');
      final token = await secureStorageService.getToken();
      final userIdentifier = await secureStorageService.getUserIdentifier();

      AppLogger.variable('token existe?', (token != null).toString());
      AppLogger.variable(
        'userIdentifier existe?',
        (userIdentifier != null).toString(),
      );
      AppLogger.variable('userIdentifier valor', userIdentifier ?? 'null');

      if (token == null || userIdentifier == null) {
        AppLogger.warning(
          '⚠️ Não há credenciais salvas. Mantendo tela de login.',
        );
        emit(LoginInitial()); // Não há credenciais, mantém na tela de login
        return;
      }

      // Solicita autenticação biométrica
      AppLogger.info('📞 CHAMANDO authService.authenticate()...');
      final isAuthenticated = await authService.authenticate();
      AppLogger.variable(
        'isAuthenticated resultado',
        isAuthenticated.toString(),
      );
      if (!isAuthenticated) {
        AppLogger.warning('⚠️ Usuário não está autenticado com a biometria');
        emit(LoginInitial()); // Usuário cancelou a biometria
        return;
      }

      // Se a biometria foi confirmada, valida o token no backend
      try {
        final authResult = await getCurrentUserUseCase();

        if (authResult.error != null) {
          // Token inválido ou expirado
          await secureStorageService.deleteToken();
          await secureStorageService.deleteRefreshToken();
          await secureStorageService.deleteUserIdentifier();
          emit(LoginFailure(error: authResult.error!));
          return;
        }

        AppLogger.variable(
          'authResult client id',
          authResult.client?.id.toString() ?? 'null',
        );

        if (authResult.client != null) {
          final client = authResult.client!;

          // Se o perfil não está completo (accountId == null),
          // isso não deveria acontecer (tokens sem accountId não são salvos),
          // mas por segurança, limpa o token e mantém na tela de login
          if (client.accountId == null) {
            AppLogger.warning(
              '⚠️ Login biométrico bem-sucedido mas perfil incompleto (accountId == null). '
              'Isso não deveria acontecer. Limpando token e mantendo na tela de login.',
            );
            await secureStorageService.deleteToken();
            await secureStorageService.deleteRefreshToken();
            await secureStorageService.deleteUserIdentifier();
            secureStorageService.clearTemporaryTokens();
            emit(LoginInitial()); // Mantém na tela de login
            return;
          }

          // Token válido e perfil completo, usuário autenticado com sucesso
          emit(LoginSuccess(client: client, requiresProfileCompletion: false));
        } else {
          throw Exception('Erro ao obter dados do usuário.');
        }
      } catch (e) {
        // Se falhar ao validar token, limpa as credenciais
        await secureStorageService.deleteToken();
        await secureStorageService.deleteRefreshToken();
        await secureStorageService.deleteUserIdentifier();
        emit(
          LoginFailure(
            error: 'Token inválido ou expirado. Faça login novamente.',
          ),
        );
      }
    } catch (e) {
      log('Erro no login biométrico: $e', name: 'LoginBloc');
      emit(LoginInitial()); // Em caso de erro, volta ao estado inicial
    }
  }

  Future<void> _onLogoutPressed(
    LogoutPressed event,
    Emitter<LoginState> emit,
  ) async {
    AppLogger.func();
    log('Evento LogoutPressed recebido no Bloc.', name: 'LoginBloc');

    try {
      // Obtém tokens antes de deletar para enviar ao backend
      final refreshToken = await secureStorageService.getRefreshToken();
      final accessToken = await secureStorageService.getToken();

      // Tenta fazer logout no backend (revoga refresh token e adiciona access token à blacklist)
      try {
        AppLogger.info('🔄 Tentando fazer logout no servidor...');
        await logoutUseCase.call(
          refreshToken: refreshToken,
          accessToken: accessToken,
        );
        AppLogger.info('✅ Logout no servidor realizado com sucesso');
      } catch (e) {
        // Log erro, mas continua com logout local
        AppLogger.warning('⚠️ Erro ao fazer logout no servidor: $e');
        AppLogger.info('🔄 Continuando com logout local...');
      }

      // Sempre remove tokens localmente, mesmo se logout no servidor falhar
      await secureStorageService.deleteToken();
      await secureStorageService.deleteRefreshToken();
      await secureStorageService.deleteUserIdentifier();

      log('Logout realizado com sucesso.', name: 'LoginBloc');
      emit(LogoutSuccess());
    } catch (e) {
      log('Erro ao fazer logout: $e', name: 'LoginBloc');
      // Mesmo em caso de erro, limpa storage e emite LogoutSuccess
      // para garantir que o usuário seja deslogado
      try {
        await secureStorageService.deleteToken();
        await secureStorageService.deleteRefreshToken();
        await secureStorageService.deleteUserIdentifier();
      } catch (_) {
        // Ignora erros ao limpar storage
      }
      emit(LogoutSuccess());
    }
  }
}
