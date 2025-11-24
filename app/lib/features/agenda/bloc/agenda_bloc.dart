import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:common/common.dart' hide Appointment;
import 'package:terafy/core/domain/usecases/schedule/create_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/get_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/get_appointments_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/update_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/session/create_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_next_session_number_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/update_session_usecase.dart';
import 'package:terafy/features/agenda/bloc/agenda_bloc_models.dart';
import 'package:terafy/features/agenda/models/appointment.dart';
import 'package:terafy/features/agenda/models/appointment_mapper.dart';

class AgendaBloc extends Bloc<AgendaEvent, AgendaState> {
  AgendaBloc({
    required GetAppointmentsUseCase getAppointmentsUseCase,
    required GetAppointmentUseCase getAppointmentUseCase,
    required CreateAppointmentUseCase createAppointmentUseCase,
    required UpdateAppointmentUseCase updateAppointmentUseCase,
    required CreateSessionUseCase createSessionUseCase,
    required GetNextSessionNumberUseCase getNextSessionNumberUseCase,
    required GetSessionUseCase getSessionUseCase,
    required UpdateSessionUseCase updateSessionUseCase,
  }) : _getAppointmentsUseCase = getAppointmentsUseCase,
       _getAppointmentUseCase = getAppointmentUseCase,
       _createAppointmentUseCase = createAppointmentUseCase,
       _updateAppointmentUseCase = updateAppointmentUseCase,
       _createSessionUseCase = createSessionUseCase,
       _getNextSessionNumberUseCase = getNextSessionNumberUseCase,
       _getSessionUseCase = getSessionUseCase,
       _updateSessionUseCase = updateSessionUseCase,
       super(const AgendaInitial()) {
    on<LoadAgenda>(_onLoadAgenda);
    on<CreateAppointment>(_onCreateAppointment);
    on<UpdateAppointment>(_onUpdateAppointment);
    on<CancelAppointment>(_onCancelAppointment);
    on<ConfirmAppointment>(_onConfirmAppointment);
    on<MarkNoShow>(_onMarkNoShow);
    on<LoadAppointmentDetails>(_onLoadAppointmentDetails);
    on<ResetAgendaView>(_onResetAgendaView);
  }

  final GetAppointmentsUseCase _getAppointmentsUseCase;
  final GetAppointmentUseCase _getAppointmentUseCase;
  final CreateAppointmentUseCase _createAppointmentUseCase;
  final UpdateAppointmentUseCase _updateAppointmentUseCase;
  final CreateSessionUseCase _createSessionUseCase;
  final GetNextSessionNumberUseCase _getNextSessionNumberUseCase;
  final GetSessionUseCase _getSessionUseCase;
  final UpdateSessionUseCase _updateSessionUseCase;

  List<Appointment> _currentAppointments = <Appointment>[];
  DateTime? _currentStart;
  DateTime? _currentEnd;

