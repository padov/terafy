import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/core/database/migration_manager.dart';
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
import 'package:common/common.dart';
import 'package:server/core/config/env_config.dart';

void main() async {
  // Carrega variáveis de ambiente do arquivo .env
  EnvConfig.load();

  // Configura o logger
  // Em produção, pode usar variável de ambiente: const bool.fromEnvironment('DEBUG', defaultValue: false)
  AppLogger.config(isDebugMode: true);

  // --- Execução Automática de Migrations ---
  AppLogger.info('🔄 Verificando e executando migrations pendentes...');
  final dbConnection = DBConnection();
  await dbConnection.initialize(); // Inicializa o pool de conexões
  try {
    await dbConnection.withConnection((conn) async {
      await MigrationManager.runPendingMigrations(conn);
    });
    AppLogger.info('✅ Migrations verificadas com sucesso');
  } catch (e, stackTrace) {
    AppLogger.error('❌ Erro ao executar migrations. Abortando inicialização do servidor.');
    AppLogger.error('Erro: $e');
    AppLogger.error('Stack trace: $stackTrace');
    exit(1);
  }

  // --- Injeção de Dependências ---
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
  final sessionController = SessionController(sessionRepository, financialRepository);
  final sessionHandler = SessionHandler(sessionController);
  final financialController = FinancialController(financialRepository, sessionRepository);
  final financialHandler = FinancialHandler(financialController);
  final homeController = HomeController(scheduleRepository, sessionRepository, patientRepository);
  final homeHandler = HomeHandler(homeController);
  final refreshTokenRepository = RefreshTokenRepository(dbConnection);
  final blacklistRepository = TokenBlacklistRepository(dbConnection);
  final authHandler = AuthHandler(userRepository, refreshTokenRepository, blacklistRepository);

  // --- Configuração do Roteador Principal ---
  final appRouter = Router()
    ..get('/ping', (Request request) => Response.ok('pong'))
    ..mount('/auth', authHandler.router.call) // Rotas de autenticação
    ..mount('/users', userHandler.router.call) // Monta as rotas de usuário
    ..mount('/therapists', therapistHandler.router.call) // Monta as rotas de terapeutas
    ..mount('/patients', patientHandler.router.call) // Monta as rotas de pacientes
    ..mount('/schedule', scheduleHandler.router.call) // Monta as rotas de agenda
    ..mount('/sessions', sessionHandler.router.call) // Monta as rotas de sessões
    ..mount('/financial', financialHandler.router.call) // Monta as rotas financeiras
    ..mount('/home', homeHandler.router.call); // Monta as rotas da home

  // --- Criação do Pipeline e Servidor ---
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(
        authMiddleware(blacklistRepository: blacklistRepository),
      ) // Middleware de autenticação com blacklist
      .addHandler(appRouter.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);

  // Imprime o ASCII Art
  const ascArt = r'''

 _____                          ____                            
|_   _|__ _ __ __ _ ___ _   _  / ___|  ___ _ ____   _____ _ __ 
  | |/ _ \ '__/ _` |  _| | | | \___ \ / _ \ '__\ \ / / _ \ '__|
  | |  __/ | | (_| |  _| |_| |  ___) |  __/ |   \ V /  __/ |   
  |_|\___|_|  \__,_|_|  \__, | |____/ \___|_|    \_/ \___|_|   
                        |___/
''';
  AppLogger.info(ascArt);
  AppLogger.info('Servidor rodando em http://${server.address.host}:${server.port}');
}
