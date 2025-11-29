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
    try {
      return await _repository.getAnamnesisByPatientId(
        patientId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );
    } catch (e) {
      throw AnamnesisException(
        'Erro ao buscar anamnese: ${e.toString()}',
        500,
      );
    }
  }

  Future<Anamnesis?> getAnamnesisById(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    try {
      return await _repository.getAnamnesisById(
        id,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );
    } catch (e) {
      throw AnamnesisException(
        'Erro ao buscar anamnese: ${e.toString()}',
        500,
      );
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
        throw AnamnesisException(
          'Já existe uma anamnese para este paciente. Use a atualização.',
          409,
        );
      }

      return await _repository.createAnamnesis(
        anamnesis,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? anamnesis.therapistId,
        bypassRLS: bypassRLS,
      );
    } catch (e) {
      AppLogger.error(e);
      if (e is AnamnesisException) rethrow;
      final errorStr = e.toString();
      if (errorStr.contains('23505') || errorStr.contains('unique')) {
        throw AnamnesisException(
          'Já existe uma anamnese para este paciente.',
          409,
        );
      }
      throw AnamnesisException(
        'Erro ao criar anamnese: ${e.toString()}',
        500,
      );
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
    try {
      return await _repository.updateAnamnesis(
        id,
        anamnesis,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? anamnesis.therapistId,
        bypassRLS: bypassRLS,
      );
    } catch (e) {
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException(
        'Erro ao atualizar anamnese: ${e.toString()}',
        500,
      );
    }
  }

  Future<void> deleteAnamnesis(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
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
    } catch (e) {
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException(
        'Erro ao remover anamnese: ${e.toString()}',
        500,
      );
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
    try {
      return await _repository.getTemplates(
        therapistId: therapistId,
        category: category,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );
    } catch (e) {
      throw AnamnesisException(
        'Erro ao listar templates: ${e.toString()}',
        500,
      );
    }
  }

  Future<AnamnesisTemplate?> getTemplateById(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    try {
      return await _repository.getTemplateById(
        id,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: bypassRLS,
      );
    } catch (e) {
      throw AnamnesisException(
        'Erro ao buscar template: ${e.toString()}',
        500,
      );
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
    } catch (e) {
      AppLogger.error(e);
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException(
        'Erro ao criar template: ${e.toString()}',
        500,
      );
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
    try {
      return await _repository.updateTemplate(
        id,
        template,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? template.therapistId,
        bypassRLS: bypassRLS,
      );
    } catch (e) {
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException(
        'Erro ao atualizar template: ${e.toString()}',
        500,
      );
    }
  }

  Future<void> deleteTemplate(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
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
    } catch (e) {
      if (e is AnamnesisException) rethrow;
      throw AnamnesisException(
        'Erro ao remover template: ${e.toString()}',
        500,
      );
    }
  }
}

