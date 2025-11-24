import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/schedule_repository.dart';

class GetAppointmentsUseCase {
  const GetAppointmentsUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<List<Appointment>> call({
    required DateTime start,
    required DateTime end,
    int? therapistId,
  }) {
    return _repository.fetchAppointments(
      start: start,
      end: end,
      therapistId: therapistId,
    );
  }
}
