import 'package:common/common.dart';
import 'package:postgres/postgres.dart';
import 'package:server/features/anamnesis/anamnesis.repository.dart';
import 'package:server/core/database/db_connection.dart';

// Mock do DBConnection para testes
class MockDBConnection extends DBConnection {
  @override
  Future<Connection> getConnection() async {
    throw UnimplementedError(
      'Use TestAnamnesisRepository para testes com dados mockados',
    );
  }
}

// Classe auxiliar para testes que simula o comportamento do AnamnesisRepository
class TestAnamnesisRepository extends AnamnesisRepository {
  final List<Anamnesis> _anamneses = [];
  final List<AnamnesisTemplate> _templates = [];
  int _lastAnamnesisId = 0;
  int _lastTemplateId = 0;

  TestAnamnesisRepository() : super(MockDBConnection());

  // ========== ANAMNESIS METHODS ==========

  @override
  Future<Anamnesis?> getAnamnesisByPatientId(
    int patientId, {
    required int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    try {
      return _anamneses.firstWhere((a) => a.patientId == patientId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Anamnesis?> getAnamnesisById(
    int id, {
    required int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    try {
      return _anamneses.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Anamnesis> createAnamnesis(
    Anamnesis anamnesis, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    // Verifica se já existe anamnese para este paciente
    final existing = await getAnamnesisByPatientId(
      anamnesis.patientId,
      userId: userId,
      userRole: userRole,
      accountId: accountId,
      bypassRLS: bypassRLS,
    );

    if (existing != null) {
      throw Exception('Anamnese já existe para este paciente');
    }

    final newAnamnesis = anamnesis.copyWith(
      id: ++_lastAnamnesisId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _anamneses.add(newAnamnesis);
    return newAnamnesis;
  }

  @override
  Future<Anamnesis?> updateAnamnesis(
    int id,
    Anamnesis anamnesis, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    final index = _anamneses.indexWhere((a) => a.id == id);
    if (index == -1) {
      return null;
    }

    final updated = anamnesis.copyWith(
      id: id,
      updatedAt: DateTime.now(),
    );

    _anamneses[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteAnamnesis(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    final index = _anamneses.indexWhere((a) => a.id == id);
    if (index == -1) {
      return false;
    }

    _anamneses.removeAt(index);
    return true;
  }

  // ========== TEMPLATE METHODS ==========

  @override
  Future<List<AnamnesisTemplate>> getTemplates({
    int? therapistId,
    String? category,
    required int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    var filtered = _templates.where((t) {
      if (therapistId != null && t.therapistId != therapistId && t.therapistId != null) {
        return false;
      }
      if (category != null && t.category != category) {
        return false;
      }
      return true;
    }).toList();

    // Inclui templates do sistema (therapistId == null)
    if (therapistId != null) {
      final systemTemplates = _templates.where((t) => t.therapistId == null);
      filtered = [...systemTemplates, ...filtered];
    }

    return filtered;
  }

  @override
  Future<AnamnesisTemplate?> getTemplateById(
    int id, {
    required int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<AnamnesisTemplate> createTemplate(
    AnamnesisTemplate template, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    // Se está marcando como padrão, remove o padrão anterior
    if (template.isDefault && template.therapistId != null) {
      for (var t in _templates) {
        if (t.therapistId == template.therapistId && t.isDefault) {
          _templates[_templates.indexOf(t)] = t.copyWith(isDefault: false);
        }
      }
    }

    final newTemplate = template.copyWith(
      id: ++_lastTemplateId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _templates.add(newTemplate);
    return newTemplate;
  }

  @override
  Future<AnamnesisTemplate?> updateTemplate(
    int id,
    AnamnesisTemplate template, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    final existing = await getTemplateById(
      id,
      userId: userId,
      userRole: userRole,
      accountId: accountId,
      bypassRLS: bypassRLS,
    );

    if (existing == null) {
      return null;
    }

    // Não permite editar templates do sistema
    if (existing.isSystem) {
      throw Exception('Não é possível editar templates do sistema');
    }

    // Se está marcando como padrão, remove o padrão anterior
    if (template.isDefault && template.therapistId != null) {
      for (var t in _templates) {
        if (t.therapistId == template.therapistId &&
            t.isDefault &&
            t.id != id) {
          _templates[_templates.indexOf(t)] = t.copyWith(isDefault: false);
        }
      }
    }

    final index = _templates.indexWhere((t) => t.id == id);
    final updated = template.copyWith(
      id: id,
      updatedAt: DateTime.now(),
    );

    _templates[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteTemplate(
    int id, {
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    final existing = await getTemplateById(
      id,
      userId: userId,
      userRole: userRole,
      accountId: accountId,
      bypassRLS: bypassRLS,
    );

    if (existing == null) {
      return false;
    }

    // Não permite deletar templates do sistema
    if (existing.isSystem) {
      throw Exception('Não é possível deletar templates do sistema');
    }

    final index = _templates.indexWhere((t) => t.id == id);
    if (index == -1) {
      return false;
    }

    _templates.removeAt(index);
    return true;
  }

  // Métodos auxiliares para testes
  void clear() {
    _anamneses.clear();
    _templates.clear();
    _lastAnamnesisId = 0;
    _lastTemplateId = 0;
  }

  List<Anamnesis> get allAnamneses => List.unmodifiable(_anamneses);
  List<AnamnesisTemplate> get allTemplates => List.unmodifiable(_templates);
}

