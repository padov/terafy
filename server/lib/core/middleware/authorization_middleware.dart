import 'package:shelf/shelf.dart';
import 'package:common/common.dart';
import 'auth_middleware.dart';

/// Middleware para verificar se o usuário tem acesso a um recurso específico
///
/// Este middleware garante que:
/// - Admins podem acessar qualquer recurso
/// - Usuários só podem acessar seus próprios recursos (baseado em accountId)
///
/// [resourceIdExtractor] - Função para extrair o ID do recurso da requisição
/// [allowedRoles] - Roles que podem acessar (se null, todas as roles autenticadas)
/// [adminBypass] - Se true, admins podem acessar qualquer recurso (padrão: true)
///
/// Exemplo:
/// ```dart
/// router.get('/therapists/<id>',
///   requireResourceAccess(
///     resourceIdExtractor: (req, id) => int.tryParse(id),
///     allowedRoles: ['therapist', 'admin'],
///   ).call((request, id) async {
///     // Handler só será executado se o usuário tiver acesso
///   })
/// );
/// ```
Middleware requireResourceAccess({
  required int? Function(Request request, String resourceId)
  resourceIdExtractor,
  List<String>? allowedRoles,
  bool adminBypass = true,
}) {
  return (Handler handler) {
    return (Request request) async {
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);
      final userId = getUserId(request);

      // Verifica autenticação
      if (userRole == null || userId == null) {
        return Response(
          401,
          body: '{"error": "Autenticação necessária"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verifica se a role é permitida
      if (allowedRoles != null && !allowedRoles.contains(userRole)) {
        AppLogger.debug(
          '[AUTHORIZATION] Role $userRole não permitida. Roles permitidas: ${allowedRoles.join(", ")}',
        );
        return Response(
          403,
          body:
              '{"error": "Acesso negado. Roles permitidas: ${allowedRoles.join(", ")}"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Admin pode acessar qualquer recurso (bypass)
      if (adminBypass && userRole == 'admin') {
        AppLogger.debug('[AUTHORIZATION] Admin bypass - acesso permitido');
        return handler(request);
      }

      // Extrai o ID do recurso da URL
      final pathSegments = request.url.pathSegments;
      if (pathSegments.isEmpty) {
        return Response(
          400,
          body: '{"error": "ID do recurso não encontrado na URL"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Pega o último segmento da URL como ID do recurso
      final resourceIdStr = pathSegments.last;
      final resourceId = resourceIdExtractor(request, resourceIdStr);

      if (resourceId == null) {
        return Response(
          400,
          body: '{"error": "ID do recurso inválido"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verifica se o usuário tem acesso ao recurso
      // Usuário só pode acessar recursos vinculados ao seu accountId
      if (accountId != null && accountId == resourceId) {
        AppLogger.debug(
          '[AUTHORIZATION] Acesso permitido - usuário acessando próprio recurso (accountId: $accountId)',
        );
        return handler(request);
      }

      // Se não tem accountId ou não corresponde, nega acesso
      AppLogger.warning(
        '[AUTHORIZATION] Acesso negado - usuário (accountId: $accountId) tentando acessar recurso (id: $resourceId)',
      );
      return Response(
        403,
        body:
            '{"error": "Acesso negado. Você só pode acessar seus próprios recursos."}',
        headers: {'Content-Type': 'application/json'},
      );
    };
  };
}

/// Verifica se o usuário tem acesso a um recurso específico
///
/// Esta função pode ser chamada dentro dos handlers para verificar acesso.
/// Retorna null se tiver acesso, ou uma Response de erro se não tiver.
///
/// [resourceId] - ID do recurso sendo acessado
/// [request] - Request do Shelf
/// [allowedRoles] - Roles que podem acessar (se null, todas as roles autenticadas)
/// [adminBypass] - Se true, admins podem acessar qualquer recurso (padrão: true)
///
/// Exemplo:
/// ```dart
/// router.get('/therapists/<id>', (request, id) async {
///   final accessError = checkResourceAccess(
///     request: request,
///     resourceId: int.tryParse(id),
///     allowedRoles: ['therapist', 'admin'],
///   );
///   if (accessError != null) return accessError;
///   // ... resto do handler
/// });
/// ```
Response? checkResourceAccess({
  required Request request,
  required int? resourceId,
  List<String>? allowedRoles,
  bool adminBypass = true,
}) {
  final userRole = getUserRole(request);
  final accountId = getAccountId(request);
  final userId = getUserId(request);

  // Verifica autenticação
  if (userRole == null || userId == null) {
    return Response(
      401,
      body: '{"error": "Autenticação necessária"}',
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Verifica se a role é permitida
  if (allowedRoles != null && !allowedRoles.contains(userRole)) {
    AppLogger.debug(
      '[AUTHORIZATION] Role $userRole não permitida. Roles permitidas: ${allowedRoles.join(", ")}',
    );
    return Response(
      403,
      body:
          '{"error": "Acesso negado. Roles permitidas: ${allowedRoles.join(", ")}"}',
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Verifica ID do recurso
  if (resourceId == null) {
    return Response(
      400,
      body: '{"error": "ID do recurso inválido"}',
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Admin pode acessar qualquer recurso (bypass)
  if (adminBypass && userRole == 'admin') {
    AppLogger.debug('[AUTHORIZATION] Admin bypass - acesso permitido');
    return null; // Acesso permitido
  }

  // Verifica se o usuário tem acesso ao recurso
  // Usuário só pode acessar recursos vinculados ao seu accountId
  if (accountId != null && accountId == resourceId) {
    AppLogger.debug(
      '[AUTHORIZATION] Acesso permitido - usuário acessando próprio recurso (accountId: $accountId)',
    );
    return null; // Acesso permitido
  }

  // Se não tem accountId ou não corresponde, nega acesso
  AppLogger.warning(
    '[AUTHORIZATION] Acesso negado - usuário (accountId: $accountId) tentando acessar recurso (id: $resourceId)',
  );
  return Response(
    403,
    body:
        '{"error": "Acesso negado. Você só pode acessar seus próprios recursos."}',
    headers: {'Content-Type': 'application/json'},
  );
}

/// Middleware para verificar se o usuário tem uma role específica
///
/// Versão melhorada que usa BaseHandler para respostas padronizadas.
///
/// [requiredRole] - Role obrigatória para acesso
///
/// Exemplo:
/// ```dart
/// router.get('/admin-only',
///   requireRole('admin').call((request) async { ... })
/// );
/// ```
Middleware requireRole(String requiredRole) {
  AppLogger.func();
  AppLogger.debug('Required role: $requiredRole');
  return (Handler handler) {
    return (Request request) async {
      final userRole = getUserRole(request);

      if (userRole == null) {
        return Response(
          401,
          body: '{"error": "Autenticação necessária"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (userRole != requiredRole) {
        AppLogger.debug(
          '[AUTHORIZATION] Role $userRole não corresponde à role requerida: $requiredRole',
        );
        return Response(
          403,
          body: '{"error": "Acesso negado. Role requerida: $requiredRole"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      AppLogger.debug(
        '[AUTHORIZATION] Role $requiredRole verificada - acesso permitido',
      );
      return handler(request);
    };
  };
}

/// Middleware para verificar se o usuário tem uma das roles permitidas
///
/// Versão melhorada que usa BaseHandler para respostas padronizadas.
///
/// [allowedRoles] - Lista de roles permitidas
///
/// Exemplo:
/// ```dart
/// router.get('/therapist-or-admin',
///   requireAnyRole(['therapist', 'admin']).call((request) async { ... })
/// );
/// ```
Middleware requireAnyRole(List<String> allowedRoles) {
  return (Handler handler) {
    return (Request request) async {
      final userRole = getUserRole(request);

      if (userRole == null) {
        return Response(
          401,
          body: '{"error": "Autenticação necessária"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!allowedRoles.contains(userRole)) {
        AppLogger.debug(
          '[AUTHORIZATION] Role $userRole não está na lista de roles permitidas: ${allowedRoles.join(", ")}',
        );
        return Response(
          403,
          body:
              '{"error": "Acesso negado. Roles permitidas: ${allowedRoles.join(", ")}"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      AppLogger.debug(
        '[AUTHORIZATION] Role $userRole verificada - acesso permitido',
      );
      return handler(request);
    };
  };
}
