import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/schedule_repository.dart';

class CreateAppointmentUseCase {
  const CreateAppointmentUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Appointment> call(Appointment appointment) {
    return _repository.createAppointment(appointment);
  }
}
