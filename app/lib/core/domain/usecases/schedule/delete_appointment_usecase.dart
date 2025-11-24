import 'package:terafy/core/domain/repositories/schedule_repository.dart';

class DeleteAppointmentUseCase {
  const DeleteAppointmentUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<void> call(int appointmentId) {
    return _repository.deleteAppointment(appointmentId);
  }
}
