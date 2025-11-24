import 'package:common/common.dart';

abstract class ScheduleRepository {
  Future<TherapistScheduleSettings> fetchSettings({int? therapistId});

  Future<TherapistScheduleSettings> updateSettings(
    TherapistScheduleSettings settings,
  );

  Future<List<Appointment>> fetchAppointments({
    required DateTime start,
    required DateTime end,
    int? therapistId,
  });

  Future<Appointment> fetchAppointment(int appointmentId);

  Future<Appointment> createAppointment(Appointment appointment);

  Future<Appointment> updateAppointment(
    int appointmentId,
    Appointment appointment,
  );

  Future<void> deleteAppointment(int appointmentId);
}
