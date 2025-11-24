import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/session_repository.dart';

class UpdateSessionUseCase {
  const UpdateSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<Session> call(int sessionId, Session session) {
    return _repository.updateSession(sessionId, session);
  }
}
