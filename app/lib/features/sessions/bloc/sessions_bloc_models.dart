import 'package:terafy/features/sessions/models/session.dart';

// ========== EVENTS ==========

abstract class SessionsEvent {
  const SessionsEvent();
}

class LoadPatientSessions extends SessionsEvent {
  final String patientId;

  const LoadPatientSessions(this.patientId);
}

class LoadSessionDetails extends SessionsEvent {
  final String sessionId;

  const LoadSessionDetails(this.sessionId);
}

class CreateSession extends SessionsEvent {
  final Session session;

  const CreateSession(this.session);
}

class UpdateSession extends SessionsEvent {
  final Session session;

  const UpdateSession(this.session);
}

class CancelSession extends SessionsEvent {
  final String sessionId;
  final String reason;
  final bool cancelledByPatient;

  const CancelSession({
    required this.sessionId,
    required this.reason,
    required this.cancelledByPatient,
  });
}

class ConfirmSession extends SessionsEvent {
  final String sessionId;

  const ConfirmSession(this.sessionId);
}

class MarkAsCompleted extends SessionsEvent {
  final String sessionId;

  const MarkAsCompleted(this.sessionId);
}

class MarkAsNoShow extends SessionsEvent {
  final String sessionId;

  const MarkAsNoShow(this.sessionId);
}

// ========== STATES ==========

abstract class SessionsState {
  const SessionsState();
}

class SessionsInitial extends SessionsState {}

class SessionsLoading extends SessionsState {}

class SessionsLoaded extends SessionsState {
  final List<Session> sessions;
  final String patientId;

  const SessionsLoaded({required this.sessions, required this.patientId});
}

class SessionDetailsLoaded extends SessionsState {
  final Session session;

  const SessionDetailsLoaded(this.session);
}

class SessionCreated extends SessionsState {
  final Session session;

  const SessionCreated(this.session);
}

class SessionUpdated extends SessionsState {
  final Session session;

  const SessionUpdated(this.session);
}

class SessionsError extends SessionsState {
  final String message;

  const SessionsError(this.message);
}
