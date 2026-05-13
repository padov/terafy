import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'package:server/features/subscription/subscription.handler.dart';

Router configureSubscriptionRoutes(SubscriptionHandler handler) {
  final router = Router();

  final therapistOrAdmin = requireAnyRole(['therapist', 'admin']);

  // GET /api/subscription/status - Retorna status da assinatura atual
  router.get('/status', therapistOrAdmin.call(handler.handleGetStatus));

  // GET /api/subscription/plans - Lista planos disponíveis
  router.get('/plans', therapistOrAdmin.call(handler.handleGetPlans));

  // GET /api/subscription/usage - Retorna informações de uso (contagem de pacientes)
  router.get('/usage', therapistOrAdmin.call(handler.handleGetUsage));

  // POST /api/subscription/checkout - Cria sessão do checkout no Stripe
  router.post('/checkout', therapistOrAdmin.call(handler.handleCreateCheckout));

  // POST /api/subscription/webhook - Endpoint desprotegido para a Stripe
  router.post('/webhook', handler.handleStripeWebhook);

  return router;
}
