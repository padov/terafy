import 'package:terafy/core/domain/entities/auth_result.dart';
import 'package:terafy/core/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthResult> call(String email, String password) {
    return repository.login(email, password);
  }
}
