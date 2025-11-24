import 'package:terafy/core/domain/entities/auth_result.dart';

abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register(String email, String password);
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> getCurrentUser();
  Future<AuthResult> refreshToken(String refreshToken);
  Future<void> logout({String? refreshToken, String? accessToken});
}
