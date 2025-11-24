import 'package:shelf/shelf.dart';
import 'package:server/core/services/jwt_service.dart';
import 'package:server/features/auth/token_blacklist.repository.dart';
import 'package:common/common.dart';

Middleware authMiddleware({TokenBlacklistRepository? blacklistRepository}) {
  return (Handler handler) {
    return (Request request) async {
      // Rotas públicas que não precisam de autenticação
      final publicRoutes = [
        '/ping',
        '/auth/login',
        '/auth/register',
        '/auth/refresh', // Refresh token é público (usa refresh token para autenticar)
      ];
      final path = request.url.path;

      // Normaliza o path: remove espaços, garante que comece com /
      final normalizedPath = path.trim().replaceAll('//', '/');
      final cleanPath = normalizedPath.startsWith('/')
          ? normalizedPath
          : '/$normalizedPath';

      AppLogger.debug(
        '[AUTH_MIDDLEWARE] Path: "$cleanPath" | Method: ${request.method}',
      );

      // Verifica se é uma rota pública
      final isPublicRoute = publicRoutes.any((route) {
        // Verifica correspondência exata
        if (cleanPath == route) {
          AppLogger.debug(
            '[AUTH_MIDDLEWARE] ✅ Rota pública encontrada (exata): $route',
          );
          return true;
        }

        // Verifica se começa com a rota seguida de / ou fim da string
        if (cleanPath.startsWith(route)) {
          final remaining = cleanPath.substring(route.length);
          final match = remaining.isEmpty || remaining.startsWith('/');
          if (match) {
            AppLogger.debug(
              '[AUTH_MIDDLEWARE] ✅ Rota pública encontrada (prefixo): $route',
            );
          }
          return match;
        }

        return false;
      });

      if (isPublicRoute) {
        return handler(request);
      }

      AppLogger.debug(
        '[AUTH_MIDDLEWARE] ❌ Rota protegida - verificando token...',
      );

      // Extrai o token do header Authorization
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(
          401,
          body: '{"error": "Token não fornecido"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = authHeader.substring(7); // Remove "Bearer "
      final claims = JwtService.validateToken(token);

      if (claims == null) {
        return Response(
          401,
          body: '{"error": "Token inválido ou expirado"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verifica se é access token (não refresh token)
      final tokenType = claims['type'] as String?;
      if (tokenType != 'access') {
        return Response(
          401,
          body: '{"error": "Token inválido. Use access token."}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verifica blacklist se repository fornecido
      if (blacklistRepository != null) {
        final jti = claims['jti'] as String?;
        if (jti != null) {
          final isBlacklisted = await blacklistRepository.isBlacklisted(jti);
          if (isBlacklisted) {
            return Response(
              401,
              body: '{"error": "Token revogado"}',
              headers: {'Content-Type': 'application/json'},
            );
          }
        }
      }

      // Adiciona informações do usuário autenticado ao request
      final updatedRequest = request.change(
        headers: {
          ...request.headers,
          'x-user-id': claims['sub'] as String,
          'x-user-role': claims['role'] as String,
          'x-account-type': claims['account_type'] as String? ?? '',
          'x-account-id': claims['account_id']?.toString() ?? '',
        },
      );

      return handler(updatedRequest);
    };
  };
}

// Função auxiliar para extrair informações do usuário do request
int? getUserId(Request request) {
  final userIdStr = request.headers['x-user-id'];
  return userIdStr != null ? int.tryParse(userIdStr) : null;
}

String? getUserRole(Request request) {
  return request.headers['x-user-role'];
}

String? getAccountType(Request request) {
  return request.headers['x-account-type'];
}

int? getAccountId(Request request) {
  final accountIdStr = request.headers['x-account-id'];
  return accountIdStr != null && accountIdStr.isNotEmpty
      ? int.tryParse(accountIdStr)
      : null;
}

// NOTA: requireRole e requireAnyRole foram movidos para authorization_middleware.dart
// para evitar duplicação e melhorar a organização do código.
// Use: import 'package:server/core/middleware/authorization_middleware.dart';

// Middleware para verificar se o usuário está autenticado (já verificado pelo authMiddleware, mas útil para rotas específicas)
Middleware requireAuth() {
  return (Handler handler) {
    return (Request request) async {
      final userId = getUserId(request);

      if (userId == null) {
        return Response(
          401,
          body: '{"error": "Autenticação necessária"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      return handler(request);
    };
  };
}
