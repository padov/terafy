import 'package:common/common.dart';
import 'package:server/features/therapist/therapist.repository.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:postgres/postgres.dart';

// Mock do DBConnection para testes
class MockDBConnection extends DBConnection {
  @override
  Future<Connection> getConnection() async {
    throw UnimplementedError('Use TestTherapistRepository para testes com dados mockados');
  }
}

// Classe auxiliar para testes que simula o comportamento do TherapistRepository
class TestTherapistRepository extends TherapistRepository {
  final List<Therapist> _therapists = [];
  final Map<int, int> _therapistUserIdMap = {}; // Mapeia therapistId -> userId
  int _lastId = 0;
  int? _currentUserId; // Simula contexto RLS
  int? _currentAccountId; // Simula accountId para RLS
  bool _bypassRLS = false;
  bool _hasRLSContext = false; // Indica se contexto RLS foi explicitamente definido

  TestTherapistRepository() : super(MockDBConnection());

  // Simula configuração de contexto RLS
  void _setRLSContext({int? userId, String? userRole, int? accountId, bool bypassRLS = false}) {
    _currentUserId = userId;
    _currentAccountId = accountId;
    _bypassRLS = bypassRLS;
    // Indica que contexto RLS foi explicitamente definido apenas se algum parâmetro foi passado
    // Se todos são null/false, não considera como contexto explícito
    _hasRLSContext = userId != null || userRole != null || accountId != null || bypassRLS;
  }

  // Simula filtro RLS - retorna apenas therapists que o usuário pode ver
  List<Therapist> _filterByRLS(List<Therapist> therapists) {
    if (_bypassRLS) {
      return therapists; // Admin vê todos
    }

    // Se contexto RLS não foi explicitamente definido, retorna todos (comportamento padrão para testes básicos)
    if (!_hasRLSContext) {
      return therapists;
    }

    // Se contexto foi definido mas não há userId/accountId, não retorna nada (RLS bloqueia)
    if (_currentUserId == null && _currentAccountId == null) {
      return [];
    }

    // Simula RLS: therapist só vê seus próprios dados baseado em accountId
    if (_currentAccountId != null) {
      return therapists.where((t) => t.id == _currentAccountId).toList();
    }

    // Se só tem userId mas não accountId, não retorna nada (precisa de accountId para ver therapist)
    return [];
  }

  @override
  Future<List<Therapist>> getAllTherapists({int? userId, String? userRole, bool bypassRLS = false}) async {
    _setRLSContext(userId: userId, userRole: userRole, bypassRLS: bypassRLS);
    final all = List<Therapist>.from(_therapists);
    return _filterByRLS(all);
  }

