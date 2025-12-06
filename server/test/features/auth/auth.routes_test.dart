import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/features/auth/auth.handler.dart';
import 'package:server/features/auth/auth.routes.dart';
import 'helpers/test_auth_repositories.dart';

void main() {
  group('Auth Routes', () {
    late AuthHandler handler;
    late Router router;

    setUp(() {
      final userRepository = TestUserRepository();
      final refreshTokenRepository = TestRefreshTokenRepository();
      final blacklistRepository = TestTokenBlacklistRepository();
      handler = AuthHandler(userRepository, refreshTokenRepository, blacklistRepository);
      router = configureAuthRoutes(handler);
    });

    group('Rotas de Autenticação', () {
      test('POST /auth/login está configurada', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/login'),
          headers: {'Content-Type': 'application/json'},
          body: '{"email": "teste@terafy.app.br", "password": "senha123"}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Rota deve estar configurada (handler chamado)
        // Pode retornar 401 (credenciais inválidas) ou 200 (sucesso)
        expect(
          body.contains('error') || body.contains('auth_token') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('POST /auth/register está configurada', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/register'),
          headers: {'Content-Type': 'application/json'},
          body: '{"email": "novo@terafy.com", "password": "senha123"}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Rota deve estar configurada (handler chamado)
        expect(
          body.contains('error') || body.contains('auth_token') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('GET /auth/me está configurada', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/me'),
          headers: {'Authorization': 'Bearer token_invalido'},
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Rota deve estar configurada (handler chamado)
        // Pode retornar 401 (token inválido) mas não 404 (rota não existe)
        expect(
          body.contains('error') || body.contains('Token') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('POST /auth/refresh está configurada', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: '{"refresh_token": "token_invalido"}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Rota deve estar configurada (handler chamado)
        expect(
          body.contains('error') || body.contains('inválido') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('POST /auth/logout está configurada', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/logout'),
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Rota deve estar configurada (handler chamado)
        // Logout sempre retorna 200 mesmo sem tokens
        expect(
          body.contains('message') || body.contains('sucesso') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('Rota inválida retorna 404', () async {
        final request = Request('GET', Uri.parse('http://localhost/rota_inexistente'));

        final response = await router(request);

        // Rota não existe, deve retornar 404
        expect(response.statusCode, 404);
      });
    });

    group('Validação de padrões de rota', () {
      test('Rotas com padrões corretos são reconhecidas', () async {
        final validRoutes = ['POST /login', 'POST /register', 'GET /me', 'POST /refresh', 'POST /logout'];

        for (final route in validRoutes) {
          final parts = route.split(' ');
          final method = parts[0];
          final path = parts[1];

          final request = Request(
            method,
            Uri.parse('http://localhost$path'),
            headers: {'Content-Type': 'application/json'},
            body: method == 'GET' ? '' : '{}',
          );

          final response = await router(request);
          final body = await response.readAsString();

          // Rota deve ser reconhecida (handler foi chamado)
          expect(
            body.contains('error') ||
                body.contains('auth_token') ||
                body.contains('message') ||
                body.contains('Token') ||
                response.statusCode != 404,
            isTrue,
            reason: 'Rota $route deve ser reconhecida (handler chamado)',
          );
        }
      });
    });
  });
}
