import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'therapist.handler.dart';

/// Configuração de rotas para a feature de terapeutas
///
/// Este arquivo contém apenas a definição das rotas HTTP.
/// A implementação dos handlers está em `therapist.handler.dart`.
Router configureTherapistRoutes(TherapistHandler handler) {
  final router = Router();

  router.get('/me', requireRole('therapist').call(handler.handleGetMe));
  router.put('/me', requireRole('therapist').call(handler.handleUpdateMe));
  router.post('/me', requireRole('therapist').call(handler.handleCreate));

  final roleAdmin = requireRole('admin');
  router.get('/', roleAdmin.call(handler.handleGetAll));
  router.get('/<id|[0-9]+>', (Request request, String id) async {
    return roleAdmin.call((Request req) => handler.handleGetById(req, id))(
      request,
    );
  });
  router.put('/<id|[0-9]+>', (Request request, String id) async {
    return roleAdmin.call((Request req) => handler.handleUpdate(req, id))(
      request,
    );
  });
  router.delete('/<id|[0-9]+>', (Request request, String id) async {
    return roleAdmin.call((Request req) => handler.handleDelete(req, id))(
      request,
    );
  });

  return router;
}
