import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:common/common.dart';
import 'package:terafy/core/data/datasources/remote/auth_remote_data_source.dart';
import 'package:terafy/core/data/repositories/auth_repository_impl.dart';
import 'package:terafy/core/data/repositories/home_repository_impl.dart';
import 'package:terafy/core/data/repositories/patient_repository_impl.dart';
import 'package:terafy/core/data/repositories/schedule_repository_impl.dart';
import 'package:terafy/core/data/repositories/session_repository_impl.dart';
import 'package:terafy/core/data/repositories/therapist_repository_impl.dart';
import 'package:terafy/core/data/repositories/financial_repository_impl.dart';
import 'package:terafy/core/data/repositories/anamnesis_repository_impl.dart';
import 'package:terafy/core/data/repositories/anamnesis_template_repository_impl.dart';
import 'package:terafy/core/data/repositories/subscription_repository_impl.dart';
import 'package:terafy/core/domain/repositories/auth_repository.dart';
import 'package:terafy/core/domain/repositories/home_repository.dart';
import 'package:terafy/core/domain/repositories/patient_repository.dart';
import 'package:terafy/core/domain/repositories/schedule_repository.dart';
import 'package:terafy/core/domain/repositories/session_repository.dart';
import 'package:terafy/core/domain/repositories/therapist_repository.dart';
import 'package:terafy/core/domain/repositories/financial_repository.dart';
import 'package:terafy/core/domain/repositories/anamnesis_repository.dart';
import 'package:terafy/core/domain/repositories/anamnesis_template_repository.dart';
import 'package:terafy/core/domain/repositories/subscription_repository.dart';
import 'package:terafy/core/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/login_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/logout_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/register_user_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/refresh_token_usecase.dart';
import 'package:terafy/core/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:terafy/core/domain/usecases/home/get_home_summary_usecase.dart';
import 'package:terafy/core/domain/usecases/patient/create_patient_usecase.dart';
import 'package:terafy/core/domain/usecases/patient/get_patient_usecase.dart';
import 'package:terafy/core/domain/usecases/patient/get_patients_usecase.dart';
import 'package:terafy/core/domain/usecases/patient/update_patient_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/create_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/delete_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/get_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/get_appointments_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/get_schedule_settings_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/update_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/update_schedule_settings_usecase.dart';
import 'package:terafy/core/domain/usecases/session/create_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/delete_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_next_session_number_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_sessions_usecase.dart';
import 'package:terafy/core/domain/usecases/session/update_session_usecase.dart';
import 'package:terafy/core/domain/usecases/therapist/create_therapist_usecase.dart';
import 'package:terafy/core/domain/usecases/therapist/get_current_therapist_usecase.dart';
import 'package:terafy/core/domain/usecases/therapist/update_therapist_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/get_transactions_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/get_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/create_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/update_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/delete_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/get_financial_summary_usecase.dart';
import 'package:terafy/core/interceptors/auth_interceptor.dart';
import 'package:terafy/core/services/auth_service.dart';
import 'package:terafy/core/services/secure_storage_service.dart';
import 'package:terafy/core/services/patients_cache_service.dart';
import 'package:terafy/core/subscription/subscription_service.dart';
import 'package:terafy/package/http.dart';

// Este é um container de dependências simples. Em projetos maiores,
// pacotes como get_it ou provider podem ser usados para uma solução mais robusta.

class DependencyContainer {
  static final DependencyContainer _instance = DependencyContainer._internal();
  factory DependencyContainer() => _instance;
  DependencyContainer._internal();

