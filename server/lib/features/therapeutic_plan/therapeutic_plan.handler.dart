import 'dart:convert';

import 'package:common/common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/features/therapeutic_plan/therapeutic_plan.controller.dart';
import 'package:server/features/therapeutic_plan/therapeutic_plan.routes.dart';

class TherapeuticPlanHandler extends BaseHandler {
  TherapeuticPlanHandler(this._controller);

  final TherapeuticPlanController _controller;

  @override
  Router get router => configureTherapeuticPlanRoutes(this);

  // ============ THERAPEUTIC PLAN HANDLERS ============

  Future<Response> handleCreatePlan(Request request) async {
    AppLogger.func();
    try {
      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int? therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = data['therapistId'] ?? data['therapist_id'];
        if (therapistIdParam == null) {
          return badRequestResponse('Informe o therapistId para criar plano terapêutico.');
        }
        therapistId = int.tryParse(therapistIdParam.toString()) ?? (throw FormatException('therapistId inválido'));
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem criar planos terapêuticos.');
      }

      final plan = TherapeuticPlan.fromJson({...data, 'therapistId': therapistId});

      final created = await _controller.createPlan(
        plan: plan,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return createdResponse(created.toJson());
    } on TherapeuticPlanException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e, stack) {
      AppLogger.error(e, stack);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao criar plano terapêutico: ${e.toString()}');
    }
  }

  Future<Response> handleGetPlan(Request request, String id) async {
    AppLogger.func();
    try {
      final planId = int.tryParse(id);
      if (planId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final plan = await _controller.getPlan(planId: planId, userId: userId, userRole: userRole, accountId: accountId);

      return successResponse(plan.toJson());
    } on TherapeuticPlanException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao buscar plano terapêutico: ${e.toString()}');
    }
  }

  Future<Response> handleListPlans(Request request) async {
    AppLogger.func();
    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int? therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = request.url.queryParameters['therapistId'];
        if (therapistIdParam != null) {
          therapistId = int.tryParse(therapistIdParam) ?? (throw FormatException('therapistId inválido'));
        }
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem acessar planos terapêuticos.');
      }

      final patientIdParam = request.url.queryParameters['patientId'];
      final statusParam = request.url.queryParameters['status'];

      int? patientId = patientIdParam != null ? int.tryParse(patientIdParam) : null;

      final plans = await _controller.listPlans(
        patientId: patientId,
        therapistId: therapistId,
        status: statusParam,
        userId: userId,
        userRole: userRole,
        accountId: therapistId ?? accountId,
      );

      return successResponse(plans.map((plan) => plan.toJson()).toList());
    } on TherapeuticPlanException catch (e) {
      AppLogger.error(e, StackTrace.current);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      AppLogger.error(e, StackTrace.current);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao listar planos terapêuticos: ${e.toString()}');
    }
  }

  Future<Response> handleUpdatePlan(Request request, String id) async {
    AppLogger.func();
    try {
      final planId = int.tryParse(id);
      if (planId == null) {
        return badRequestResponse('ID inválido');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int? therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = data['therapistId'] ?? data['therapist_id'];
        if (therapistIdParam != null) {
          therapistId = int.tryParse(therapistIdParam.toString()) ?? (throw FormatException('therapistId inválido'));
        }
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem atualizar planos terapêuticos.');
      }

      final plan = TherapeuticPlan.fromJson({...data, if (therapistId != null) 'therapistId': therapistId});

      final updated = await _controller.updatePlan(
        planId: planId,
        plan: plan,
        userId: userId,
        userRole: userRole,
        accountId: therapistId ?? accountId,
      );

      return successResponse(updated.toJson());
    } on TherapeuticPlanException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao atualizar plano terapêutico: ${e.toString()}');
    }
  }

  Future<Response> handleDeletePlan(Request request, String id) async {
    AppLogger.func();
    try {
      final planId = int.tryParse(id);
      if (planId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      await _controller.deletePlan(planId: planId, userId: userId, userRole: userRole, accountId: accountId);

      return successResponse({'message': 'Plano terapêutico removido com sucesso'});
    } on TherapeuticPlanException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao remover plano terapêutico: ${e.toString()}');
    }
  }

  // ============ THERAPEUTIC OBJECTIVE HANDLERS ============

  Future<Response> handleCreateObjective(Request request) async {
    AppLogger.func();
    try {
      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int? therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = data['therapistId'] ?? data['therapist_id'];
        if (therapistIdParam == null) {
          return badRequestResponse('Informe o therapistId para criar objetivo terapêutico.');
        }
        therapistId = int.tryParse(therapistIdParam.toString()) ?? (throw FormatException('therapistId inválido'));
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem criar objetivos terapêuticos.');
      }

      final objective = TherapeuticObjective.fromJson({...data, 'therapistId': therapistId});

      final created = await _controller.createObjective(
        objective: objective,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return createdResponse(created.toJson());
    } on TherapeuticPlanException catch (e, stack) {
      AppLogger.error(e, stack);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e, stack) {
      AppLogger.error(e, stack);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao criar objetivo terapêutico: ${e.toString()}');
    }
  }

  Future<Response> handleGetObjective(Request request, String id) async {
    AppLogger.func();
    try {
      final objectiveId = int.tryParse(id);
      if (objectiveId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final objective = await _controller.getObjective(
        objectiveId: objectiveId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse(objective.toJson());
    } on TherapeuticPlanException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao buscar objetivo terapêutico: ${e.toString()}');
    }
  }

  Future<Response> handleListObjectives(Request request) async {
    AppLogger.func();
    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int? therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = request.url.queryParameters['therapistId'];
        if (therapistIdParam != null) {
          therapistId = int.tryParse(therapistIdParam) ?? (throw FormatException('therapistId inválido'));
        }
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem acessar objetivos terapêuticos.');
      }

      final planIdParam = request.url.queryParameters['planId'];
      final patientIdParam = request.url.queryParameters['patientId'];
      final statusParam = request.url.queryParameters['status'];
      final priorityParam = request.url.queryParameters['priority'];
      final deadlineTypeParam = request.url.queryParameters['deadlineType'];

      int? planId = planIdParam != null ? int.tryParse(planIdParam) : null;
      int? patientId = patientIdParam != null ? int.tryParse(patientIdParam) : null;

      final objectives = await _controller.listObjectives(
        planId: planId,
        patientId: patientId,
        therapistId: therapistId,
        status: statusParam,
        priority: priorityParam,
        deadlineType: deadlineTypeParam,
        userId: userId,
        userRole: userRole,
        accountId: therapistId ?? accountId,
      );

      return successResponse(objectives.map((obj) => obj.toJson()).toList());
    } on TherapeuticPlanException catch (e) {
      AppLogger.error(e, StackTrace.current);
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      AppLogger.error(e, StackTrace.current);
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao listar objetivos terapêuticos: ${e.toString()}');
    }
  }

  Future<Response> handleUpdateObjective(Request request, String id) async {
    AppLogger.func();
    try {
      final objectiveId = int.tryParse(id);
      if (objectiveId == null) {
        return badRequestResponse('ID inválido');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int? therapistId;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil primeiro.');
        }
        therapistId = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = data['therapistId'] ?? data['therapist_id'];
        if (therapistIdParam != null) {
          therapistId = int.tryParse(therapistIdParam.toString()) ?? (throw FormatException('therapistId inválido'));
        }
      } else {
        return forbiddenResponse('Somente terapeutas ou administradores podem atualizar objetivos terapêuticos.');
      }

      final objective = TherapeuticObjective.fromJson({...data, if (therapistId != null) 'therapistId': therapistId});

      final updated = await _controller.updateObjective(
        objectiveId: objectiveId,
        objective: objective,
        userId: userId,
        userRole: userRole,
        accountId: therapistId ?? accountId,
      );

      return successResponse(updated.toJson());
    } on TherapeuticPlanException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao atualizar objetivo terapêutico: ${e.toString()}');
    }
  }

  Future<Response> handleDeleteObjective(Request request, String id) async {
    AppLogger.func();
    try {
      final objectiveId = int.tryParse(id);
      if (objectiveId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      await _controller.deleteObjective(
        objectiveId: objectiveId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse({'message': 'Objetivo terapêutico removido com sucesso'});
    } on TherapeuticPlanException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } on FormatException catch (e) {
      return badRequestResponse(e.message);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao remover objetivo terapêutico: ${e.toString()}');
    }
  }
}
