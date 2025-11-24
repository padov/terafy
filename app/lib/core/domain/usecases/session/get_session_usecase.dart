import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/session_repository.dart';

class GetSessionUseCase {
  const GetSessionUseCase(this._repository);

  final SessionRepository _repository;

  Future<Session> call(int sessionId) {
    return _repository.fetchSession(sessionId);
  }
}
