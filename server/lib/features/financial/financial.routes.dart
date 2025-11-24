import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'package:server/features/financial/financial.handler.dart';

Router configureFinancialRoutes(FinancialHandler handler) {
  final router = Router();
  final therapistOrAdmin = requireAnyRole(['therapist', 'admin']);

  router.post(
    '/',
    therapistOrAdmin.call(handler.handleCreateTransaction),
  );

  router.get(
    '/',
    therapistOrAdmin.call(handler.handleListTransactions),
  );

  router.get(
    '/summary',
    therapistOrAdmin.call(handler.handleGetFinancialSummary),
  );

  router.get(
    '/<id|[0-9]+>',
    (Request request, String id) async {
      return therapistOrAdmin.call(
        (req) => handler.handleGetTransaction(req, id),
      )(request);
    },
  );

  router.put(
    '/<id|[0-9]+>',
    (Request request, String id) async {
      return therapistOrAdmin.call(
        (req) => handler.handleUpdateTransaction(req, id),
      )(request);
    },
  );

  router.delete(
    '/<id|[0-9]+>',
    (Request request, String id) async {
      return therapistOrAdmin.call(
        (req) => handler.handleDeleteTransaction(req, id),
      )(request);
    },
  );

  return router;
}

