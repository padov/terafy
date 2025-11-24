import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'package:server/features/patient/patient.handler.dart';

Router configurePatientRoutes(PatientHandler handler) {
  final router = Router();

  final therapistOrAdmin = requireAnyRole(['therapist', 'admin']);
  final therapistAdminOrPatient = requireAnyRole([
    'therapist',
    'admin',
    'patient',
  ]);

  router.get('/', therapistOrAdmin.call(handler.handleList));
  router.post('/', therapistOrAdmin.call(handler.handleCreate));

  router.get('/<id|[0-9]+>', (Request request, String id) async {
    return therapistAdminOrPatient.call(
      (Request req) => handler.handleGetById(req, id),
    )(request);
  });

  router.put('/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call(
      (Request req) => handler.handleUpdate(req, id),
    )(request);
  });

  router.delete('/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call(
      (Request req) => handler.handleDelete(req, id),
    )(request);
  });

  return router;
}
