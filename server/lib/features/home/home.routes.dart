import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'package:server/features/home/home.handler.dart';

Router configureHomeRoutes(HomeHandler handler) {
  final router = Router();
  final therapistOrAdmin = requireAnyRole(['therapist', 'admin']);

  router.get('/summary', therapistOrAdmin.call(handler.handleGetSummary));

  return router;
}
