import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/cors_middleware.dart';
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
import 'package:server/features/anamnesis/anamnesis.controller.dart';
import 'package:server/features/anamnesis/anamnesis.handler.dart';
import 'package:server/features/anamnesis/anamnesis.repository.dart';
import 'package:common/common.dart';
import 'package:server/core/config/env_config.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

/// Lê a versão do servidor a partir do pubspec.yaml
String _getServerVersion() {
  try {
    // Obtém o caminho do diretório do executável
    final scriptPath = Platform.script.toFilePath();
    final serverDir = p.dirname(p.dirname(scriptPath)); // Volta 2 níveis (de bin/ para raiz)
    final pubspecPath = p.join(serverDir, 'pubspec.yaml');

    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) {
      AppLogger.warning('⚠️  pubspec.yaml não encontrado em: $pubspecPath');
      return 'unknown';
    }

    final content = pubspecFile.readAsStringSync();
    final versionMatch = RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(content);

    if (versionMatch != null) {
      return versionMatch.group(1)!.trim();
    }

    AppLogger.warning('⚠️  Versão não encontrada no pubspec.yaml');
    return 'unknown';
  } catch (e) {
    AppLogger.error('❌ Erro ao ler versão do pubspec.yaml: $e');
    return 'unknown';
  }
}

/// Converte string de nível de log para Level
Level _parseLogLevel(String levelStr) {
  switch (levelStr.toUpperCase()) {
    case 'ALL':
      return Level.ALL;
    case 'FINEST':
      return Level.FINEST;
    case 'FINER':
      return Level.FINER;
    case 'FINE':
      return Level.FINE;
    case 'CONFIG':
      return Level.CONFIG;
    case 'INFO':
      return Level.INFO;
    case 'WARNING':
      return Level.WARNING;
    case 'SEVERE':
      return Level.SEVERE;
    case 'SHOUT':
      return Level.SHOUT;
    case 'OFF':
      return Level.OFF;
    default:
      AppLogger.warning('⚠️  Nível de log desconhecido: $levelStr. Usando ALL.');
      return Level.ALL;
  }
}

void main() async {
  // Carrega variáveis de ambiente do arquivo .env
  EnvConfig.load();

  // Log das variáveis de ambiente de conexão (sem mostrar senha)
  AppLogger.info('Configurações de banco de dados:');
  AppLogger.info('  DB_HOST: ${EnvConfig.getOrDefault('DB_HOST', 'não definido')}');
  AppLogger.info('  DB_PORT: ${EnvConfig.getIntOrDefault('DB_PORT', 0)}');
  AppLogger.info('  DB_NAME: ${EnvConfig.getOrDefault('DB_NAME', 'não definido')}');
  AppLogger.info('  DB_USER: ${EnvConfig.getOrDefault('DB_USER', 'não definido')}');
  AppLogger.info('  DB_SSL_MODE: ${EnvConfig.getOrDefault('DB_SSL_MODE', 'não definido')}');

  // Valida JWT_SECRET_KEY
  final jwtSecret = EnvConfig.get('JWT_SECRET_KEY');
  if (jwtSecret == null || jwtSecret.isEmpty) {
    AppLogger.warning('⚠️  JWT_SECRET_KEY não configurado! Usando chave de desenvolvimento.');
    AppLogger.warning('   ⚠️  ATENÇÃO: Em produção, configure JWT_SECRET_KEY no arquivo .env');
    AppLogger.warning('   ⚠️  Isso pode causar problemas de autenticação!');
  } else {
    AppLogger.info('✅ JWT_SECRET_KEY configurado (${jwtSecret.length} caracteres)');
  }

  // Configura o logger
  // Em produção, pode usar variável de ambiente: const bool.fromEnvironment('DEBUG', defaultValue: false)
  AppLogger.config(
    isDebugMode: true,
    logToFile: EnvConfig.getOrDefault('LOG_TO_FILE', 'false') == 'true',
    logDirectory: EnvConfig.getOrDefault('LOG_DIR', './log'),
    logLevel: _parseLogLevel(EnvConfig.getOrDefault('LOG_LEVEL', 'ALL')),
    maxFileSizeMB: EnvConfig.getIntOrDefault('LOG_MAX_FILE_SIZE_MB', 20),
    retentionDays: EnvConfig.getIntOrDefault('LOG_RETENTION_DAYS', 30),
    compressRotated: EnvConfig.getOrDefault('LOG_COMPRESS_ROTATED', 'true') == 'true',
  );

  // --- Garantir Banco de Dados e Permissões ---
  // Este passo é opcional - apenas tenta criar/configurar se tiver permissões
  // Se falhar, continua mesmo assim (o banco pode já existir e estar configurado)
  AppLogger.info('🔍 Verificando banco de dados e permissões...');
  try {
    await MigrationManager.ensureDatabaseAndPermissions();
  } catch (e) {
    // Se o banco não existe, aborta a inicialização
    final errorStr = e.toString();
    if (errorStr.contains('3D000') || errorStr.contains('does not exist')) {
      AppLogger.error('❌ Banco de dados não existe e não foi possível criá-lo.');
      AppLogger.error('   Por favor, crie o banco de dados manualmente ou verifique as permissões do usuário.');
      AppLogger.error('   Erro: $e');
      exit(1);
    }
    // Para outros erros (permissão), apenas registra aviso e continua
    AppLogger.warning('⚠️  Não foi possível verificar/criar banco (pode não ter permissão)');
    AppLogger.warning('   Continuando... (assumindo que o banco já existe e está configurado)');
  }

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
  final sessionController = SessionController(sessionRepository, scheduleRepository, financialRepository);
  final sessionHandler = SessionHandler(sessionController);
  final financialController = FinancialController(financialRepository);
  final financialHandler = FinancialHandler(financialController);
  final homeController = HomeController(scheduleRepository, sessionRepository, patientRepository, financialRepository);
  final homeHandler = HomeHandler(homeController);
  final anamnesisRepository = AnamnesisRepository(dbConnection);
  final anamnesisController = AnamnesisController(anamnesisRepository);
  final anamnesisHandler = AnamnesisHandler(anamnesisController);
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
    ..mount('/home', homeHandler.router.call) // Monta as rotas da home
    ..mount('/anamnesis', anamnesisHandler.router.call); // Monta as rotas de anamnese

  // --- Criação do Pipeline e Servidor ---
  final handler = Pipeline()
      .addMiddleware(corsMiddleware()) // CORS deve ser o primeiro middleware
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
  AppLogger.info('📦 Versão: ${_getServerVersion()}');
  AppLogger.info('🌐 Servidor rodando em http://${server.address.host}:${server.port}');
}
