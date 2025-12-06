import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/cors_middleware.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/features/auth/auth.handler.dart';
import 'package:server/features/auth/refresh_token.repository.dart';
import 'package:server/features/auth/token_blacklist.repository.dart';
import 'package:server/features/home/home.controller.dart';
import 'package:server/features/home/home.handler.dart';
import 'package:server/features/patient/patient.controller.dart';
import 'package:server/features/patient/patient.handler.dart';
import 'package:server/features/patient/patient.repository.dart';
import 'package:server/features/schedule/schedule.controller.dart';
import 'package:server/features/schedule/schedule.handler.dart';
import 'package:server/features/schedule/schedule.repository.dart';
import 'package:server/features/session/session.controller.dart';
import 'package:server/features/session/session.handler.dart';
import 'package:server/features/session/session.repository.dart';
import 'package:server/features/financial/financial.controller.dart';
import 'package:server/features/financial/financial.handler.dart';
import 'package:server/features/financial/financial.repository.dart';
import 'package:server/features/therapist/therapist.handler.dart';
import 'package:server/features/therapist/therapist.repository.dart';
import 'package:server/features/user/user.handler.dart';
import 'package:server/features/user/user.repository.dart';
import 'package:server/features/anamnesis/anamnesis.controller.dart';
import 'package:server/features/anamnesis/anamnesis.handler.dart';
import 'package:server/features/anamnesis/anamnesis.repository.dart';
import 'integration_test_db.dart';

/// Helper para criar servidor de teste completo
class TestServerSetup {
  /// Cria Handler completo do servidor usando DBConnection de teste
  static Handler createTestHandler(DBConnection dbConnection) {
    // Injeção de Dependências (igual ao server.dart)
    final userRepository = UserRepository(dbConnection);
    final userHandler = UserHandler(userRepository);
    final therapistRepository = TherapistRepository(dbConnection);
    final therapistHandler = TherapistHandler(therapistRepository, userRepository);
    final patientRepository = PatientRepository(dbConnection);
    final patientController = PatientController(patientRepository);
    final patientHandler = PatientHandler(patientController);
    final scheduleRepository = ScheduleRepository(dbConnection);
    final scheduleController = ScheduleController(scheduleRepository);
    final scheduleHandler = ScheduleHandler(scheduleController);
    final sessionRepository = SessionRepository(dbConnection);
    final financialRepository = FinancialRepository(dbConnection);
    final sessionController = SessionController(sessionRepository, scheduleRepository, financialRepository);
    final sessionHandler = SessionHandler(sessionController);
    final financialController = FinancialController(financialRepository, sessionRepository);
    final financialHandler = FinancialHandler(financialController);
    final homeController = HomeController(scheduleRepository, sessionRepository, patientRepository);
    final homeHandler = HomeHandler(homeController);
    final anamnesisRepository = AnamnesisRepository(dbConnection);
    final anamnesisController = AnamnesisController(anamnesisRepository);
    final anamnesisHandler = AnamnesisHandler(anamnesisController);
    final refreshTokenRepository = RefreshTokenRepository(dbConnection);
    final blacklistRepository = TokenBlacklistRepository(dbConnection);
    final authHandler = AuthHandler(userRepository, refreshTokenRepository, blacklistRepository);

    // Configuração do Roteador Principal
    final appRouter = Router()
      ..get('/ping', (Request request) => Response.ok('pong'))
      ..mount('/auth', authHandler.router.call)
      ..mount('/users', userHandler.router.call)
      ..mount('/therapists', therapistHandler.router.call)
      ..mount('/patients', patientHandler.router.call)
      ..mount('/schedule', scheduleHandler.router.call)
      ..mount('/sessions', sessionHandler.router.call)
      ..mount('/financial', financialHandler.router.call)
      ..mount('/home', homeHandler.router.call)
      ..mount('/anamnesis', anamnesisHandler.router.call);

    // Criação do Pipeline com middlewares
    final handler = Pipeline()
        .addMiddleware(corsMiddleware())
        .addMiddleware(authMiddleware(blacklistRepository: blacklistRepository))
        .addHandler(appRouter.call);

    return handler;
  }

  /// Setup completo: cria banco, executa migrations
  static Future<void> setup() async {
    await IntegrationTestDB.setup();
  }

  /// Teardown: limpa dados
  static Future<void> teardown() async {
    await IntegrationTestDB.cleanDatabase();
  }
}
