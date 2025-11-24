import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/schedule_repository.dart';

class UpdateAppointmentUseCase {
  const UpdateAppointmentUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Appointment> call(int appointmentId, Appointment appointment) {
    return _repository.updateAppointment(appointmentId, appointment);
  }
}
