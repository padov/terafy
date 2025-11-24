import 'package:common/common.dart' as common;
import 'package:terafy/features/agenda/models/appointment.dart' as ui;

ui.Appointment mapToUiAppointment(common.Appointment appointment) {
  final duration = appointment.endTime.difference(appointment.startTime);
  final recurrenceRule = appointment.recurrenceRule != null
      ? Map<String, dynamic>.from(appointment.recurrenceRule!)
      : null;

  ui.RecurrenceType recurrence = ui.RecurrenceType.none;
  if (recurrenceRule != null) {
    final ruleType = recurrenceRule['type']?.toString();
    switch (ruleType) {
      case 'daily':
        recurrence = ui.RecurrenceType.daily;
        break;
      case 'weekly':
        recurrence = ui.RecurrenceType.weekly;
        break;
      default:
        recurrence = ui.RecurrenceType.none;
    }
  }

  return ui.Appointment(
    id: appointment.id?.toString() ?? '',
    therapistId: appointment.therapistId.toString(),
    patientId: appointment.patientId?.toString(),
    patientName: appointment.patientName,
    dateTime: appointment.startTime.toLocal(),
    duration: duration,
    type: _mapTypeFromString(appointment.type),
    status: _mapStatusFromString(appointment.status),
    recurrence: recurrence,
    recurrenceEndDate: appointment.recurrenceEnd?.toLocal(),
    recurrenceExceptions: appointment.recurrenceExceptions
        ?.map((e) => e.toLocal())
        .toList(),
    recurrenceRule: recurrenceRule,
    color: appointment.color,
    reminders: const [],
    reminderSentAt: appointment.reminderSentAt?.toLocal(),
    confirmedAt: appointment.patientConfirmedAt?.toLocal(),
    notes: appointment.notes,
    parentAppointmentId: appointment.parentAppointmentId?.toString(),
    room: appointment.location,
    onlineLink: appointment.onlineLink,
    arrivedAt: appointment.patientArrivalAt?.toLocal(),
    sessionId: appointment.sessionId?.toString(),
    createdAt: appointment.createdAt?.toLocal() ?? DateTime.now(),
    updatedAt: appointment.updatedAt?.toLocal() ?? DateTime.now(),
  );
}

common.Appointment mapToDomainAppointment(ui.Appointment appointment) {
  final startTime = appointment.dateTime.toUtc();
  final endTime = appointment.endTime.toUtc();

  return common.Appointment(
    id: int.tryParse(appointment.id),
    therapistId: int.tryParse(appointment.therapistId) ?? 0,
    patientId: appointment.patientId != null
        ? int.tryParse(appointment.patientId!)
        : null,
    patientName: appointment.patientName,
    type: _mapTypeToString(appointment.type),
    status: _mapStatusToString(appointment.status),
    title: null,
    description: appointment.notes,
    startTime: startTime,
    endTime: endTime,
    recurrenceRule: appointment.recurrenceRule,
    recurrenceEnd: appointment.recurrenceEndDate?.toUtc(),
    recurrenceExceptions: appointment.recurrenceExceptions
        ?.map((e) => e.toUtc())
        .toList(),
    location: appointment.room,
    onlineLink: appointment.onlineLink,
    color: appointment.color,
    reminders: const [],
    reminderSentAt: appointment.reminderSentAt?.toUtc(),
    patientConfirmedAt: appointment.confirmedAt?.toUtc(),
    patientArrivalAt: appointment.arrivedAt?.toUtc(),
    waitingRoomStatus: null,
    cancellationReason: appointment.status == ui.AppointmentStatus.cancelled
        ? appointment.notes
        : null,
    notes: appointment.notes,
    parentAppointmentId: appointment.parentAppointmentId != null
        ? int.tryParse(appointment.parentAppointmentId!)
        : null,
    sessionId: appointment.sessionId != null
        ? int.tryParse(appointment.sessionId!)
        : null,
    createdAt: appointment.createdAt.toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );
}

ui.AppointmentType _mapTypeFromString(String type) {
  switch (type) {
    case 'personal':
      return ui.AppointmentType.personal;
    case 'block':
      return ui.AppointmentType.block;
    case 'session':
      return ui.AppointmentType.session;
  }
  return ui.AppointmentType.session;
}

String _mapTypeToString(ui.AppointmentType type) {
  switch (type) {
    case ui.AppointmentType.personal:
      return 'personal';
    case ui.AppointmentType.block:
      return 'block';
    case ui.AppointmentType.session:
      return 'session';
  }
}

ui.AppointmentStatus _mapStatusFromString(String status) {
  switch (status) {
    case 'reserved':
      return ui.AppointmentStatus.reserved;
    case 'confirmed':
      return ui.AppointmentStatus.confirmed;
    case 'completed':
      return ui.AppointmentStatus.completed;
    case 'cancelled':
      return ui.AppointmentStatus.cancelled;
    case 'no_show':
      return ui.AppointmentStatus.noShow;
    default:
      return ui.AppointmentStatus.reserved;
  }
}

String _mapStatusToString(ui.AppointmentStatus status) {
  switch (status) {
    case ui.AppointmentStatus.reserved:
      return 'reserved';
    case ui.AppointmentStatus.confirmed:
      return 'confirmed';
    case ui.AppointmentStatus.completed:
      return 'completed';
    case ui.AppointmentStatus.cancelled:
      return 'cancelled';
    case ui.AppointmentStatus.noShow:
      return 'cancelled';
  }
}