  late final Dio dio;
  late final AuthRemoteDataSource authRemoteDataSource;
  late final AuthRepository authRepository;
  late final TherapistRepository therapistRepository;
  late final PatientRepository patientRepository;
  late final ScheduleRepository scheduleRepository;
  late final SessionRepository sessionRepository;
  late final FinancialRepository financialRepository;
  late final HomeRepository homeRepository;
  late final AnamnesisRepository anamnesisRepository;
  late final AnamnesisTemplateRepository anamnesisTemplateRepository;
  late final SubscriptionRepository subscriptionRepository;
  late final SubscriptionService subscriptionService;
  late final LoginUseCase loginUseCase;
  late final RegisterUserUseCase registerUserUseCase;
  late final SignInWithGoogleUseCase signInWithGoogleUseCase;
  late final GetCurrentUserUseCase getCurrentUserUseCase;
  late final RefreshTokenUseCase refreshTokenUseCase;
  late final LogoutUseCase logoutUseCase;
  late final CreateTherapistUseCase createTherapistUseCase;
  late final GetCurrentTherapistUseCase getCurrentTherapistUseCase;
  late final UpdateTherapistUseCase updateTherapistUseCase;
  late final GetPatientsUseCase getPatientsUseCase;
  late final CreatePatientUseCase createPatientUseCase;
  late final GetPatientUseCase getPatientUseCase;
  late final UpdatePatientUseCase updatePatientUseCase;
  late final GetHomeSummaryUseCase getHomeSummaryUseCase;
  late final GetScheduleSettingsUseCase getScheduleSettingsUseCase;
  late final UpdateScheduleSettingsUseCase updateScheduleSettingsUseCase;
  late final GetAppointmentsUseCase getAppointmentsUseCase;
  late final GetAppointmentUseCase getAppointmentUseCase;
  late final CreateAppointmentUseCase createAppointmentUseCase;
  late final UpdateAppointmentUseCase updateAppointmentUseCase;
  late final DeleteAppointmentUseCase deleteAppointmentUseCase;
  late final GetSessionsUseCase getSessionsUseCase;
  late final GetSessionUseCase getSessionUseCase;
  late final CreateSessionUseCase createSessionUseCase;
  late final UpdateSessionUseCase updateSessionUseCase;
  late final DeleteSessionUseCase deleteSessionUseCase;
  late final GetNextSessionNumberUseCase getNextSessionNumberUseCase;
  late final GetTransactionsUseCase getTransactionsUseCase;
  late final GetTransactionUseCase getTransactionUseCase;
  late final CreateTransactionUseCase createTransactionUseCase;
  late final UpdateTransactionUseCase updateTransactionUseCase;
  late final DeleteTransactionUseCase deleteTransactionUseCase;
  late final GetFinancialSummaryUseCase getFinancialSummaryUseCase;
  late final SecureStorageService secureStorageService;
  late AuthService authService; // Não é final para permitir substituição em testes
  late final HttpClient httpClient;
  late final PatientsCacheService patientsCacheService;

  // Obtém a URL base do backend dependendo da plataforma
  String get _baseUrl {
    // Em desenvolvimento, usa localhost
    if (kDebugMode) {
      if (kIsWeb) {
        return 'http://localhost:8080';
      }
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      }
      if (Platform.isIOS) {
        // iOS Simulator usa localhost normalmente
        return 'http://localhost:8080';
      }
    }

    // Em produção web, detecta automaticamente o protocolo da página atual
    // Isso garante que se a página está em HTTPS, a API também usa HTTPS
    if (kIsWeb) {
      return _getApiUrlForWeb();
    }

