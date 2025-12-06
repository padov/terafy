import 'package:terafy/core/domain/repositories/schedule_repository.dart';

class ValidateAppointmentsUseCase {
  final ScheduleRepository repository;

  ValidateAppointmentsUseCase(this.repository);

  Future<List<Map<String, DateTime>>> call({required List<Map<String, DateTime>> slots, int? therapistId}) async {
    return await repository.validateAppointments(slots: slots, therapistId: therapistId);
  }
}
