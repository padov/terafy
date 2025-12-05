import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/services/session_manager.dart';
import 'package:terafy/core/domain/entities/auth_result.dart';
import 'package:common/common.dart';
import 'login_bloc_models.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final SessionManager sessionManager;

  LoginBloc({required this.sessionManager}) : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<LoginWithBiometrics>(_onLoginWithBiometrics);
    on<LoginWithGooglePressed>(_onLoginWithGooglePressed);
    on<CheckBiometricLogin>(_onCheckBiometricLogin);
    on<CheckTokenValidity>(_onCheckTokenValidity);
    on<BiometricsPreferenceChanged>(_onBiometricsPreferenceChanged);
    on<LogoutPressed>(_onLogoutPressed);

    // Verifica automaticamente se deve tentar login biométrico ou validar token ao inicializar
    Future.microtask(() => add(CheckBiometricLogin()));
  }

  Future<void> _onBiometricsPreferenceChanged(BiometricsPreferenceChanged event, Emitter<LoginState> emit) async {
    AppLogger.func();
    await sessionManager.setBiometricsEnabled(event.enabled);
  }

  Future<void> _onLoginButtonPressed(LoginButtonPressed event, Emitter<LoginState> emit) async {
    log('Evento LoginButtonPressed recebido no Bloc com email: ${event.email}', name: 'LoginBloc');
    emit(LoginLoading());
    final result = await sessionManager.login(
      email: event.email,
      password: event.password,
      isBiometricsEnabled: event.isBiometricsEnabled,
    );
    _handleAuthResult(result, emit);
  }

  Future<void> _onLoginWithGooglePressed(LoginWithGooglePressed event, Emitter<LoginState> emit) async {
    log('Evento LoginWithGooglePressed recebido no Bloc.', name: 'LoginBloc');
    emit(LoginLoading());
    final result = await sessionManager.loginWithGoogle();
    _handleAuthResult(result, emit);
  }

  Future<void> _onCheckBiometricLogin(CheckBiometricLogin event, Emitter<LoginState> emit) async {
    AppLogger.func();
    // Tenta login biométrico ou validação de sessão automática
    final result = await sessionManager.checkSessionOrBiometrics();

    if (result != null) {
      _handleAuthResult(result, emit);
    }
    // Se result for null, mantém no estado inicial (LoginInitial)
  }

  Future<void> _onLoginWithBiometrics(LoginWithBiometrics event, Emitter<LoginState> emit) async {
    AppLogger.func();
    emit(LoginLoading());
    // Reutiliza a lógica de verificação de sessão/biometria
    final result = await sessionManager.checkSessionOrBiometrics();

    if (result != null) {
      _handleAuthResult(result, emit);
    } else {
      // Se falhou ou cancelou, volta para o estado inicial
      emit(LoginInitial());
    }
  }

  Future<void> _onCheckTokenValidity(CheckTokenValidity event, Emitter<LoginState> emit) async {
    AppLogger.func();
    final result = await sessionManager.checkTokenValidity();

    if (result != null) {
      _handleAuthResult(result, emit);
    }
  }

  Future<void> _onLogoutPressed(LogoutPressed event, Emitter<LoginState> emit) async {
    AppLogger.func();
    await sessionManager.logout();
    emit(LogoutSuccess());
  }

  void _handleAuthResult(AuthResult result, Emitter<LoginState> emit) {
    if (result.error != null) {
      emit(LoginFailure(error: result.error!));
    } else if (result.client != null) {
      final client = result.client!;
      emit(LoginSuccess(client: client, requiresProfileCompletion: client.accountId == null));
    }
  }
}