    // Para mobile em produção, sempre usa HTTPS
    return 'https://api.terafy.app.br';
  }

  /// Detecta automaticamente o protocolo da página web e usa HTTPS para produção
  /// Isso resolve problemas de Mixed Content (HTTPS page → HTTP API)
  String _getApiUrlForWeb() {
    try {
      // Obtém a URL atual da página
      final currentUrl = Uri.base;
      final host = currentUrl.host;

      // Se está em um domínio de produção (terafy.app.br), sempre usa HTTPS
      if (host.contains('terafy.app.br')) {
        return 'https://api.terafy.app.br';
      }

      // Se está em localhost (desenvolvimento), pode usar HTTP
      if (host == 'localhost' || host == '127.0.0.1') {
        // Em desenvolvimento local, pode usar HTTP
        // Mas se você estiver testando HTTPS localmente, use HTTPS
        return 'http://localhost:8080';
      }

      // Para qualquer outro caso (incluindo IPs), usa HTTPS como padrão seguro
      return 'https://api.terafy.app.br';
    } catch (e) {
      // Em caso de erro, usa HTTPS como padrão seguro
      AppLogger.warning('Erro ao detectar protocolo da página: $e. Usando HTTPS como padrão.');
      return 'https://api.terafy.app.br';
    }
  }

  void setup({AuthService? testAuthService}) {
    // Services - inicializar primeiro pois são usados por outros componentes
    secureStorageService = SecureStorageService();
    authService = testAuthService ?? AuthService();
    patientsCacheService = PatientsCacheService();
    subscriptionService = SubscriptionService();

    httpClient = DioHttpClient(baseUrl: _baseUrl, enableLogger: kDebugMode);
    dio = (httpClient as DioHttpClient).dio;

    // Adiciona interceptor de autenticação
    // Nota: Context será definido quando necessário
    // dio.interceptors.add(AuthInterceptor(secureStorageService));

    // Data Sources
    authRemoteDataSource = AuthRemoteDataSourceImpl(dio: dio, secureStorageService: secureStorageService);
    // Repositories
    authRepository = AuthRepositoryImpl(remoteDataSource: authRemoteDataSource);
    therapistRepository = TherapistRepositoryImpl(httpClient: httpClient);
    patientRepository = PatientRepositoryImpl(httpClient: httpClient);
    scheduleRepository = ScheduleRepositoryImpl(httpClient: httpClient);
    sessionRepository = SessionRepositoryImpl(httpClient: httpClient);
    financialRepository = FinancialRepositoryImpl(httpClient: httpClient);
    homeRepository = HomeRepositoryImpl(httpClient: httpClient);
    anamnesisRepository = AnamnesisRepositoryImpl(httpClient: httpClient);
    anamnesisTemplateRepository = AnamnesisTemplateRepositoryImpl(httpClient: httpClient);
    subscriptionRepository = SubscriptionRepositoryImpl(httpClient: httpClient);

    // Use Cases
    loginUseCase = LoginUseCase(authRepository);
    registerUserUseCase = RegisterUserUseCase(authRepository);
    signInWithGoogleUseCase = SignInWithGoogleUseCase(authRepository);
    getCurrentUserUseCase = GetCurrentUserUseCase(authRepository);
    refreshTokenUseCase = RefreshTokenUseCase(authRepository);
    logoutUseCase = LogoutUseCase(authRepository);
    createTherapistUseCase = CreateTherapistUseCase(therapistRepository);
    getCurrentTherapistUseCase = GetCurrentTherapistUseCase(therapistRepository);
    updateTherapistUseCase = UpdateTherapistUseCase(therapistRepository);
    getPatientsUseCase = GetPatientsUseCase(patientRepository);
    createPatientUseCase = CreatePatientUseCase(patientRepository);
    getPatientUseCase = GetPatientUseCase(patientRepository);
    updatePatientUseCase = UpdatePatientUseCase(patientRepository);
    getHomeSummaryUseCase = GetHomeSummaryUseCase(homeRepository);
    getScheduleSettingsUseCase = GetScheduleSettingsUseCase(scheduleRepository);
    updateScheduleSettingsUseCase = UpdateScheduleSettingsUseCase(scheduleRepository);
    getAppointmentsUseCase = GetAppointmentsUseCase(scheduleRepository);
    getAppointmentUseCase = GetAppointmentUseCase(scheduleRepository);
    createAppointmentUseCase = CreateAppointmentUseCase(scheduleRepository);
    updateAppointmentUseCase = UpdateAppointmentUseCase(scheduleRepository);
    deleteAppointmentUseCase = DeleteAppointmentUseCase(scheduleRepository);
    getSessionsUseCase = GetSessionsUseCase(sessionRepository);
    getSessionUseCase = GetSessionUseCase(sessionRepository);
    createSessionUseCase = CreateSessionUseCase(sessionRepository);
    updateSessionUseCase = UpdateSessionUseCase(sessionRepository);
    deleteSessionUseCase = DeleteSessionUseCase(sessionRepository);
    getNextSessionNumberUseCase = GetNextSessionNumberUseCase(sessionRepository);
    getTransactionsUseCase = GetTransactionsUseCase(financialRepository);
    getTransactionUseCase = GetTransactionUseCase(financialRepository);
    createTransactionUseCase = CreateTransactionUseCase(financialRepository);
    updateTransactionUseCase = UpdateTransactionUseCase(financialRepository);
    deleteTransactionUseCase = DeleteTransactionUseCase(financialRepository);
    getFinancialSummaryUseCase = GetFinancialSummaryUseCase(financialRepository);
  }

  /// Substitui o AuthService (útil para testes)
  void setAuthServiceForTests(AuthService testAuthService) {
    authService = testAuthService;
  }

  /// Configura o interceptor de autenticação com callback para token expirado
  void setupAuthInterceptor({VoidCallback? onTokenExpired}) {
    // Remove interceptors antigos se existirem
    dio.interceptors.removeWhere((interceptor) => interceptor is AuthInterceptor);

    // Adiciona novo interceptor com callback, Dio e RefreshTokenUseCase
    dio.interceptors.add(
      AuthInterceptor(
        secureStorageService,
        dio,
        refreshTokenUseCase: refreshTokenUseCase,
        onTokenExpired: onTokenExpired,
      ),
    );
  }
}
