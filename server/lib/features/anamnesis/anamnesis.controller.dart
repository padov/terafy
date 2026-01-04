import 'package:common/common.dart';
import 'package:server/features/anamnesis/anamnesis.repository.dart';

class AnamnesisException implements Exception {
  final String message;
  final int statusCode;

  AnamnesisException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class AnamnesisController {
  final AnamnesisRepository _repository;

  AnamnesisController(this._repository);

  // ========== ANAMNESIS METHODS ==========

  Future<Anamnesis?> getAnamnesisByPatientId(
    int patientId, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    try {
      return await _repository.getAnamnesisByPatientId(
        patientId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      throw AnamnesisException('Erro ao buscar anamnese: ${e.toString()}', 500);
    }
  }

  Future<Anamnesis?> getAnamnesisById(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    try {
      return await _repository.getAnamnesisById(
        id,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      throw AnamnesisException('Erro ao buscar anamnese: ${e.toString()}', 500);
    }
  }

  Future<Anamnesis> createAnamnesis({
    required Anamnesis anamnesis,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    try {
      // Verifica se já existe anamnese para este paciente
      final existing = await _repository.getAnamnesisByPatientId(
        anamnesis.patientId,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? anamnesis.therapistId,
        bypassRLS: bypassRLS,
      );

      if (existing != null) {
        throw AnamnesisException('Já existe uma anamnese para este paciente. Use a atualização.', 409);
      }

      return await _repository.createAnamnesis(
        anamnesis,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? anamnesis.therapistId,
        bypassRLS: bypassRLS,
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is AnamnesisException) rethrow;
      final errorStr = e.toString();
      if (errorStr.contains('23505') || errorStr.contains('unique')) {
        throw AnamnesisException('Já existe uma anamnese para este paciente.', 409);
      }
      throw AnamnesisException('Erro ao criar anamnese: ${e.toString()}', 500);
    }
  }

  Future<Anamnesis?> updateAnamnesis(
    int id, {
    required Anamnesis anamnesis,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    try {
      return await _repository.updateAnamnesis(
        id,
        anamnesis,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? anamnesis.therapistId,
        bypassRLS: bypassRLS,
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException('Erro ao atualizar anamnese: ${e.toString()}', 500);
    }
  }

  Future<void> deleteAnamnesis(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    try {
      final deleted = await _repository.deleteAnamnesis(
        id,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );

      if (!deleted) {
        throw AnamnesisException('Anamnese não encontrada', 404);
      }
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException('Erro ao remover anamnese: ${e.toString()}', 500);
    }
  }

  // ========== TEMPLATE METHODS ==========

  Future<List<AnamnesisTemplate>> listTemplates({
    int? therapistId,
    String? category,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    try {
      return await _repository.getTemplates(
        therapistId: therapistId,
        category: category,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      throw AnamnesisException('Erro ao listar templates: ${e.toString()}', 500);
    }
  }

  Future<AnamnesisTemplate?> getTemplateById(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    try {
      return await _repository.getTemplateById(
        id,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      throw AnamnesisException('Erro ao buscar template: ${e.toString()}', 500);
    }
  }

  Future<AnamnesisTemplate> createTemplate({
    required AnamnesisTemplate template,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    try {
      return await _repository.createTemplate(
        template,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? template.therapistId,
        bypassRLS: bypassRLS,
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException('Erro ao criar template: ${e.toString()}', 500);
    }
  }

  Future<AnamnesisTemplate?> updateTemplate(
    int id, {
    required AnamnesisTemplate template,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    try {
      return await _repository.updateTemplate(
        id,
        template,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? template.therapistId,
        bypassRLS: bypassRLS,
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException('Erro ao atualizar template: ${e.toString()}', 500);
    }
  }

  Future<void> deleteTemplate(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    try {
      final deleted = await _repository.deleteTemplate(
        id,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );

      if (!deleted) {
        throw AnamnesisException('Template não encontrado', 404);
      }
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException('Erro ao remover template: ${e.toString()}', 500);
    }
  }

  // ========== INVITE METHODS ==========

  Future<String> createInvite({
    required int therapistId,
    required int patientId,
    required int templateId,
    required int userId,
  }) async {
    AppLogger.func();
    try {
      // Default expiry: 7 days
      final expiresAt = DateTime.now().add(const Duration(days: 7));

      return await _repository.createInvite(
        therapistId: therapistId,
        patientId: patientId,
        templateId: templateId,
        expiresAt: expiresAt,
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      throw AnamnesisException('Erro ao criar convite: ${e.toString()}', 500);
    }
  }

  Future<Map<String, dynamic>> getPublicInviteContext(String token) async {
    AppLogger.func();
    try {
      final data = await _repository.getInviteByToken(token);
      if (data == null) {
        throw AnamnesisException('Convite inválido ou expirado', 404);
      }

      // Transform flat DB structure to nested JSON structure expected by frontend
      return {
        'patientName': data['patient_name'],
        'therapistName': data['therapist_name'],
        'template': {
          'id': data['template_id'],
          'name': data['template_name'],
          'description': data['template_description'],
          'structure': data['template_structure'], // This is already a Map/JSON from DB
        },
      };
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException('Erro ao buscar convite: ${e.toString()}', 500);
    }
  }

  Future<Anamnesis> submitPublicInvite(String token, Map<String, dynamic> formData) async {
    AppLogger.func();
    try {
      final invite = await _repository.getInviteByToken(token);
      if (invite == null) {
        throw AnamnesisException('Convite inválido ou expirado', 404);
      }

      final patientId = invite['patient_id'] as int;
      final therapistId = invite['therapist_id'] as int;
      final templateId = invite['template_id'] as int;

      // Create Anamnesis object
      final anamnesis = Anamnesis(
        id: 0, // New
        patientId: patientId,
        therapistId: therapistId,
        templateId: templateId,
        data: formData,
        completedAt: DateTime.now(), // Auto-complete when submitted by patient
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _repository.createAnamnesis(
        anamnesis,
        userId: 0, // System/Public context
        userRole: 'system',
        bypassRLS: true,
      );

      await _repository.consumeInvite(invite['id'] as int);

      return created;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException('Erro ao submeter anamnese: ${e.toString()}', 500);
    }
  }
}
