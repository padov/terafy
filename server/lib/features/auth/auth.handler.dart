import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:common/common.dart';
import 'package:server/features/user/user.repository.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/services/jwt_service.dart';
import 'auth.controller.dart';
import 'auth.routes.dart';
import 'refresh_token.repository.dart';
import 'token_blacklist.repository.dart';

class AuthHandler extends BaseHandler {
  final UserRepository _userRepository;
  final RefreshTokenRepository _refreshTokenRepository;
  final TokenBlacklistRepository _blacklistRepository;
  late final AuthController _controller;

  AuthHandler(this._userRepository, this._refreshTokenRepository, this._blacklistRepository) {
    _controller = AuthController(_userRepository, _refreshTokenRepository);
  }

  @override
  Router get router => configureAuthRoutes(this);

  /// Handler para rota POST /auth/login
  Future<Response> handleLogin(Request request) async {
    AppLogger.func();
    try {
      final body = await request.readAsString();
      if (body.isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final loginData = jsonDecode(body) as Map<String, dynamic>;
      final email = loginData['email'] as String?;
      final password = loginData['password'] as String?;

      if (email == null || password == null) {
        return badRequestResponse('Email e senha são obrigatórios');
      }

      final result = await _controller.login(email, password);

      return successResponse({
        'auth_token': result.authToken,
        'refresh_token': result.refreshToken,
        'user': result.user.toJson(),
      });
    } on AuthException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao realizar login: ${e.toString()}');
    }
  }

  /// Handler para rota POST /auth/register
  Future<Response> handleRegister(Request request) async {
    AppLogger.func();
    try {
      final body = await request.readAsString();
      if (body.isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final registerData = jsonDecode(body) as Map<String, dynamic>;
      final email = registerData['email'] as String?;
      final password = registerData['password'] as String?;

      if (email == null || password == null) {
        return badRequestResponse('Email e senha são obrigatórios');
      }

      final result = await _controller.register(email, password);

      return createdResponse({
        'auth_token': result.authToken,
        'refresh_token': result.refreshToken,
        'user': result.user.toJson(),
        'message': result.message,
      });
    } on AuthException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao registrar usuário: ${e.toString()}');
    }
  }

  /// Handler para rota GET /auth/me
  Future<Response> handleGetCurrentUser(Request request) async {
    AppLogger.func();
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return unauthorizedResponse('Token não fornecido');
      }

      final token = authHeader.substring(7); // Remove "Bearer "
      final user = await _controller.getCurrentUser(token);

      return successResponse({'user': user.toJson()});
    } on AuthException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao buscar usuário: ${e.toString()}');
    }
  }

  /// Handler para rota POST /auth/refresh
  /// Renova o access token usando um refresh token válido
  Future<Response> handleRefreshToken(Request request) async {
    AppLogger.func();
    try {
      final body = await request.readAsString();
      if (body.isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final refreshData = jsonDecode(body) as Map<String, dynamic>;
      final refreshToken = refreshData['refresh_token'] as String?;

      if (refreshToken == null) {
        return badRequestResponse('refresh_token é obrigatório');
      }

      final tokens = await _controller.refreshAccessToken(refreshToken);

      return successResponse({'access_token': tokens['access_token'], 'refresh_token': tokens['refresh_token']});
    } on AuthException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao renovar token: ${e.toString()}');
    }
  }

  /// Handler para rota POST /auth/logout
  /// Revoga refresh token e adiciona access token à blacklist
  Future<Response> handleLogout(Request request) async {
    AppLogger.func();
    try {
      final body = await request.readAsString();
      final refreshData = body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic>? : null;

      final refreshToken = refreshData?['refresh_token'] as String?;
      final accessToken = request.headers['authorization']?.replaceFirst('Bearer ', '');

      if (refreshToken != null) {
        await _controller.revokeRefreshToken(
          refreshToken,
          accessToken: accessToken,
          blacklistRepository: _blacklistRepository,
        );
      } else if (accessToken != null) {
        // Se não tem refresh token, apenas adiciona access token à blacklist
        final claims = JwtService.validateToken(accessToken);
        if (claims != null) {
          final jti = claims['jti'] as String?;
          final userId = int.tryParse(claims['sub'] as String? ?? '');
          final exp = claims['exp'] as int?;

          if (jti != null && userId != null && exp != null) {
            final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            await _blacklistRepository.addToBlacklist(
              tokenId: jti,
              userId: userId,
              expiresAt: expiresAt,
              reason: 'logout',
            );
          }
        }
      }

      return successResponse({'message': 'Logout realizado com sucesso'});
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Erro ao realizar logout: ${e.toString()}');
    }
  }
}
