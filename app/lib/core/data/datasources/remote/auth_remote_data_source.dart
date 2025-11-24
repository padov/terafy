import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:terafy/core/data/models/auth_result_model.dart';
import 'package:common/common.dart';
import 'package:terafy/core/services/secure_storage_service.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResultModel> login(String email, String password);
  Future<AuthResultModel> register(String email, String password);
  Future<AuthResultModel> signInWithGoogle();
  Future<AuthResultModel> getCurrentUser();
  Future<AuthResultModel> refreshToken(String refreshToken);
  Future<void> logout({String? refreshToken, String? accessToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final SecureStorageService secureStorageService;

  AuthRemoteDataSourceImpl({
    required this.dio,
    required this.secureStorageService,
  });

  @override
  Future<AuthResultModel> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      log(response.data.toString(), name: 'AuthAPI Response');

      if (response.statusCode == 200 && response.data != null) {
        return AuthResultModel.fromJson(response.data);
      } else {
        throw Exception('Falha na comunicação com o servidor.');
      }
    } on DioException catch (e) {
      // Tratar erros específicos do Dio (rede, timeout, etc.)
      String errorMessage = 'Erro ao fazer login';

      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 401) {
          errorMessage = responseData?['error'] ?? 'Credenciais inválidas';
        } else if (statusCode == 400) {
          errorMessage = responseData?['error'] ?? 'Dados inválidos';
        } else if (statusCode == 403) {
          errorMessage =
              responseData?['error'] ?? 'Conta suspensa ou cancelada';
        } else {
          errorMessage = responseData?['error'] ?? 'Erro ao fazer login';
        }
      } else {
        errorMessage = e.message ?? 'Erro de conexão';
      }

      log(errorMessage, name: 'AuthAPI DioException');
      throw Exception(errorMessage);
    } catch (e) {
      // Outros erros
      log('Generic Exception: ${e.toString()}', name: 'AuthAPI Error');
      rethrow;
    }
  }

  @override
  Future<AuthResultModel> register(String email, String password) async {
    AppLogger.func();
    try {
      final response = await dio.post(
        '/auth/register',
        data: {'email': email, 'password': password},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      log(response.data.toString(), name: 'RegisterAPI Response');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return AuthResultModel.fromJson(response.data);
      } else {
        throw Exception('Falha ao registrar usuário.');
      }
    } on DioException catch (e) {
      String errorMessage = 'Erro ao registrar usuário';

      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 400) {
          errorMessage = responseData?['error'] ?? 'Dados inválidos';
        } else if (statusCode == 409) {
          errorMessage = responseData?['error'] ?? 'Email já cadastrado';
        } else {
          errorMessage = responseData?['error'] ?? 'Erro ao registrar usuário';
        }
      } else {
        errorMessage = e.message ?? 'Erro de conexão';
      }

      log(errorMessage, name: 'RegisterAPI DioException');
      throw Exception(errorMessage);
    } catch (e) {
      log('Generic Exception: ${e.toString()}', name: 'RegisterAPI Error');
      rethrow;
    }
  }

  @override
  Future<AuthResultModel> signInWithGoogle() async {
    try {
      log('Iniciando login com Google...', name: 'GoogleSignIn');

      // 1. Iniciar o fluxo de login do Google, especificando o ID do cliente web
      //    Isso é crucial para obter um idToken que possa ser validado no backend.
      final String serverClientId =
          '1056350914736-9quf6vj6g6s7pls4t67q9ivm987a0s6q.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: serverClientId,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // O usuário cancelou o fluxo de login
        log('Usuário cancelou o login com Google.', name: 'GoogleSignIn');
        throw Exception('Login com Google cancelado pelo usuário.');
      }

      // 2. Obter as credenciais de autenticação, incluindo o idToken
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        log(
          'Não foi possível obter o idToken do Google.',
          name: 'GoogleSignIn',
        );
        throw Exception('Falha ao obter o token de autenticação do Google.');
      }

      log('Login com Google bem-sucedido!', name: 'GoogleSignIn');
      log('ID Token: ${idToken.substring(0, 30)}...', name: 'GoogleSignIn');

      // 3. TODO: Enviar o idToken para a API GraphQL
      // Por enquanto, vamos simular uma falha, pois o backend não está pronto.
      // Quando o backend tiver o novo mutation, substituiremos esta parte.
      throw UnimplementedError(
        'A API GraphQL ainda não suporta login com idToken do Google.',
      );

      // Exemplo de como seria a chamada para a API no futuro:
      /*
      final response = await dio.post(
        flavorConfig.baseUrl,
        data: {
          'query': 'mutation AuthWithGoogle(\$token: String!) { ... }',
          'variables': {'token': idToken},
        },
      );
      return AuthResultModel.fromJson(response.data['data']['authWithGoogle']);
      */
    } catch (e) {
      log('Erro durante o login com Google: $e', name: 'GoogleSignIn');
      rethrow;
    }
  }

  @override
  Future<AuthResultModel> getCurrentUser() async {
    try {
      // Obtém o token do storage para adicionar ao header
      final token = await secureStorageService.getToken();

      if (token == null) {
        throw Exception('Token não encontrado');
      }

      final response = await dio.get(
        '/auth/me',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      log(response.data.toString(), name: 'GetCurrentUser Response');

      if (response.statusCode == 200 && response.data != null) {
        // O endpoint /auth/me retorna {'user': {...}}
        final userData = response.data['user'] as Map<String, dynamic>;

        // Retorna AuthResultModel com token e dados do usuário
        return AuthResultModel.fromJson({
          'auth_token': token,
          'user': userData,
        });
      } else {
        throw Exception('Falha ao obter dados do usuário.');
      }
    } on DioException catch (e) {
      String errorMessage = 'Erro ao validar token';

      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 401) {
          errorMessage = responseData?['error'] ?? 'Token inválido ou expirado';
        } else {
          errorMessage = responseData?['error'] ?? 'Erro ao validar token';
        }
      } else {
        errorMessage = e.message ?? 'Erro de conexão';
      }

      log(errorMessage, name: 'GetCurrentUser DioException');
      throw Exception(errorMessage);
    } catch (e) {
      log('Generic Exception: ${e.toString()}', name: 'GetCurrentUser Error');
      rethrow;
    }
  }

  @override
  Future<AuthResultModel> refreshToken(String refreshToken) async {
    AppLogger.func();
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      log(response.data.toString(), name: 'RefreshTokenAPI Response');

      if (response.statusCode == 200 && response.data != null) {
        // Backend retorna: { "access_token": "...", "refresh_token": "..." }
        // Precisamos adaptar para o formato esperado pelo AuthResultModel
        return AuthResultModel.fromJson({
          'auth_token': response.data['access_token'],
          'refresh_token': response.data['refresh_token'],
        });
      } else {
        throw Exception('Falha ao renovar token');
      }
    } on DioException catch (e) {
      String errorMessage = 'Erro ao renovar token';

      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 401) {
          errorMessage =
              responseData?['error'] ?? 'Refresh token inválido ou expirado';
        } else if (statusCode == 400) {
          errorMessage = responseData?['error'] ?? 'Dados inválidos';
        } else {
          errorMessage = responseData?['error'] ?? 'Erro ao renovar token';
        }
      } else {
        errorMessage = e.message ?? 'Erro de conexão';
      }

      log(errorMessage, name: 'RefreshTokenAPI DioException');
      throw Exception(errorMessage);
    } catch (e) {
      log('Generic Exception: ${e.toString()}', name: 'RefreshTokenAPI Error');
      rethrow;
    }
  }

  @override
  Future<void> logout({String? refreshToken, String? accessToken}) async {
    AppLogger.func();
    try {
      // Prepara headers com access token se disponível
      final headers = <String, dynamic>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      // Prepara body com refresh token se disponível
      final data = <String, dynamic>{};
      if (refreshToken != null) {
        data['refresh_token'] = refreshToken;
      }

      final response = await dio.post(
        '/auth/logout',
        data: data.isEmpty ? null : data,
        options: Options(headers: headers),
      );

      log(response.data.toString(), name: 'LogoutAPI Response');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Falha ao realizar logout no servidor');
      }
    } on DioException catch (e) {
      String errorMessage = 'Erro ao realizar logout';

      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        if (statusCode == 401) {
          // Token inválido, mas ainda assim tentamos fazer logout local
          errorMessage =
              responseData?['error'] ??
              'Token inválido, mas logout local realizado';
        } else {
          errorMessage = responseData?['error'] ?? 'Erro ao realizar logout';
        }
      } else {
        errorMessage = e.message ?? 'Erro de conexão';
      }

      log(errorMessage, name: 'LogoutAPI DioException');
      // Não relança exceção - logout local deve sempre acontecer
      // mesmo se o logout no servidor falhar
    } catch (e) {
      log('Generic Exception: ${e.toString()}', name: 'LogoutAPI Error');
      // Não relança exceção - logout local deve sempre acontecer
    }
  }
}
