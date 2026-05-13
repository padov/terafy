import 'package:equatable/equatable.dart';
import 'package:terafy/features/financial/models/payment.dart';
import 'package:terafy/features/sessions/models/session.dart';

// ========== EVENTS ==========

abstract class SessionsEvent extends Equatable {
  const SessionsEvent();

  @override
  List<Object?> get props => [];
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

  @override
  List<Object?> get props => [session];
}

class UpdateSession extends SessionsEvent {
  final Session session;

  const UpdateSession(this.session);
}

class CancelSession extends SessionsEvent {
  final String sessionId;
  final String reason;
  final bool cancelledByPatient;

  const CancelSession({required this.sessionId, required this.reason, required this.cancelledByPatient});
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

class RegisterSessionPayment extends SessionsEvent {
  final String sessionId;
  final double amount;
  final DateTime paymentDate;
  final String? receiptNumber;

  const RegisterSessionPayment({
    required this.sessionId,
    required this.amount,
    required this.paymentDate,
    this.receiptNumber,
  });
}

// ========== STATES ==========

abstract class SessionsState extends Equatable {
  const SessionsState();

  @override
  List<Object?> get props => [];
}

class SessionsInitial extends SessionsState {}

class SessionsLoading extends SessionsState {}

class SessionsLoaded extends SessionsState {
  final List<Session> sessions;
  final String patientId;

  const SessionsLoaded({required this.sessions, required this.patientId});

  @override
  List<Object?> get props => [sessions, patientId];
}

class SessionDetailsLoaded extends SessionsState {
  final Session session;
  final Payment? payment;

  const SessionDetailsLoaded(this.session, {this.payment});

  @override
  List<Object?> get props => [session, payment];
}

class SessionCreated extends SessionsState {
  final Session session;

  const SessionCreated(this.session);

  @override
  List<Object?> get props => [session];
}

class SessionUpdated extends SessionsState {
  final Session session;

  const SessionUpdated(this.session);
}

class SessionsError extends SessionsState {
  final String message;

  const SessionsError(this.message);

  @override
  List<Object?> get props => [message];
}
