import 'package:common/common.dart';
import 'package:terafy/core/domain/entities/auth_result.dart';
import 'package:terafy/core/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/login_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/logout_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:terafy/core/services/auth_service.dart';
import 'package:terafy/core/services/secure_storage_service.dart';

class SessionManager {
  final LoginUseCase _loginUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final LogoutUseCase _logoutUseCase;
  final SecureStorageService _secureStorageService;
  final AuthService _authService;

  SessionManager({
    required LoginUseCase loginUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required RefreshTokenUseCase refreshTokenUseCase,
    required LogoutUseCase logoutUseCase,
    required SecureStorageService secureStorageService,
    required AuthService authService,
  }) : _loginUseCase = loginUseCase,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _refreshTokenUseCase = refreshTokenUseCase,
       _logoutUseCase = logoutUseCase,
       _secureStorageService = secureStorageService,
       _authService = authService;

  /// Realiza o login com email e senha
  Future<AuthResult> login({required String email, required String password, required bool isBiometricsEnabled}) async {
    AppLogger.func();
    try {
      final authResult = await _loginUseCase(email, password);

      if (authResult.error != null) {
        return authResult;
      }

      if (authResult.client != null && authResult.authToken != null) {
        await _handleSuccessfulLogin(authResult: authResult, email: email, isBiometricsEnabled: isBiometricsEnabled);
      }

      return authResult;
    } catch (e) {
      AppLogger.error(e, StackTrace.current);
      return AuthResult(error: e.toString());
    }
  }

  /// Realiza o login com Google
  Future<AuthResult> loginWithGoogle() async {
    AppLogger.func();
    try {
      final authResult = await _signInWithGoogleUseCase();

      if (authResult.error != null) {
        return authResult;
      }

      if (authResult.client != null && authResult.authToken != null) {
        // Para login social, desabilitamos biometria por padrão
        await _handleSuccessfulLogin(
          authResult: authResult,
          email: authResult.client!.email,
          isBiometricsEnabled: false,
        );
      }

      return authResult;
    } catch (e) {
      AppLogger.error(e, StackTrace.current);
      return AuthResult(error: e.toString());
    }
  }

  /// Verifica se há sessão ativa ou possibilidade de login biométrico
  Future<AuthResult?> checkSessionOrBiometrics() async {
    AppLogger.func();
    try {
      final token = await _secureStorageService.getToken();
      final refreshToken = await _secureStorageService.getRefreshToken();
      final userIdentifier = await _secureStorageService.getUserIdentifier();
      final canCheckBiometrics = await _authService.canCheckBiometrics();

      // 1. Tenta Login Biométrico Automático
      if (token != null && userIdentifier != null && canCheckBiometrics) {
        AppLogger.info('✅ Condições para biometria atendidas. Tentando autenticar...');
        final isAuthenticated = await _authService.authenticate();

        if (isAuthenticated) {
          return await _validateToken();
        } else {
          AppLogger.warning('⚠️ Biometria falhou ou cancelada.');
          // Se falhou biometria, não retorna erro imediatamente,
          // deixa cair para verificação de token normal ou retorna null para pedir login
          return null;
        }
      }

      // 2. Se tem token mas sem biometria, valida o token
      if (token != null) {
        AppLogger.info('🔍 Token encontrado. Validando...');
        return await _validateToken();
      }

      // 3. Se só tem refresh token, tenta renovar
      if (token == null && refreshToken != null) {
        AppLogger.info('🔄 Apenas refresh token encontrado. Renovando...');
        return await _tryRefreshToken(refreshToken);
      }

      return null; // Nenhuma sessão encontrada
    } catch (e) {
      AppLogger.error(e, StackTrace.current);
      return null;
    }
  }

