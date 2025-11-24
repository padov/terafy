import 'package:terafy/core/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> call({String? refreshToken, String? accessToken}) {
    return repository.logout(
      refreshToken: refreshToken,
      accessToken: accessToken,
    );
  }
}
