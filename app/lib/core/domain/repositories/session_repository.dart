import 'package:common/common.dart';

abstract class SessionRepository {
  Future<List<Session>> fetchSessions({
    int? patientId,
    int? therapistId,
    int? appointmentId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Session> fetchSession(int sessionId);

  Future<Session> createSession(Session session);

  Future<Session> updateSession(int sessionId, Session session);

  Future<void> deleteSession(int sessionId);

  Future<int> getNextSessionNumber(int patientId);
}
