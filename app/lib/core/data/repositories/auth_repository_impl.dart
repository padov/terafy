import 'package:terafy/core/data/datasources/remote/auth_remote_data_source.dart';
import 'package:terafy/core/domain/entities/auth_result.dart';
import 'package:terafy/core/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final authResultModel = await remoteDataSource.login(email, password);
      // Como AuthResultModel é um subtipo de AuthResult, podemos retornar diretamente.
      return authResultModel;
    } catch (e) {
      // O tratamento de erros pode ser refinado aqui, se necessário.
      rethrow;
    }
  }

  @override
  Future<AuthResult> register(String email, String password) async {
    try {
      final authResultModel = await remoteDataSource.register(email, password);
      return authResultModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final authResultModel = await remoteDataSource.signInWithGoogle();
      return authResultModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResult> getCurrentUser() async {
    try {
      final authResultModel = await remoteDataSource.getCurrentUser();
      return authResultModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResult> refreshToken(String refreshToken) async {
    try {
      final authResultModel = await remoteDataSource.refreshToken(refreshToken);
      return authResultModel;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout({String? refreshToken, String? accessToken}) async {
    try {
      await remoteDataSource.logout(
        refreshToken: refreshToken,
        accessToken: accessToken,
      );
    } catch (e) {
      // Não relança exceção - logout local deve sempre acontecer
      // mesmo se o logout no servidor falhar
    }
  }
}
