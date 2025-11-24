import 'package:terafy/core/domain/entities/auth_result.dart';
import 'package:terafy/core/domain/repositories/auth_repository.dart';

class RegisterUserUseCase {
  final AuthRepository repository;

  RegisterUserUseCase(this.repository);

  Future<AuthResult> call(String email, String password) {
    return repository.register(email, password);
  }
}
