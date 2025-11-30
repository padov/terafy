import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'package:server/features/messaging/messaging.handler.dart';

Router configureMessagingRoutes(MessagingHandler handler) {
  final router = Router();

  final therapistOrAdmin = requireAnyRole(['therapist', 'admin']);

  // Enviar mensagem genérica
  router.post('/send', therapistOrAdmin.call(handler.handleSend));

  // Enviar lembrete de agendamento
  router.post('/reminder', therapistOrAdmin.call(handler.handleSendReminder));

  // Histórico de mensagens
  router.get('/history', therapistOrAdmin.call(handler.handleHistory));

  // Processar lembretes agendados (apenas admin)
  router.post('/process-reminders', requireAnyRole(['admin']).call(handler.handleProcessReminders));

  return router;
}

