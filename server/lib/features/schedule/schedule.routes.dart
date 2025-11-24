import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'package:server/features/schedule/schedule.handler.dart';

Router configureScheduleRoutes(ScheduleHandler handler) {
  final router = Router();

  final therapistOrAdmin = requireAnyRole(['therapist', 'admin']);

  router.get('/settings', therapistOrAdmin.call(handler.handleGetSettings));

  router.put('/settings', therapistOrAdmin.call(handler.handleUpdateSettings));

  router.get('/appointments', therapistOrAdmin.call(handler.handleListAppointments));

  router.get('/appointments/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleGetAppointment(req, id))(request);
  });

  router.post('/appointments', therapistOrAdmin.call(handler.handleCreateAppointment));

  router.put('/appointments/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleUpdateAppointment(req, id))(request);
  });

  router.delete('/appointments/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleDeleteAppointment(req, id))(request);
  });

  return router;
}
