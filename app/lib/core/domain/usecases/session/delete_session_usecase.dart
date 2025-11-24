import 'package:terafy/core/domain/repositories/session_repository.dart';

class DeleteSessionUseCase {
  const DeleteSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<void> call(int sessionId) {
    return _repository.deleteSession(sessionId);
  }
}