  Future<void> _onLoadAgenda(
    LoadAgenda event,
    Emitter<AgendaState> emit,
  ) async {
    emit(const AgendaLoading());

    try {
      _currentStart = event.startDate;
      _currentEnd = event.endDate;

      final appointments = await _getAppointmentsUseCase(
        start: event.startDate,
        end: event.endDate,
      );

      _currentAppointments = appointments.map(mapToUiAppointment).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      emit(
        AgendaLoaded(
          appointments: _currentAppointments,
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      );
    } catch (e) {
      emit(AgendaError(_buildErrorMessage('carregar agenda', e)));
    }
  }

  Future<void> _onCreateAppointment(
    CreateAppointment event,
    Emitter<AgendaState> emit,
  ) async {
    try {
      final commonAppointment = mapToDomainAppointment(event.appointment);

      final created = await _createAppointmentUseCase(commonAppointment);
      final createdUi = mapToUiAppointment(created);

      _currentAppointments = [..._currentAppointments, createdUi]
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      emit(AppointmentCreated(createdUi));
      _reloadCurrentPeriod();
    } catch (e) {
      emit(AgendaError(_buildErrorMessage('criar agendamento', e)));
    }
  }

  Future<void> _onUpdateAppointment(
    UpdateAppointment event,
    Emitter<AgendaState> emit,
  ) async {
    await _persistUpdate(
      emit,
      updatedAppointment: event.appointment,
      onSuccess: (updated) => emit(AppointmentUpdated(updated)),
      errorAction: 'atualizar agendamento',
    );
  }

  Future<void> _onCancelAppointment(
    CancelAppointment event,
    Emitter<AgendaState> emit,
  ) async {
    final appointment = _findAppointment(event.appointmentId);
    if (appointment == null) {
      emit(const AgendaError('Agendamento não encontrado'));
      return;
    }

    // Se o agendamento tem sessão vinculada, cancelar a sessão também
    if (appointment.sessionId != null) {
      try {
        final sessionId = int.tryParse(appointment.sessionId!);
        if (sessionId != null) {
          final commonSession = await _getSessionUseCase(sessionId);
          final updatedSession = commonSession.copyWith(
            status: 'cancelledByTherapist',
            cancellationReason: event.reason ?? 'Agendamento cancelado',
            cancellationTime: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          await _updateSessionUseCase(sessionId, updatedSession);
        }
      } catch (e) {
        // Log erro mas continua cancelando o agendamento
        // emit(AgendaError('Erro ao cancelar sessão: ${e.toString()}'));
      }
    }

    final updated = appointment.copyWith(
      status: AppointmentStatus.cancelled,
      notes: event.reason?.isNotEmpty == true
          ? '${appointment.notes ?? ''}\nMotivo: ${event.reason}'
          : appointment.notes,
      updatedAt: DateTime.now(),
    );

    await _persistUpdate(
      emit,
      updatedAppointment: updated,
      onSuccess: (_) => emit(AppointmentCancelled(event.appointmentId)),
      errorAction: 'cancelar agendamento',
    );
  }

  Future<void> _onConfirmAppointment(
    ConfirmAppointment event,
    Emitter<AgendaState> emit,
  ) async {
    final appointment = _findAppointment(event.appointmentId);
    if (appointment == null) {
      emit(const AgendaError('Agendamento não encontrado'));
      return;
    }

    String? sessionId;

    // Se é agendamento de sessão e tem paciente, criar sessão automaticamente
    if (appointment.type == AppointmentType.session &&
        appointment.patientId != null) {
      try {
        final patientId = int.tryParse(appointment.patientId!);
        if (patientId == null) {
          emit(const AgendaError('ID do paciente inválido'));
          return;
        }

        // Calcular próximo número de sessão
        final sessionNumber = await _getNextSessionNumberUseCase(patientId);

        // Criar sessão baseada no agendamento
        final session = Session(
          patientId: patientId,
          therapistId: int.tryParse(appointment.therapistId) ?? 0,
          appointmentId: int.tryParse(appointment.id),
          scheduledStartTime: appointment.dateTime.toUtc(),
          scheduledEndTime: appointment.endTime.toUtc(),
          durationMinutes: appointment.duration.inMinutes,
          sessionNumber: sessionNumber,
          type: 'presential', // Default, pode ser ajustado depois
          modality: 'individual', // Default
          location: appointment.room,
          onlineRoomLink: appointment.onlineLink,
          status: 'confirmed', // Sessão criada quando agendamento é confirmado
          paymentStatus: 'pending', // Default
        );

        final createdSession = await _createSessionUseCase(session);
        sessionId = createdSession.id?.toString();
      } catch (e) {
        emit(AgendaError('Erro ao criar sessão: ${e.toString()}'));
        return;
      }
    }

    final updated = appointment.copyWith(
      status: AppointmentStatus.confirmed,
      confirmedAt: DateTime.now(),
      sessionId: sessionId,
      updatedAt: DateTime.now(),
    );

    await _persistUpdate(
      emit,
      updatedAppointment: updated,
      errorAction: 'confirmar agendamento',
    );
  }

  Future<void> _onMarkNoShow(
    MarkNoShow event,
    Emitter<AgendaState> emit,
  ) async {
    final appointment = _findAppointment(event.appointmentId);
    if (appointment == null) {
      emit(const AgendaError('Agendamento não encontrado'));
      return;
    }

    final updated = appointment.copyWith(
      status: AppointmentStatus.noShow,
      updatedAt: DateTime.now(),
    );

    await _persistUpdate(
      emit,
      updatedAppointment: updated,
      errorAction: 'registrar falta',
    );
  }

  Future<void> _onLoadAppointmentDetails(
    LoadAppointmentDetails event,
    Emitter<AgendaState> emit,
  ) async {
    // Primeiro tenta encontrar na lista local
    var appointment = _findAppointment(event.appointmentId);

    // Se não encontrar, busca do backend
    if (appointment == null) {
      try {
        final appointmentId = int.tryParse(event.appointmentId);
        if (appointmentId == null) {
          emit(const AgendaError('ID de agendamento inválido'));
          return;
        }

        final commonAppointment = await _getAppointmentUseCase(appointmentId);
        appointment = mapToUiAppointment(commonAppointment);

        // Adiciona à lista local para futuras referências
        _currentAppointments = [..._currentAppointments, appointment]
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      } catch (e) {
        emit(
          AgendaError(
            _buildErrorMessage('carregar detalhes do agendamento', e),
          ),
        );
        return;
      }
    }

    emit(AppointmentDetailsLoaded(appointment));
  }

  void _onResetAgendaView(ResetAgendaView event, Emitter<AgendaState> emit) {
    if (_currentStart != null && _currentEnd != null) {
      emit(
        AgendaLoaded(
          appointments: _currentAppointments,
          startDate: _currentStart!,
          endDate: _currentEnd!,
        ),
      );
    } else if (_currentAppointments.isNotEmpty) {
      final start = _currentAppointments.first.dateTime;
      final end = _currentAppointments.last.endTime;
      emit(
        AgendaLoaded(
          appointments: _currentAppointments,
          startDate: start,
          endDate: end,
        ),
      );
    } else {
      emit(const AgendaInitial());
    }
  }

  Appointment? _findAppointment(String id) {
    try {
      return _currentAppointments.firstWhere((apt) => apt.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistUpdate(
    Emitter<AgendaState> emit, {
    required Appointment updatedAppointment,
    required String errorAction,
    void Function(Appointment updated)? onSuccess,
  }) async {
    try {
      final commonAppointment = mapToDomainAppointment(updatedAppointment);
      final appointmentId = commonAppointment.id;

      if (appointmentId == null) {
        emit(const AgendaError('Agendamento inválido'));
        return;
      }

      final saved = await _updateAppointmentUseCase(
        appointmentId,
        commonAppointment,
      );

      final savedUi = mapToUiAppointment(saved);

      _currentAppointments =
          _currentAppointments
              .map((apt) => apt.id == savedUi.id ? savedUi : apt)
              .toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (onSuccess != null) {
        onSuccess(savedUi);
      } else {
        emit(AppointmentUpdated(savedUi));
      }

      _reloadCurrentPeriod();
    } catch (e) {
      emit(AgendaError(_buildErrorMessage(errorAction, e)));
    }
  }

  void _reloadCurrentPeriod() {
    if (_currentStart != null && _currentEnd != null) {
      add(LoadAgenda(startDate: _currentStart!, endDate: _currentEnd!));
    }
  }

  String _buildErrorMessage(String action, Object error) {
    final base = 'Erro ao $action';
    final description = error.toString();
    if (description.isEmpty || description == 'Exception') {
      return base;
    }
    return '$base: $description';
  }
}
