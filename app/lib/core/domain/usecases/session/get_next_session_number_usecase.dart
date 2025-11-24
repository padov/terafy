import 'package:terafy/core/domain/repositories/session_repository.dart';

class GetNextSessionNumberUseCase {
  const GetNextSessionNumberUseCase(this._repository);

  final SessionRepository _repository;

  Future<int> call(int patientId) {
    return _repository.getNextSessionNumber(patientId);
  }
}
