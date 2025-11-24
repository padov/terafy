import 'package:terafy/core/domain/entities/auth_result.dart';
import 'package:terafy/core/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<AuthResult> call() {
    return repository.getCurrentUser();
  }
}
