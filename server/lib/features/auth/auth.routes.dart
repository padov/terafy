import 'package:shelf_router/shelf_router.dart';
import 'auth.handler.dart';

/// Configura as rotas de autenticação
Router configureAuthRoutes(AuthHandler handler) {
  final router = Router();

  // POST /auth/login - Autenticação de usuário
  router.post('/login', handler.handleLogin);

  // POST /auth/register - Registro de novo terapeuta
  router.post('/register', handler.handleRegister);

  // GET /auth/me - Retorna informações do usuário autenticado (requer token)
  router.get('/me', handler.handleGetCurrentUser);

  // POST /auth/refresh - Renova access token usando refresh token
  router.post('/refresh', handler.handleRefreshToken);

  // POST /auth/logout - Revoga refresh token e adiciona access token à blacklist
  router.post('/logout', handler.handleLogout);

  return router;
}
