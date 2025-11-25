import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'package:server/features/anamnesis/anamnesis.handler.dart';

Router configureAnamnesisRoutes(AnamnesisHandler handler) {
  final router = Router();

  final therapistOrAdmin = requireAnyRole(['therapist', 'admin']);

  // ========== ANAMNESIS ROUTES ==========

  // GET /anamnesis/patient/:patientId - Buscar anamnese por paciente
  router.get(
    '/patient/<patientId|[0-9]+>',
    (Request request, String patientId) async {
      return therapistOrAdmin.call(
        (Request req) => handler.handleGetByPatientId(req, patientId),
      )(request);
    },
  );

  // GET /anamnesis/:id - Buscar anamnese por ID
  router.get(
    '/<id|[0-9]+>',
    (Request request, String id) async {
      return therapistOrAdmin.call(
        (Request req) => handler.handleGetById(req, id),
      )(request);
    },
  );

  // POST /anamnesis - Criar anamnese
  router.post('/', therapistOrAdmin.call(handler.handleCreate));

  // PUT /anamnesis/:id - Atualizar anamnese
  router.put(
    '/<id|[0-9]+>',
    (Request request, String id) async {
      return therapistOrAdmin.call(
        (Request req) => handler.handleUpdate(req, id),
      )(request);
    },
  );

  // DELETE /anamnesis/:id - Deletar anamnese
  router.delete(
    '/<id|[0-9]+>',
    (Request request, String id) async {
      return therapistOrAdmin.call(
        (Request req) => handler.handleDelete(req, id),
      )(request);
    },
  );

  // ========== TEMPLATE ROUTES ==========

  // GET /anamnesis/templates - Listar templates
  router.get('/templates', therapistOrAdmin.call(handler.handleListTemplates));

  // GET /anamnesis/templates/:id - Buscar template por ID
  router.get(
    '/templates/<id|[0-9]+>',
    (Request request, String id) async {
      return therapistOrAdmin.call(
        (Request req) => handler.handleGetTemplateById(req, id),
      )(request);
    },
  );

  // POST /anamnesis/templates - Criar template
  router.post(
    '/templates',
    therapistOrAdmin.call(handler.handleCreateTemplate),
  );

  // PUT /anamnesis/templates/:id - Atualizar template
  router.put(
    '/templates/<id|[0-9]+>',
    (Request request, String id) async {
      return therapistOrAdmin.call(
        (Request req) => handler.handleUpdateTemplate(req, id),
      )(request);
    },
  );

  // DELETE /anamnesis/templates/:id - Deletar template
  router.delete(
    '/templates/<id|[0-9]+>',
    (Request request, String id) async {
      return therapistOrAdmin.call(
        (Request req) => handler.handleDeleteTemplate(req, id),
      )(request);
    },
  );

  return router;
}