  /// Verifica validade do token atual (sem biometria)
  Future<AuthResult?> checkTokenValidity() async {
    AppLogger.func();
    try {
      final token = await _secureStorageService.getToken();
      final refreshToken = await _secureStorageService.getRefreshToken();

      if (token != null) {
        return await _validateToken();
      } else if (refreshToken != null) {
        return await _tryRefreshToken(refreshToken);
      }

      return null;
    } catch (e) {
      AppLogger.error(e, StackTrace.current);
      return null;
    }
  }

  /// Realiza logout
  Future<void> logout() async {
    AppLogger.func();
    try {
      final refreshToken = await _secureStorageService.getRefreshToken();
      final accessToken = await _secureStorageService.getToken();

      if (refreshToken != null || accessToken != null) {
        try {
          await _logoutUseCase(refreshToken: refreshToken, accessToken: accessToken);
        } catch (e) {
          AppLogger.warning('⚠️ Erro ao fazer logout no servidor: $e');
        }
      }
    } finally {
      await _secureStorageService.clearAll();
    }
  }

  /// Define a preferência de biometria
  Future<void> setBiometricsEnabled(bool enabled) async {
    if (!enabled) {
      await _secureStorageService.deleteUserIdentifier();
    }
  }

  // --- Métodos Privados Auxiliares ---

  Future<void> _handleSuccessfulLogin({
    required AuthResult authResult,
    required String email,
    required bool isBiometricsEnabled,
  }) async {
    final client = authResult.client!;

    // Salva tokens
    if (client.accountId != null) {
      await _secureStorageService.saveToken(authResult.authToken!);
      if (authResult.refreshAuthToken != null) {
        await _secureStorageService.saveRefreshToken(authResult.refreshAuthToken!);
      }
    } else {
      _secureStorageService.saveTemporaryToken(authResult.authToken!);
      if (authResult.refreshAuthToken != null) {
        _secureStorageService.saveTemporaryRefreshToken(authResult.refreshAuthToken!);
      }
    }

    // Configura Biometria
    if (isBiometricsEnabled) {
      final canCheck = await _authService.canCheckBiometrics();
      if (canCheck) {
        await _secureStorageService.saveUserIdentifier(email);
        // Solicita autenticação para confirmar
        await _authService.authenticate();
      } else {
        await _secureStorageService.deleteUserIdentifier();
      }
    } else {
      await _secureStorageService.deleteUserIdentifier();
    }
  }

  Future<AuthResult> _validateToken() async {
    try {
      final authResult = await _getCurrentUserUseCase();

      if (authResult.error != null) {
        // Se token inválido, tenta refresh
        final refreshToken = await _secureStorageService.getRefreshToken();
        if (refreshToken != null) {
          return await _tryRefreshToken(refreshToken);
        }
        await _clearSession();
        return authResult;
      }

      return authResult;
    } catch (e) {
      // Erro de rede ou outro, tenta refresh por garantia
      final refreshToken = await _secureStorageService.getRefreshToken();
      if (refreshToken != null) {
        return await _tryRefreshToken(refreshToken);
      }
      return AuthResult(error: e.toString());
    }
  }

  Future<AuthResult> _tryRefreshToken(String refreshToken) async {
    try {
      final result = await _refreshTokenUseCase(refreshToken);

      if (result.authToken != null) {
        await _secureStorageService.saveToken(result.authToken!);
        if (result.refreshAuthToken != null) {
          await _secureStorageService.saveRefreshToken(result.refreshAuthToken!);
        }
        // Após refresh, busca usuário
        return await _getCurrentUserUseCase();
      }

      await _clearSession();
      return AuthResult(error: 'Falha ao renovar token');
    } catch (e) {
      await _clearSession();
      return AuthResult(error: e.toString());
    }
  }

  Future<void> _clearSession() async {
    await _secureStorageService.deleteToken();
    await _secureStorageService.deleteRefreshToken();
    await _secureStorageService.deleteUserIdentifier();
    _secureStorageService.clearTemporaryTokens();
  }
}
