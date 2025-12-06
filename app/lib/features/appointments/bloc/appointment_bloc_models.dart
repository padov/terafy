import 'package:equatable/equatable.dart';
import 'package:terafy/features/appointments/models/appointment.dart';

// ==================== EVENTS ====================

abstract class AppointmentEvent extends Equatable {
  const AppointmentEvent();

  @override
  List<Object?> get props => [];
}

/// Carregar agenda para um período
class LoadAppointments extends AppointmentEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadAppointments({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}

/// Criar novo agendamento
class CreateAppointment extends AppointmentEvent {
  final Appointment appointment;

  const CreateAppointment(this.appointment);

  @override
  List<Object> get props => [appointment];
}

/// Atualizar agendamento
class UpdateAppointment extends AppointmentEvent {
  final Appointment appointment;

  const UpdateAppointment(this.appointment);

  @override
  List<Object> get props => [appointment];
}

/// Cancelar agendamento
class CancelAppointment extends AppointmentEvent {
  final String appointmentId;
  final String? reason;

  const CancelAppointment({required this.appointmentId, this.reason});

  @override
  List<Object?> get props => [appointmentId, reason];
}

/// Confirmar agendamento
class ConfirmAppointment extends AppointmentEvent {
  final String appointmentId;

  const ConfirmAppointment(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

/// Registrar falta (no-show)
class MarkNoShow extends AppointmentEvent {
  final String appointmentId;

  const MarkNoShow(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

/// Carregar detalhes de um agendamento
class LoadAppointmentDetails extends AppointmentEvent {
  final String appointmentId;

  const LoadAppointmentDetails(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

/// Reemite a agenda atual armazenada em cache
class ResetAppointmentsView extends AppointmentEvent {
  const ResetAppointmentsView();
}

// ==================== STATES ====================

abstract class AppointmentState extends Equatable {
  const AppointmentState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AppointmentInitial extends AppointmentState {
  const AppointmentInitial();
}

/// Carregando agenda
class AppointmentLoading extends AppointmentState {
  const AppointmentLoading();
}

/// Agenda carregada com sucesso
class AppointmentLoaded extends AppointmentState {
  final List<Appointment> appointments;
  final DateTime startDate;
  final DateTime endDate;

  const AppointmentLoaded({required this.appointments, required this.startDate, required this.endDate});

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
      final date = DateTime(appointment.dateTime.year, appointment.dateTime.month, appointment.dateTime.day);
      countMap[date] = (countMap[date] ?? 0) + 1;
    }

    return countMap;
  }
}

/// Detalhes do agendamento carregado
class AppointmentDetailsLoaded extends AppointmentState {
  final Appointment appointment;

  const AppointmentDetailsLoaded(this.appointment);

  @override
  List<Object> get props => [appointment];
}

/// Agendamento criado com sucesso
class AppointmentCreated extends AppointmentState {
  final Appointment appointment;

  const AppointmentCreated(this.appointment);

  @override
  List<Object> get props => [appointment];
}

/// Agendamento atualizado com sucesso
class AppointmentUpdated extends AppointmentState {
  final Appointment appointment;

  const AppointmentUpdated(this.appointment);

  @override
  List<Object> get props => [appointment];
}

/// Agendamento cancelado com sucesso
class AppointmentCancelled extends AppointmentState {
  final String appointmentId;

  const AppointmentCancelled(this.appointmentId);

  @override
  List<Object> get props => [appointmentId];
}

/// Erro na agenda
class AppointmentError extends AppointmentState {
  final String message;

  const AppointmentError(this.message);

  @override
  List<Object> get props => [message];
}
