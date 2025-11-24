import 'package:equatable/equatable.dart';
import 'package:terafy/features/agenda/models/appointment.dart';

// ==================== EVENTS ====================

abstract class AgendaEvent extends Equatable {
  const AgendaEvent();

  @override
  List<Object?> get props => [];
}

/// Carregar agenda para um período
class LoadAgenda extends AgendaEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadAgenda({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}

/// Criar novo agendamento
class CreateAppointment extends AgendaEvent {
  final Appointment appointment;

  const CreateAppointment(this.appointment);

  @override
  List<Object> get props => [appointment];
}

/// Atualizar agendamento
class UpdateAppointment extends AgendaEvent {
  final Appointment appointment;

  const UpdateAppointment(this.appointment);

  @override
  List<Object> get props => [appointment];
}

/// Cancelar agendamento
class CancelAppointment extends AgendaEvent {
  final String appointmentId;
  final String? reason;

  const CancelAppointment({required this.appointmentId, this.reason});

  @override
  List<Object?> get props => [appointmentId, reason];
}

/// Confirmar agendamento
class ConfirmAppointment extends AgendaEvent {
  final String appointmentId;

  const ConfirmAppointment(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

/// Registrar falta (no-show)
class MarkNoShow extends AgendaEvent {
  final String appointmentId;

  const MarkNoShow(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

/// Carregar detalhes de um agendamento
class LoadAppointmentDetails extends AgendaEvent {
  final String appointmentId;

  const LoadAppointmentDetails(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

/// Reemite a agenda atual armazenada em cache
class ResetAgendaView extends AgendaEvent {
  const ResetAgendaView();
}

// ==================== STATES ====================

abstract class AgendaState extends Equatable {
  const AgendaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AgendaInitial extends AgendaState {
  const AgendaInitial();
}

/// Carregando agenda
class AgendaLoading extends AgendaState {
  const AgendaLoading();
}

/// Agenda carregada com sucesso
class AgendaLoaded extends AgendaState {
  final List<Appointment> appointments;
  final DateTime startDate;
  final DateTime endDate;

  const AgendaLoaded({
    required this.appointments,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [appointments, startDate, endDate];

  /// Obter agendamentos de um dia específico
  List<Appointment> getAppointmentsForDay(DateTime date) {
    return appointments.where((appointment) {
      return appointment.dateTime.year == date.year &&
          appointment.dateTime.month == date.month &&
          appointment.dateTime.day == date.day;
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Obter agendamentos por status
  List<Appointment> getAppointmentsByStatus(AppointmentStatus status) {
    return appointments.where((appointment) {
      return appointment.status == status;
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Contar agendamentos por dia
  Map<DateTime, int> getAppointmentCountByDay() {
    final Map<DateTime, int> countMap = {};

    for (final appointment in appointments) {
      final date = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );
      countMap[date] = (countMap[date] ?? 0) + 1;
    }

    return countMap;
  }
}

/// Detalhes do agendamento carregado
class AppointmentDetailsLoaded extends AgendaState {
  final Appointment appointment;

  const AppointmentDetailsLoaded(this.appointment);

  @override
  List<Object> get props => [appointment];
}

/// Agendamento criado com sucesso
class AppointmentCreated extends AgendaState {
  final Appointment appointment;

  const AppointmentCreated(this.appointment);

  @override
  List<Object> get props => [appointment];
}

/// Agendamento atualizado com sucesso
class AppointmentUpdated extends AgendaState {
  final Appointment appointment;

  const AppointmentUpdated(this.appointment);

  @override
  List<Object> get props => [appointment];
}

/// Agendamento cancelado com sucesso
class AppointmentCancelled extends AgendaState {
  final String appointmentId;

  const AppointmentCancelled(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

/// Erro na agenda
class AgendaError extends AgendaState {
  final String message;

  const AgendaError(this.message);

  @override
  List<Object> get props => [message];
}
