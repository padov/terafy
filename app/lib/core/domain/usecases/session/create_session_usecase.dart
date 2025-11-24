import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/session_repository.dart';

class CreateSessionUseCase {
  const CreateSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<Session> call(Session session) {
    return _repository.createSession(session);
  }
}