  @override
  Future<Therapist?> getTherapistById(
    int id, {
    int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);
    try {
      final therapist = _therapists.firstWhere((t) => t.id == id);
      final filtered = _filterByRLS([therapist]);
      return filtered.isEmpty ? null : filtered.first;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Therapist> createTherapist(Therapist therapist, {int? userId, String? userRole}) async {
    // Valida email único
    if (_therapists.any((t) => t.email == therapist.email)) {
      throw Exception('Email já está em uso');
    }

    final now = DateTime.now();
    final newTherapist = Therapist(
      id: ++_lastId,
      name: therapist.name,
      nickname: therapist.nickname,
      document: therapist.document,
      email: therapist.email,
      phone: therapist.phone,
      birthDate: therapist.birthDate,
      profilePictureUrl: therapist.profilePictureUrl,
      professionalRegistryType: therapist.professionalRegistryType,
      professionalRegistryNumber: therapist.professionalRegistryNumber,
      specialties: therapist.specialties,
      education: therapist.education,
      professionalPresentation: therapist.professionalPresentation,
      officeAddress: therapist.officeAddress,
      calendarSettings: therapist.calendarSettings,
      notificationPreferences: therapist.notificationPreferences,
      bankDetails: therapist.bankDetails,
      status: therapist.status,
      createdAt: now,
      updatedAt: now,
    );
    _therapists.add(newTherapist);
    return newTherapist;
  }

  @override
  Future<Therapist?> updateTherapist(
    int id,
    Therapist therapist, {
    int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    final index = _therapists.indexWhere((t) => t.id == id);
    if (index == -1) {
      return null;
    }

    // Verifica RLS
    final existing = _therapists[index];
    final filtered = _filterByRLS([existing]);
    if (filtered.isEmpty) {
      return null; // RLS bloqueou
    }

    // Valida email único (se mudou)
    if (therapist.email != existing.email && _therapists.any((t) => t.email == therapist.email && t.id != id)) {
      throw Exception('Email já está em uso');
    }

    final updated = Therapist(
      id: existing.id,
      name: therapist.name,
      nickname: therapist.nickname,
      document: therapist.document,
      email: therapist.email,
      phone: therapist.phone,
      birthDate: therapist.birthDate,
      profilePictureUrl: therapist.profilePictureUrl,
      professionalRegistryType: therapist.professionalRegistryType,
      professionalRegistryNumber: therapist.professionalRegistryNumber,
      specialties: therapist.specialties,
      education: therapist.education,
      professionalPresentation: therapist.professionalPresentation,
      officeAddress: therapist.officeAddress,
      calendarSettings: therapist.calendarSettings,
      notificationPreferences: therapist.notificationPreferences,
      bankDetails: therapist.bankDetails,
      status: therapist.status,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _therapists[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteTherapist(int id, {int? userId, String? userRole, int? accountId, bool bypassRLS = false}) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    final index = _therapists.indexWhere((t) => t.id == id);
    if (index == -1) {
      return false;
    }

    // Verifica RLS
    final existing = _therapists[index];
    final filtered = _filterByRLS([existing]);
    if (filtered.isEmpty) {
      return false; // RLS bloqueou
    }

    _therapists.removeAt(index);
    return true;
  }

  @override
  Future<Therapist> updateTherapistUserId(int therapistId, int userId) async {
    final index = _therapists.indexWhere((t) => t.id == therapistId);
    if (index == -1) {
      throw Exception('Therapist not found');
    }
    // Atualiza o mapeamento userId -> therapistId
    _therapistUserIdMap[therapistId] = userId;
    final updatedTherapist = Therapist(
      id: _therapists[index].id,
      name: _therapists[index].name,
      nickname: _therapists[index].nickname,
      document: _therapists[index].document,
      email: _therapists[index].email,
      phone: _therapists[index].phone,
      birthDate: _therapists[index].birthDate,
      profilePictureUrl: _therapists[index].profilePictureUrl,
      professionalRegistryType: _therapists[index].professionalRegistryType,
      professionalRegistryNumber: _therapists[index].professionalRegistryNumber,
      specialties: _therapists[index].specialties,
      education: _therapists[index].education,
      professionalPresentation: _therapists[index].professionalPresentation,
      officeAddress: _therapists[index].officeAddress,
      calendarSettings: _therapists[index].calendarSettings,
      notificationPreferences: _therapists[index].notificationPreferences,
      bankDetails: _therapists[index].bankDetails,
      status: _therapists[index].status,
      createdAt: _therapists[index].createdAt,
      updatedAt: DateTime.now(),
    );
    _therapists[index] = updatedTherapist;
    return updatedTherapist;
  }

  @override
  Future<Map<String, dynamic>?> getTherapistByUserIdWithPlan(int userId) async {
    // Busca o therapistId associado ao userId
    final therapistId = _therapistUserIdMap.entries
        .where((entry) => entry.value == userId)
        .map((entry) => entry.key)
        .firstOrNull;

    if (therapistId == null) {
      return null;
    }

    // Busca o therapist
    final therapist = _therapists.firstWhere(
      (t) => t.id == therapistId,
      orElse: () => throw Exception('Therapist not found'),
    );

    // Converte para JSON e adiciona informações do plano (simulado)
    final therapistJson = therapist.toJson();
    therapistJson['plan'] = {'id': 0, 'name': 'Free', 'price': 0.0, 'patient_limit': 5};

    return therapistJson;
  }

  @override
  Future<void> createPlanSubscription({
    required int therapistId,
    required int planId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Simulação: apenas verifica se o therapist existe
    _therapists.firstWhere((t) => t.id == therapistId, orElse: () => throw Exception('Therapist not found'));
    // Em um teste real, você poderia armazenar a subscription
    return;
  }

  void clear() {
    _therapists.clear();
    _therapistUserIdMap.clear();
    _lastId = 0;
    _currentUserId = null;
    _currentAccountId = null;
    _bypassRLS = false;
    _hasRLSContext = false;
  }
}
