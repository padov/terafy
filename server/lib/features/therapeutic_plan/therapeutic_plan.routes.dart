import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'package:server/features/therapeutic_plan/therapeutic_plan.handler.dart';

Router configureTherapeuticPlanRoutes(TherapeuticPlanHandler handler) {
  final router = Router();

  final therapistOrAdmin = requireAnyRole(['therapist', 'admin']);

  // ============ THERAPEUTIC PLAN ROUTES ============

  // GET /therapeutic-plans - Lista todos os planos
  router.get('/', therapistOrAdmin.call(handler.handleListPlans));

  // GET /therapeutic-plans/<id> - Busca um plano por ID
  router.get('/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleGetPlan(req, id))(request);
  });

  // POST /therapeutic-plans - Cria um novo plano
  router.post('/', therapistOrAdmin.call(handler.handleCreatePlan));

  // PUT /therapeutic-plans/<id> - Atualiza um plano
  router.put('/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleUpdatePlan(req, id))(request);
  });

  // DELETE /therapeutic-plans/<id> - Deleta um plano
  router.delete('/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleDeletePlan(req, id))(request);
  });

  // ============ THERAPEUTIC OBJECTIVE ROUTES (Nested) ============

  // GET /therapeutic-plans/objectives - Lista todos os objetivos
  router.get('/objectives', therapistOrAdmin.call(handler.handleListObjectives));

  // GET /therapeutic-plans/objectives/<id> - Busca um objetivo por ID
  router.get('/objectives/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleGetObjective(req, id))(request);
  });

  // POST /therapeutic-plans/objectives - Cria um novo objetivo
  router.post('/objectives', therapistOrAdmin.call(handler.handleCreateObjective));

  // PUT /therapeutic-plans/objectives/<id> - Atualiza um objetivo
  router.put('/objectives/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleUpdateObjective(req, id))(request);
  });

  // DELETE /therapeutic-plans/objectives/<id> - Deleta um objetivo
  router.delete('/objectives/<id|[0-9]+>', (Request request, String id) async {
    return therapistOrAdmin.call((Request req) => handler.handleDeleteObjective(req, id))(request);
  });

  return router;
}
