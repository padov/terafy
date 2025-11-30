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
import 'package:server/features/schedule/services/appointment_reminder_service.dart';
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
import 'package:server/features/messaging/messaging.controller.dart';
import 'package:server/features/messaging/messaging.handler.dart';
import 'package:server/features/messaging/messaging.repository.dart';
import 'package:server/features/messaging/domain/message_channel.dart';
import 'package:server/features/messaging/domain/message_provider.dart';
import 'package:server/features/messaging/providers/email_message_provider.dart';
import 'package:server/features/messaging/providers/sms_message_provider.dart';
import 'package:server/features/messaging/providers/whatsapp_message_provider.dart';
import 'package:server/features/messaging/providers/push_message_provider.dart';
import 'package:server/features/messaging/services/message_template_service.dart';
import 'package:server/features/messaging/services/reminder_scheduler.dart';
import 'package:server/features/messaging/usecases/get_message_history_usecase.dart';
import 'package:server/features/messaging/usecases/send_appointment_reminder_usecase.dart';
import 'package:server/features/messaging/usecases/send_message_usecase.dart';
import 'package:server/features/whatsapp/whatsapp.controller.dart';
import 'package:server/features/whatsapp/whatsapp.handler.dart';
import 'package:server/features/whatsapp/whatsapp.repository.dart';
import 'package:server/features/whatsapp/services/conversation_manager.dart';
import 'package:server/features/whatsapp/services/whatsapp_appointment_service.dart';
import 'package:server/features/whatsapp/services/whatsapp_confirmation_service.dart';
import 'package:server/features/whatsapp/whatsapp.webhook_handler.dart';
import 'package:common/common.dart';
import 'package:server/core/config/env_config.dart';

/// Versão do servidor
const String serverVersion = '0.2.1';

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
  AppLogger.config(isDebugMode: true);

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
  final sessionRepository = SessionRepository(dbConnection);
  final financialRepository = FinancialRepository(dbConnection);
  final sessionController = SessionController(sessionRepository, financialRepository);
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

  // --- Sistema de Mensagens ---
  final messageRepository = MessageRepositoryImpl(dbConnection);
  final emailProvider = EmailMessageProvider();
  final smsProvider = SMSMessageProvider();
  final whatsappProvider = WhatsAppMessageProvider();
  final pushProvider = PushMessageProvider();
  final messageProviders = <MessageChannel, MessageProvider>{
    MessageChannel.email: emailProvider,
    MessageChannel.sms: smsProvider,
    MessageChannel.whatsapp: whatsappProvider,
    MessageChannel.push: pushProvider,
  };
  final templateService = MessageTemplateService();
  final sendMessageUseCase = SendMessageUseCase(messageRepository, messageProviders);
  final sendAppointmentReminderUseCase = SendAppointmentReminderUseCase(
    messageRepository,
    templateService,
    sendMessageUseCase,
  );
  final getMessageHistoryUseCase = GetMessageHistoryUseCase(messageRepository);

  // --- Appointment Reminder Service (usa messageRepository) ---
  final appointmentReminderService = AppointmentReminderService(
    messageRepository,
    patientRepository,
    therapistRepository,
  );
  
  // ScheduleController com reminderService
  final scheduleController = ScheduleController(
    scheduleRepository,
    reminderService: appointmentReminderService,
  );
  final scheduleHandler = ScheduleHandler(scheduleController);

  // --- Sistema WhatsApp ---
  final whatsappRepository = WhatsAppRepository(dbConnection);
  final whatsappConversationManager = ConversationManager(
    whatsappRepository,
    patientRepository,
    scheduleRepository,
  );
  final whatsappAppointmentService = WhatsAppAppointmentService(
    scheduleController,
    scheduleRepository,
    sendAppointmentReminderUseCase,
  );
  final whatsappConfirmationService = WhatsAppConfirmationService(
    messageRepository,
    whatsappProvider,
    scheduleRepository,
    patientRepository,
    therapistRepository,
  );
  final whatsappWebhookHandler = WhatsAppWebhookHandler(
    whatsappConversationManager,
    whatsappRepository,
    whatsappProvider,
  );
  final whatsappController = WhatsAppController(
    whatsappRepository,
    whatsappConversationManager,
    whatsappAppointmentService,
    whatsappConfirmationService,
    whatsappWebhookHandler,
    scheduleRepository,
  );
  final whatsappHandler = WhatsAppHandler(whatsappController);

  // --- Reminder Scheduler (usa WhatsAppConfirmationService) ---
  final reminderScheduler = ReminderScheduler(
    messageRepository,
    sendMessageUseCase,
    whatsappConfirmationService: whatsappConfirmationService,
  );
  final messagingController = MessagingController(
    sendMessageUseCase,
    sendAppointmentReminderUseCase,
    getMessageHistoryUseCase,
    reminderScheduler,
  );
  final messagingHandler = MessagingHandler(messagingController);

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
    ..mount('/anamnesis', anamnesisHandler.router.call) // Monta as rotas de anamnese
    ..mount('/messages', messagingHandler.router.call) // Monta as rotas de mensagens
    ..mount('/whatsapp', whatsappHandler.router.call); // Monta as rotas de WhatsApp

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
  AppLogger.info('📦 Versão: $serverVersion');
  AppLogger.info('🌐 Servidor rodando em http://${server.address.host}:${server.port}');
}
