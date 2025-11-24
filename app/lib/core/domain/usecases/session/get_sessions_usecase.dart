import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/session_repository.dart';

class GetSessionsUseCase {
  const GetSessionsUseCase(this._repository);

  final SessionRepository _repository;

  Future<List<Session>> call({
    int? patientId,
    int? therapistId,
    int? appointmentId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.fetchSessions(
      patientId: patientId,
      therapistId: therapistId,
      appointmentId: appointmentId,
      status: status,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
