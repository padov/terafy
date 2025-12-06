import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:common/common.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/core/middleware/authorization_middleware.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/features/user/user.repository.dart';
import 'therapist.repository.dart';
import 'therapist.controller.dart';
import 'therapist.routes.dart';

class TherapistHandler extends BaseHandler {
  final TherapistRepository _repository;
  final UserRepository _userRepository;
  late final TherapistController _controller;

  TherapistHandler(this._repository, this._userRepository) {
    _controller = TherapistController(_repository, _userRepository);
  }

  @override
  Router get router => configureTherapistRoutes(this);

  /// Handler para rota GET /therapists
  /// Apenas admin pode acessar (verificado pelo middleware requireRole('admin'))
  Future<Response> handleGetAll(Request request) async {
    AppLogger.func();
    try {
      // Extrai informações do token para contexto RLS
      final userId = getUserId(request);
      final userRole = getUserRole(request);

      // Admin pode ver todos (bypass RLS)
      final therapists = await _controller.getAllTherapists(
        userId: userId,
        userRole: userRole,
        bypassRLS: userRole == 'admin',
      );
      final therapistsJson = therapists.map((t) => t.toJson()).toList();
      return successResponse(therapistsJson);
    } on TherapistException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao buscar terapeutas: ${e.toString()}');
    }
  }

  /// Handler para rota GET /therapists/me
  Future<Response> handleGetMe(Request request) async {
    AppLogger.func();
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return unauthorizedResponse('Usuário não autenticado');
      }

      final result = await _controller.getTherapistByUserId(userId);
      return successResponse(result.therapistData);
    } on TherapistException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao buscar terapeuta: ${e.toString()}');
    }
  }

  /// Handler para rota PUT /therapists/me
  /// Permite que o terapeuta atualize seus próprios dados
  Future<Response> handleUpdateMe(Request request) async {
    AppLogger.func();
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return unauthorizedResponse('Usuário não autenticado');
      }

      // Obtém o accountId que é o therapistId do usuário autenticado
      final accountId = getAccountId(request);
      if (accountId == null) {
        return badRequestResponse('Usuário não possui perfil de terapeuta vinculado');
      }

      // Extrai informações do token para contexto RLS
      final userRole = getUserRole(request);

      final body = await request.readAsString();
      if (body.isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final therapistMap = jsonDecode(body) as Map<String, dynamic>;
      final therapist = Therapist.fromMap(therapistMap);
      final updatedTherapist = await _controller.updateTherapist(
        accountId,
        therapist,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
      );

      return successResponse(updatedTherapist.toJson());
    } on TherapistException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao atualizar terapeuta: ${e.toString()}');
    }
  }

  /// Handler para rota GET /therapists/:id
  /// Apenas admin pode acessar (verificado pelo middleware requireRole('admin'))
  Future<Response> handleGetById(Request request, String id) async {
    AppLogger.func();
    try {
      final therapistId = int.tryParse(id);
      if (therapistId == null) {
        return badRequestResponse('ID inválido');
      }

      // Extrai informações do token para contexto RLS
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      // Admin pode ver qualquer um (bypass RLS)
      final therapist = await _controller.getTherapistById(
        therapistId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );
      return successResponse(therapist.toJson());
    } on TherapistException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao buscar terapeuta: ${e.toString()}');
    }
  }

  /// Handler para rota POST /therapists
  Future<Response> handleCreate(Request request) async {
    AppLogger.func();
    try {
      // Obtém o userId do token JWT
      final userId = getUserId(request);
      if (userId == null) {
        return unauthorizedResponse('Usuário não autenticado');
      }

      // Extrai informações do token para contexto RLS
      final userRole = getUserRole(request);

      final body = await request.readAsString();
      if (body.isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final therapistMap = jsonDecode(body) as Map<String, dynamic>;
      final newTherapist = Therapist.fromMap(therapistMap);

      // Extrai o planId do calendar_settings se presente
      int? planId;
      if (therapistMap['calendar_settings'] != null) {
        final calendarSettings = therapistMap['calendar_settings'] as Map<String, dynamic>;
        planId = calendarSettings['selected_plan_id'] as int?;
      }

      final result = await _controller.createTherapist(
        therapist: newTherapist,
        userId: userId,
        userRole: userRole,
        planId: planId,
      );

      return createdResponse(result.therapist.toJson());
    } on TherapistException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao criar terapeuta: ${e.toString()}');
    }
  }

  /// Handler para rota PUT /therapists/:id
  /// Admin pode atualizar qualquer um, therapist só pode atualizar o próprio
  Future<Response> handleUpdate(Request request, String id) async {
    AppLogger.func();
    try {
      final therapistId = int.tryParse(id);
      if (therapistId == null) {
        return badRequestResponse('ID inválido');
      }

      // Verifica acesso ao recurso
      final accessError = checkResourceAccess(
        request: request,
        resourceId: therapistId,
        allowedRoles: ['therapist', 'admin'],
      );
      if (accessError != null) return accessError;

      // Extrai informações do token para contexto RLS
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      final body = await request.readAsString();
      if (body.isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final therapistMap = jsonDecode(body) as Map<String, dynamic>;
      final therapist = Therapist.fromMap(therapistMap);
      final updatedTherapist = await _controller.updateTherapist(
        therapistId,
        therapist,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return successResponse(updatedTherapist.toJson());
    } on TherapistException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao atualizar terapeuta: ${e.toString()}');
    }
  }

  /// Handler para rota DELETE /therapists/:id
  /// Admin pode deletar qualquer um, therapist só pode deletar o próprio
  Future<Response> handleDelete(Request request, String id) async {
    AppLogger.func();
    try {
      final therapistId = int.tryParse(id);
      if (therapistId == null) {
        return badRequestResponse('ID inválido');
      }

      // Verifica acesso ao recurso
      final accessError = checkResourceAccess(
        request: request,
        resourceId: therapistId,
        allowedRoles: ['therapist', 'admin'],
      );
      if (accessError != null) return accessError;

      // Extrai informações do token para contexto RLS
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      await _controller.deleteTherapist(
        therapistId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );
      return successResponse({'message': 'Terapeuta deletado com sucesso'});
    } on TherapistException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao deletar terapeuta: ${e.toString()}');
    }
  }
}
