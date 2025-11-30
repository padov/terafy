import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'package:server/features/whatsapp/whatsapp.handler.dart';

Router configureWhatsAppRoutes(WhatsAppHandler handler) {
  final router = Router();

  // Webhook do Evolution API (sem autenticação - validação por assinatura)
  router.post('/webhook', handler.handleWebhook);

  // Enviar confirmações (requer autenticação)
  router.post('/confirmations', requireAnyRole(['therapist', 'admin']).call(handler.handleSendConfirmations));

  return router;
}

