import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import '../../helpers/integration_test_db.dart';
import '../../helpers/test_server_setup.dart';
import '../../helpers/http_test_helpers.dart';

void main() {
  group('Auth API Integration Tests', () {
    late Handler handler;
    late TestDBConnection dbConnection;

    setUpAll(() async {
      await TestServerSetup.setup();
    });

    setUp(() async {
      await IntegrationTestDB.cleanDatabase();
      dbConnection = TestDBConnection();
      handler = TestServerSetup.createTestHandler(dbConnection);
    });

    tearDown(() async {
      await IntegrationTestDB.cleanDatabase();
    });

    group('POST /auth/register', () {
      test('deve criar usuário e retornar tokens', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': 'novo@terafy.com', 'password': 'senha123'},
        );

        final response = await handler(request);

        expect(response.statusCode, 201); // Created
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['user'], isNotNull);
        expect(data['user']['email'], 'novo@terafy.com');
        expect(data['auth_token'], isNotNull);
        expect(data['auth_token'], isNotEmpty);
        expect(data['refresh_token'], isNotNull);
        expect(data['refresh_token'], isNotEmpty);
        expect(data['message'], isNotNull);
        expect(data['message'], isNotEmpty);
      });

      test('deve validar constraint de email único (retorna erro)', () async {
        // Cria primeiro usuário
        final request1 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': 'duplicado@terafy.com', 'password': 'senha123'},
        );
        await handler(request1);

        // Tenta criar duplicado
        final request2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': 'duplicado@terafy.com', 'password': 'senha123'},
        );

        final response = await handler(request2);
        expect(response.statusCode, greaterThanOrEqualTo(400));
      });

      test('deve validar dados obrigatórios', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {
            'email': 'teste@terafy.app.br',
            // password faltando
          },
        );

        final response = await handler(request);
        expect(response.statusCode, 400);
      });
    });

    group('POST /auth/login', () {
      test('deve fazer login e retornar tokens', () async {
        // Cria usuário primeiro
        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': 'login@terafy.com', 'password': 'senha123'},
        );
        await handler(registerRequest);

        // Faz login
        final loginRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/login',
          body: {'email': 'login@terafy.com', 'password': 'senha123'},
        );

        final response = await handler(loginRequest);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['user'], isNotNull);
        expect(data['auth_token'], isNotEmpty);
        expect(data['refresh_token'], isNotEmpty);
      });

      test('deve retornar 401 com credenciais inválidas', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/login',
          body: {'email': 'inexistente@terafy.com', 'password': 'senha123'},
        );

        final response = await handler(request);
        expect(response.statusCode, 401);
      });
    });

    group('POST /auth/refresh', () {
      test('deve renovar access token usando refresh token', () async {
        // Cria usuário e faz login
        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': 'refresh@terafy.com', 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final refreshToken = registerData['refresh_token'] as String;

        // Renova token
        final refreshRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/refresh',
          body: {'refresh_token': refreshToken},
        );

        final response = await handler(refreshRequest);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['access_token'], isNotEmpty);
        expect(data['refresh_token'], refreshToken);
      });

      test('deve retornar 401 com refresh token inválido', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/refresh',
          body: {'refresh_token': 'token_invalido'},
        );

        final response = await handler(request);
        expect(response.statusCode, 401);
      });
    });

    group('GET /auth/me', () {
      test('deve retornar usuário autenticado', () async {
        // Cria usuário e faz login
        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': 'me@terafy.com', 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final accessToken = registerData['auth_token'] as String;

        // Busca dados do usuário
        final meRequest = HttpTestHelpers.createRequest(method: 'GET', path: '/auth/me', token: accessToken);

        final response = await handler(meRequest);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['user'], isNotNull);
        expect(data['user']['email'], 'me@terafy.com');
      });

      test('deve retornar 401 sem token', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/auth/me');

        final response = await handler(request);
        expect(response.statusCode, 401);
      });
    });

    group('POST /auth/logout', () {
      test('deve revogar tokens', () async {
        // Cria usuário e faz login
        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': 'logout@terafy.com', 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final accessToken = registerData['auth_token'] as String;
        final refreshToken = registerData['refresh_token'] as String;

        // Faz logout
        final logoutRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/logout',
          body: {'refresh_token': refreshToken},
          token: accessToken,
        );

        final response = await handler(logoutRequest);
        expect(response.statusCode, 200);

        // Tenta usar token revogado (deve falhar)
        final meRequest = HttpTestHelpers.createRequest(method: 'GET', path: '/auth/me', token: accessToken);

        final meResponse = await handler(meRequest);
        expect(meResponse.statusCode, 401);
      });
    });
  });
}
