import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/domain/usecases/schedule/get_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/update_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/session/create_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/delete_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_sessions_usecase.dart';
import 'package:terafy/core/domain/usecases/session/update_session_usecase.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc_models.dart';
import 'package:terafy/features/sessions/models/session.dart';
import 'package:terafy/features/sessions/models/session_mapper.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  SessionsBloc({
    required GetSessionsUseCase getSessionsUseCase,
    required GetSessionUseCase getSessionUseCase,
    required CreateSessionUseCase createSessionUseCase,
    required UpdateSessionUseCase updateSessionUseCase,
    required DeleteSessionUseCase deleteSessionUseCase,
    required GetAppointmentUseCase getAppointmentUseCase,
    required UpdateAppointmentUseCase updateAppointmentUseCase,
  }) : _getSessionsUseCase = getSessionsUseCase,
       _getSessionUseCase = getSessionUseCase,
       _createSessionUseCase = createSessionUseCase,
       _updateSessionUseCase = updateSessionUseCase,
       _deleteSessionUseCase = deleteSessionUseCase,
       _getAppointmentUseCase = getAppointmentUseCase,
       _updateAppointmentUseCase = updateAppointmentUseCase,
       super(SessionsInitial()) {
    on<LoadPatientSessions>(_onLoadPatientSessions);
    on<LoadSessionDetails>(_onLoadSessionDetails);
    on<CreateSession>(_onCreateSession);
    on<UpdateSession>(_onUpdateSession);
    on<CancelSession>(_onCancelSession);
    on<ConfirmSession>(_onConfirmSession);
    on<MarkAsCompleted>(_onMarkAsCompleted);
    on<MarkAsNoShow>(_onMarkAsNoShow);
  }

  final GetSessionsUseCase _getSessionsUseCase;
  final GetSessionUseCase _getSessionUseCase;
  final CreateSessionUseCase _createSessionUseCase;
  final UpdateSessionUseCase _updateSessionUseCase;
  final DeleteSessionUseCase _deleteSessionUseCase;
  final GetAppointmentUseCase _getAppointmentUseCase;
  final UpdateAppointmentUseCase _updateAppointmentUseCase;

  Future<void> _onLoadPatientSessions(LoadPatientSessions event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());

    try {
      final patientId = int.tryParse(event.patientId);
      if (patientId == null) {
        emit(SessionsError('ID do paciente inválido'));
        return;
      }

      final commonSessions = await _getSessionsUseCase(patientId: patientId);
      final sessions = commonSessions.map((s) => mapToUiSession(s)).toList()
        ..sort((a, b) => b.scheduledStartTime.compareTo(a.scheduledStartTime));

      emit(SessionsLoaded(sessions: sessions, patientId: event.patientId));
    } catch (e) {
      emit(SessionsError('Erro ao carregar sessões: ${e.toString()}'));
    }
  }

  Future<void> _onLoadSessionDetails(LoadSessionDetails event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());

    try {
      final sessionId = int.tryParse(event.sessionId);
      if (sessionId == null) {
        emit(SessionsError('ID da sessão inválido'));
        return;
      }

      final commonSession = await _getSessionUseCase(sessionId);
      final session = mapToUiSession(commonSession);

      emit(SessionDetailsLoaded(session));
    } catch (e) {
      emit(SessionsError('Erro ao carregar detalhes da sessão: ${e.toString()}'));
    }
  }

  Future<void> _onCreateSession(CreateSession event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());

    try {
      final commonSession = mapToDomainSession(event.session);
      final created = await _createSessionUseCase(commonSession);
      final uiSession = mapToUiSession(created);

      emit(SessionCreated(uiSession));
    } catch (e) {
      emit(SessionsError('Erro ao criar sessão: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateSession(UpdateSession event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());

    try {
      final sessionId = int.tryParse(event.session.id);
      if (sessionId == null) {
        emit(SessionsError('ID da sessão inválido'));
        return;
      }

      final commonSession = mapToDomainSession(event.session);
      final updated = await _updateSessionUseCase(sessionId, commonSession);
      final uiSession = mapToUiSession(updated);

      emit(SessionUpdated(uiSession));
    } catch (e) {
      emit(SessionsError('Erro ao atualizar sessão: ${e.toString()}'));
    }
  }

  Future<void> _onCancelSession(CancelSession event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());

    try {
      final sessionId = int.tryParse(event.sessionId);
      if (sessionId == null) {
        emit(SessionsError('ID da sessão inválido'));
        return;
      }

      // Buscar sessão atual
      final commonSession = await _getSessionUseCase(sessionId);
      final uiSession = mapToUiSession(commonSession);

      // Atualizar status
      final updatedSession = uiSession.copyWith(
        status: event.cancelledByPatient ? SessionStatus.cancelledByPatient : SessionStatus.cancelledByTherapist,
        cancellationReason: event.reason,
        cancellationTime: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Salvar no backend
      final commonUpdated = mapToDomainSession(updatedSession);
      final saved = await _updateSessionUseCase(sessionId, commonUpdated);
      final finalSession = mapToUiSession(saved);

      emit(SessionUpdated(finalSession));
    } catch (e) {
      emit(SessionsError('Erro ao cancelar sessão: ${e.toString()}'));
    }
  }

  Future<void> _onConfirmSession(ConfirmSession event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());

    try {
      final sessionId = int.tryParse(event.sessionId);
      if (sessionId == null) {
        emit(SessionsError('ID da sessão inválido'));
        return;
      }

      // Buscar sessão atual
      final commonSession = await _getSessionUseCase(sessionId);
      final uiSession = mapToUiSession(commonSession);

      // Atualizar status
      final updatedSession = uiSession.copyWith(
        status: SessionStatus.confirmed,
        presenceConfirmationTime: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Salvar no backend
      final commonUpdated = mapToDomainSession(updatedSession);
      final saved = await _updateSessionUseCase(sessionId, commonUpdated);
      final finalSession = mapToUiSession(saved);

      emit(SessionUpdated(finalSession));
    } catch (e) {
      emit(SessionsError('Erro ao confirmar sessão: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAsCompleted(MarkAsCompleted event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());

    try {
      final sessionId = int.tryParse(event.sessionId);
      if (sessionId == null) {
        emit(SessionsError('ID da sessão inválido'));
        return;
      }

      // Buscar sessão atual
      final commonSession = await _getSessionUseCase(sessionId);
      final uiSession = mapToUiSession(commonSession);

      // Atualizar status
      final updatedSession = uiSession.copyWith(status: SessionStatus.completed, updatedAt: DateTime.now());

      // Salvar no backend
      final commonUpdated = mapToDomainSession(updatedSession);
      final saved = await _updateSessionUseCase(sessionId, commonUpdated);
      final finalSession = mapToUiSession(saved);

      // Se a sessão tem appointmentId vinculado, atualizar agendamento para completed
      if (finalSession.appointmentId != null) {
        try {
          final appointmentId = int.tryParse(finalSession.appointmentId!);
          if (appointmentId != null) {
            final commonAppointment = await _getAppointmentUseCase(appointmentId);
            final updatedAppointment = commonAppointment.copyWith(
              status: 'completed',
              updatedAt: DateTime.now().toUtc(),
            );
            await _updateAppointmentUseCase(appointmentId, updatedAppointment);
          }
        } catch (e) {
          // Log erro mas continua - a sessão já foi atualizada
          // emit(SessionsError('Erro ao atualizar agendamento: ${e.toString()}'));
        }
      }

      emit(SessionUpdated(finalSession));
    } catch (e) {
      emit(SessionsError('Erro ao marcar sessão como realizada: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAsNoShow(MarkAsNoShow event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());

    try {
      final sessionId = int.tryParse(event.sessionId);
      if (sessionId == null) {
        emit(SessionsError('ID da sessão inválido'));
        return;
      }

      // Buscar sessão atual
      final commonSession = await _getSessionUseCase(sessionId);
      final uiSession = mapToUiSession(commonSession);

      // Atualizar status
      final updatedSession = uiSession.copyWith(status: SessionStatus.noShow, updatedAt: DateTime.now());

      // Salvar no backend
      final commonUpdated = mapToDomainSession(updatedSession);
      final saved = await _updateSessionUseCase(sessionId, commonUpdated);
      final finalSession = mapToUiSession(saved);

      emit(SessionUpdated(finalSession));
    } catch (e) {
      emit(SessionsError('Erro ao marcar falta: ${e.toString()}'));
    }
  }
}
