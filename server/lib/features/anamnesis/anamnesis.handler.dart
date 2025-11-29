import 'dart:convert';

import 'package:common/common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/features/anamnesis/anamnesis.controller.dart';
import 'package:server/features/anamnesis/anamnesis.routes.dart';

class AnamnesisHandler extends BaseHandler {
  final AnamnesisController _controller;

  AnamnesisHandler(this._controller);

  @override
  Router get router => configureAnamnesisRoutes(this);

  // ========== ANAMNESIS HANDLERS ==========

  Future<Response> handleGetByPatientId(Request request, String patientId) async {
    AppLogger.func();

    try {
      final id = int.tryParse(patientId);
      if (id == null) {
        return badRequestResponse('ID do paciente inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final anamnesis = await _controller.getAnamnesisByPatientId(
        id,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (anamnesis == null) {
        return notFoundResponse('Anamnese não encontrada para este paciente');
      }

      return successResponse(anamnesis.toJson());
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao buscar anamnese: ${e.toString()}');
    }
  }

  Future<Response> handleGetById(Request request, String id) async {
    AppLogger.func();

    try {
      final anamnesisId = int.tryParse(id);
      if (anamnesisId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final anamnesis = await _controller.getAnamnesisById(
        anamnesisId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (anamnesis == null) {
        return notFoundResponse('Anamnese não encontrada');
      }

      return successResponse(anamnesis.toJson());
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao buscar anamnese: ${e.toString()}');
    }
  }

  Future<Response> handleCreate(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final patientId = _readInt(data, ['patientId', 'patient_id']);
      if (patientId == null) {
        return badRequestResponse('patientId é obrigatório');
      }

      int? therapistId = _readInt(data, ['therapistId', 'therapist_id']);

      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil antes de criar anamneses.');
        }
        therapistId = accountId;
      } else if (userRole != 'admin') {
        return forbiddenResponse('Apenas terapeutas ou administradores podem criar anamneses');
      }

      if (therapistId == null) {
        return badRequestResponse('therapistId é obrigatório');
      }

      final anamnesis = _anamnesisFromRequestMap(data: data, patientId: patientId, therapistId: therapistId);

      final created = await _controller.createAnamnesis(
        anamnesis: anamnesis,
        userId: userId,
        userRole: userRole,
        accountId: therapistId,
        bypassRLS: userRole == 'admin',
      );

      return createdResponse(created.toJson());
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao criar anamnese: ${e.toString()}');
    }
  }

  Future<Response> handleUpdate(Request request, String id) async {
    AppLogger.func();

    try {
      final anamnesisId = int.tryParse(id);
      if (anamnesisId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final existing = await _controller.getAnamnesisById(
        anamnesisId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (existing == null) {
        return notFoundResponse('Anamnese não encontrada');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final updatedAnamnesis = _anamnesisFromRequestMap(
        data: data,
        patientId: existing.patientId,
        therapistId: existing.therapistId,
        base: existing,
      );

      final result = await _controller.updateAnamnesis(
        anamnesisId,
        anamnesis: updatedAnamnesis,
        userId: userId,
        userRole: userRole,
        accountId: existing.therapistId,
        bypassRLS: userRole == 'admin',
      );

      if (result == null) {
        return notFoundResponse('Anamnese não encontrada');
      }

      return successResponse(result.toJson());
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao atualizar anamnese: ${e.toString()}');
    }
  }

  Future<Response> handleDelete(Request request, String id) async {
    AppLogger.func();

    try {
      final anamnesisId = int.tryParse(id);
      if (anamnesisId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      await _controller.deleteAnamnesis(
        anamnesisId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return successResponse({'message': 'Anamnese removida com sucesso'});
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao remover anamnese: ${e.toString()}');
    }
  }

  // ========== TEMPLATE HANDLERS ==========

  Future<Response> handleListTemplates(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      int? therapistFilter;
      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil antes de acessar templates.');
        }
        therapistFilter = accountId;
      } else if (userRole == 'admin') {
        final therapistIdParam = request.url.queryParameters['therapistId'];
        if (therapistIdParam != null && therapistIdParam.isNotEmpty) {
          therapistFilter = int.tryParse(therapistIdParam);
          if (therapistFilter == null) {
            return badRequestResponse('Parâmetro therapistId inválido');
          }
        }
      }

      final category = request.url.queryParameters['category'];

      final templates = await _controller.listTemplates(
        therapistId: therapistFilter,
        category: category,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return successResponse(templates.map((template) => template.toJson()).toList());
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao listar templates: ${e.toString()}');
    }
  }

  Future<Response> handleGetTemplateById(Request request, String id) async {
    AppLogger.func();

    try {
      final templateId = int.tryParse(id);
      if (templateId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final template = await _controller.getTemplateById(
        templateId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (template == null) {
        return notFoundResponse('Template não encontrado');
      }

      return successResponse(template.toJson());
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao buscar template: ${e.toString()}');
    }
  }

  Future<Response> handleCreateTemplate(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      int? therapistId = _readInt(data, ['therapistId', 'therapist_id']);

      if (userRole == 'therapist') {
        if (accountId == null) {
          return badRequestResponse('Conta de terapeuta não vinculada. Complete o perfil antes de criar templates.');
        }
        therapistId = accountId;
      } else if (userRole != 'admin') {
        return forbiddenResponse('Apenas terapeutas ou administradores podem criar templates');
      }

      final template = _templateFromRequestMap(data: data, therapistId: therapistId);

      final created = await _controller.createTemplate(
        template: template,
        userId: userId,
        userRole: userRole,
        accountId: therapistId,
        bypassRLS: userRole == 'admin',
      );

      return createdResponse(created.toJson());
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao criar template: ${e.toString()}');
    }
  }

  Future<Response> handleUpdateTemplate(Request request, String id) async {
    AppLogger.func();

    try {
      final templateId = int.tryParse(id);
      if (templateId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final existing = await _controller.getTemplateById(
        templateId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (existing == null) {
        return notFoundResponse('Template não encontrado');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final updatedTemplate = _templateFromRequestMap(data: data, therapistId: existing.therapistId, base: existing);

      final result = await _controller.updateTemplate(
        templateId,
        template: updatedTemplate,
        userId: userId,
        userRole: userRole,
        accountId: existing.therapistId,
        bypassRLS: userRole == 'admin',
      );

      if (result == null) {
        return notFoundResponse('Template não encontrado');
      }

      return successResponse(result.toJson());
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao atualizar template: ${e.toString()}');
    }
  }

  Future<Response> handleDeleteTemplate(Request request, String id) async {
    AppLogger.func();

    try {
      final templateId = int.tryParse(id);
      if (templateId == null) {
        return badRequestResponse('ID inválido');
      }

      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      await _controller.deleteTemplate(
        templateId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return successResponse({'message': 'Template removido com sucesso'});
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao remover template: ${e.toString()}');
    }
  }

  // ========== HELPER METHODS ==========

  Anamnesis _anamnesisFromRequestMap({
    required Map<String, dynamic> data,
    required int patientId,
    required int therapistId,
    Anamnesis? base,
  }) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    Map<String, dynamic> parseJson(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        } catch (_) {
          return {};
        }
      }
      return {};
    }

    return Anamnesis(
      id: base?.id,
      patientId: patientId,
      therapistId: therapistId,
      templateId: _readInt(data, ['templateId', 'template_id']) ?? base?.templateId,
      data: parseJson(_read<dynamic>(data, ['data'])),
      completedAt: parseDate(_read<dynamic>(data, ['completedAt', 'completed_at'])) ?? base?.completedAt,
      createdAt: base?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  AnamnesisTemplate _templateFromRequestMap({
    required Map<String, dynamic> data,
    int? therapistId,
    AnamnesisTemplate? base,
  }) {
    Map<String, dynamic> parseJson(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        } catch (_) {
          return {};
        }
      }
      return {};
    }

    return AnamnesisTemplate(
      id: base?.id,
      therapistId: therapistId ?? base?.therapistId,
      name: _readString(data, ['name']) ?? base?.name ?? '',
      description: _readString(data, ['description']) ?? base?.description,
      category: _readString(data, ['category']) ?? base?.category,
      isDefault: _readBool(data, ['isDefault', 'is_default']) ?? base?.isDefault ?? false,
      isSystem: _readBool(data, ['isSystem', 'is_system']) ?? base?.isSystem ?? false,
      structure: parseJson(_read<dynamic>(data, ['structure'])),
      createdAt: base?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    final value = _read<dynamic>(data, keys);
    if (value == null) return null;
    return value.toString();
  }

  static int? _readInt(Map<String, dynamic> data, List<String> keys) {
    final value = _read<dynamic>(data, keys);
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static bool? _readBool(Map<String, dynamic> data, List<String> keys) {
    final value = _read<dynamic>(data, keys);
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is num) return value != 0;
    return null;
  }

  static T? _read<T>(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        return data[key] as T?;
      }
    }
    return null;
  }
}
