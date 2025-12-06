import 'package:common/common.dart';
import 'package:server/features/session/session.repository.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:postgres/postgres.dart' hide Session;

// Mock do DBConnection para testes
class MockDBConnection extends DBConnection {
  @override
  Future<Connection> getConnection() async {
    throw UnimplementedError('Use TestSessionRepository para testes com dados mockados');
  }
}

// Classe auxiliar para testes que simula o comportamento do SessionRepository
class TestSessionRepository extends SessionRepository {
  final List<Session> _sessions = [];
  int _lastId = 0;
  int? _currentUserId;
  bool _bypassRLS = false;

  TestSessionRepository() : super(MockDBConnection());

  void _setRLSContext({int? userId, String? userRole, int? accountId, bool bypassRLS = false}) {
    _currentUserId = userId;
    _bypassRLS = bypassRLS;
  }

  List<Session> _filterByRLS(List<Session> sessions) {
    if (_bypassRLS) {
      return sessions;
    }
    if (_currentUserId == null) {
      return [];
    }
    return sessions; // Simplificado para testes
  }

  @override
  Future<Session> createSession({
    required Session session,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    final now = DateTime.now();
    final newSession = Session(
      id: ++_lastId,
      patientId: session.patientId,
      therapistId: session.therapistId,
      appointmentId: session.appointmentId,
      scheduledStartTime: session.scheduledStartTime,
      scheduledEndTime: session.scheduledEndTime,
      durationMinutes: session.durationMinutes,
      sessionNumber: session.sessionNumber,
      type: session.type,
      modality: session.modality,
      location: session.location,
      onlineRoomLink: session.onlineRoomLink,
      status: session.status,
      cancellationReason: session.cancellationReason,
      cancellationTime: session.cancellationTime,
      chargedAmount: session.chargedAmount,
      paymentStatus: session.paymentStatus,
      patientMood: session.patientMood,
      topicsDiscussed: session.topicsDiscussed,
      sessionNotes: session.sessionNotes,
      observedBehavior: session.observedBehavior,
      interventionsUsed: session.interventionsUsed,
      resourcesUsed: session.resourcesUsed,
      homework: session.homework,
      patientReactions: session.patientReactions,
      progressObserved: session.progressObserved,
      difficultiesIdentified: session.difficultiesIdentified,
      nextSteps: session.nextSteps,
      nextSessionGoals: session.nextSessionGoals,
      needsReferral: session.needsReferral,
      currentRisk: session.currentRisk,
      importantObservations: session.importantObservations,
      presenceConfirmationTime: session.presenceConfirmationTime,
      reminderSent: session.reminderSent,
      reminderSentTime: session.reminderSentTime,
      patientRating: session.patientRating,
      attachments: session.attachments,
      createdAt: now,
      updatedAt: now,
    );
    _sessions.add(newSession);
    return newSession;
  }

  @override
  Future<Session?> getSessionById({
    required int sessionId,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);
    try {
      final session = _sessions.firstWhere((s) => s.id == sessionId);
      final filtered = _filterByRLS([session]);
      return filtered.isEmpty ? null : filtered.first;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Session>> listSessions({
    required int userId,
    String? userRole,
    int? accountId,
    int? appointmentId,
    int? therapistId,
    int? patientId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? statuses,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    var filtered = List<Session>.from(_sessions);

    if (appointmentId != null) {
      filtered = filtered.where((s) => s.appointmentId == appointmentId).toList();
    }
    if (therapistId != null) {
      filtered = filtered.where((s) => s.therapistId == therapistId).toList();
    }
    if (patientId != null) {
      filtered = filtered.where((s) => s.patientId == patientId).toList();
    }
    if (statuses != null && statuses.isNotEmpty) {
      filtered = filtered.where((s) => statuses.contains(s.status)).toList();
    }
    if (startDate != null) {
      filtered = filtered
          .where((s) => s.scheduledStartTime.isAfter(startDate) || s.scheduledStartTime.isAtSameMomentAs(startDate))
          .toList();
    }
    if (endDate != null) {
      filtered = filtered
          .where((s) => s.scheduledStartTime.isBefore(endDate) || s.scheduledStartTime.isAtSameMomentAs(endDate))
          .toList();
    }

    return _filterByRLS(filtered);
  }

  @override
  Future<Session?> updateSession({
    required int sessionId,
    required Session session,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) {
      return null;
    }

    final existing = _sessions[index];
    final filtered = _filterByRLS([existing]);
    if (filtered.isEmpty) {
      return null;
    }

    final updated = Session(
      id: existing.id,
      patientId: existing.patientId, // Não pode mudar
      therapistId: existing.therapistId, // Não pode mudar
      appointmentId: existing.appointmentId,
      scheduledStartTime: session.scheduledStartTime,
      scheduledEndTime: session.scheduledEndTime,
      durationMinutes: session.durationMinutes,
      sessionNumber: existing.sessionNumber, // Não pode mudar
      type: session.type,
      modality: session.modality,
      location: session.location,
      onlineRoomLink: session.onlineRoomLink,
      status: session.status,
      cancellationReason: session.cancellationReason,
      cancellationTime: session.cancellationTime,
      chargedAmount: session.chargedAmount,
      paymentStatus: session.paymentStatus,
      patientMood: session.patientMood,
      topicsDiscussed: session.topicsDiscussed,
      sessionNotes: session.sessionNotes,
      observedBehavior: session.observedBehavior,
      interventionsUsed: session.interventionsUsed,
      resourcesUsed: session.resourcesUsed,
      homework: session.homework,
      patientReactions: session.patientReactions,
      progressObserved: session.progressObserved,
      difficultiesIdentified: session.difficultiesIdentified,
      nextSteps: session.nextSteps,
      nextSessionGoals: session.nextSessionGoals,
      needsReferral: session.needsReferral,
      currentRisk: session.currentRisk,
      importantObservations: session.importantObservations,
      presenceConfirmationTime: session.presenceConfirmationTime,
      reminderSent: session.reminderSent,
      reminderSentTime: session.reminderSentTime,
      patientRating: session.patientRating,
      attachments: session.attachments,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _sessions[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteSession({
    required int sessionId,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) {
      return false;
    }

    final existing = _sessions[index];
    final filtered = _filterByRLS([existing]);
    if (filtered.isEmpty) {
      return false;
    }

    _sessions.removeAt(index);
    return true;
  }

  @override
  Future<int> getNextSessionNumber({
    required int patientId,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    final patientSessions = _sessions.where((s) => s.patientId == patientId).toList();
    if (patientSessions.isEmpty) {
      return 1;
    }

    final maxNumber = patientSessions.map((s) => s.sessionNumber).reduce((a, b) => a > b ? a : b);
    return maxNumber + 1;
  }

  void clear() {
    _sessions.clear();
    _lastId = 0;
    _currentUserId = null;
    _bypassRLS = false;
  }
}
