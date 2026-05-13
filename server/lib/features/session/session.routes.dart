import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'package:server/features/session/session.handler.dart';

Router configureSessionRoutes(SessionHandler handler) {
  final router = Router();

  final therapistOrAdmin = requireAnyRole(['therapist', 'admin']);

  router.get('/', therapistOrAdmin.call(handler.handleListSessions));

  router.get('/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleGetSession(req, id))(request);
  });

  router.get('/next-number', (Request request) async {
    return therapistOrAdmin.call(handler.handleGetNextSessionNumber)(request);
  });

  router.post('/', therapistOrAdmin.call(handler.handleCreateSession));

  router.put('/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleUpdateSession(req, id))(request);
  });

  router.delete('/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleDeleteSession(req, id))(request);
  });
  router.post('/<id|[0-9]+>/analyze_audio', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleAnalyzeAudio(req, id))(request);
  });

  // v2: recebe texto livre + transcrição STT (sem upload de áudio)
  router.post('/<id|[0-9]+>/analyze_v2', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleAnalyzeTextV2(req, id))(request);
  });

  return router;
}
