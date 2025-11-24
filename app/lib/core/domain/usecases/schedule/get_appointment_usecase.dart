import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/schedule_repository.dart';

class GetAppointmentUseCase {
  const GetAppointmentUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Appointment> call(int appointmentId) {
    return _repository.fetchAppointment(appointmentId);
  }
}
