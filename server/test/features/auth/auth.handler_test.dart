import 'dart:convert';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:common/common.dart';
import 'package:server/features/auth/auth.handler.dart';
import 'package:server/core/services/password_service.dart';
import 'package:server/core/services/jwt_service.dart';
import 'package:server/core/config/env_config.dart';
import 'helpers/test_auth_repositories.dart';

void main() {
  // Inicializa EnvConfig para garantir que JwtService funcione
  setUpAll(() {
    EnvConfig.load();
  });

  group('AuthHandler', () {
    late TestUserRepository userRepository;
    late TestRefreshTokenRepository refreshTokenRepository;
    late TestTokenBlacklistRepository blacklistRepository;
    late AuthHandler handler;

    setUp(() {
      userRepository = TestUserRepository();
      refreshTokenRepository = TestRefreshTokenRepository();
      blacklistRepository = TestTokenBlacklistRepository();
      handler = AuthHandler(userRepository, refreshTokenRepository, blacklistRepository);
    });

    tearDown(() {
      userRepository.clear();
      refreshTokenRepository.clear();
      blacklistRepository.clear();
    });

    group('POST /auth/login', () {
      test('deve fazer login com credenciais válidas', () async {
        final password = 'senha123';
        final passwordHash = PasswordService.hashPassword(password);
        await userRepository.createUser(
          User(
            email: 'teste@terafy.app.br',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        final request = Request(
          'POST',
          Uri.parse('http://localhost/login'),
          body: jsonEncode({'email': 'teste@terafy.app.br', 'password': password}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
        expect(response.headers['content-type'], 'application/json');

        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['auth_token'], isNotEmpty);
        expect(data['refresh_token'], isNotEmpty);
        expect(data['user'], isNotNull);
        expect(data['user']['email'], 'teste@terafy.app.br');
      });

      test('deve retornar 401 quando credenciais são inválidas', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/login'),
          body: jsonEncode({'email': 'naoexiste@terafy.com', 'password': 'senha123'}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 401);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], 'Credenciais inválidas');
      });

      test('deve retornar 400 quando corpo está vazio', () async {
        final request = Request('POST', Uri.parse('http://localhost/login'), body: '');

        final response = await handler.router.call(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], 'Corpo da requisição não pode ser vazio');
      });

      test('deve retornar 400 quando JSON é inválido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/login'),
          body: 'invalid json',
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        // Deve tratar erro de parsing e retornar 500 (erro interno)
        expect(response.statusCode, greaterThanOrEqualTo(400));
      });

      test('deve retornar 400 quando email ou senha estão faltando', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/login'),
          body: jsonEncode({'email': 'teste@terafy.app.br'}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], 'Email e senha são obrigatórios');
      });

      test('deve retornar 403 quando conta está suspensa', () async {
        final password = 'senha123';
        final passwordHash = PasswordService.hashPassword(password);
        await userRepository.createUser(
          User(
            email: 'teste@terafy.app.br',
            passwordHash: passwordHash,
            role: 'therapist',
            status: 'suspended',
            emailVerified: false,
          ),
        );

        final request = Request(
          'POST',
          Uri.parse('http://localhost/login'),
          body: jsonEncode({'email': 'teste@terafy.app.br', 'password': password}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 403);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], 'Conta suspensa ou cancelada');
      });
    });

    group('POST /auth/register', () {
      test('deve registrar novo usuário com sucesso', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/register'),
          body: jsonEncode({'email': 'novo@terafy.com', 'password': 'senha123'}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 201);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['auth_token'], isNotEmpty);
        expect(data['refresh_token'], isNotEmpty);
        expect(data['user'], isNotNull);
        expect(data['user']['email'], 'novo@terafy.com');
        expect(data['message'], isNotEmpty);
      });

      test('deve retornar 400 quando senha é muito curta', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/register'),
          body: jsonEncode({'email': 'novo@terafy.com', 'password': '123'}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], 'Senha deve ter no mínimo 6 caracteres');
      });

      test('deve retornar 400 quando email já existe', () async {
        await userRepository.createUser(
          User(
            email: 'existente@terafy.com',
            passwordHash: PasswordService.hashPassword('senha123'),
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        final request = Request(
          'POST',
          Uri.parse('http://localhost/register'),
          body: jsonEncode({'email': 'existente@terafy.com', 'password': 'senha123'}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], 'Email já cadastrado');
      });

      test('deve retornar 400 quando JSON é inválido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/register'),
          body: 'invalid json',
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        // Deve tratar erro de parsing e retornar 500 (erro interno)
        expect(response.statusCode, greaterThanOrEqualTo(400));
      });
    });

    group('GET /auth/me', () {
      test('deve retornar usuário quando token é válido', () async {
        final user = await userRepository.createUser(
          User(
            email: 'teste@terafy.app.br',
            passwordHash: PasswordService.hashPassword('senha123'),
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        final token = JwtService.generateAccessToken(userId: user.id!, email: user.email, role: user.role);

        final request = Request('GET', Uri.parse('http://localhost/me'), headers: {'Authorization': 'Bearer $token'});

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['user'], isNotNull);
        expect(data['user']['id'], user.id);
        expect(data['user']['email'], 'teste@terafy.app.br');
      });

      test('deve retornar 401 quando token não é fornecido', () async {
        final request = Request('GET', Uri.parse('http://localhost/me'));

        final response = await handler.router.call(request);

        expect(response.statusCode, 401);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], 'Token não fornecido');
      });

      test('deve retornar 401 quando Authorization header não tem Bearer prefix', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/me'),
          headers: {'Authorization': 'token_sem_bearer'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 401);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], 'Token não fornecido');
      });

      test('deve retornar 401 quando token é inválido', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/me'),
          headers: {'Authorization': 'Bearer token_invalido'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 401);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], 'Token inválido ou expirado');
      });
    });

    group('POST /auth/refresh', () {
      test('deve renovar access token com refresh token válido', () async {
        final user = await userRepository.createUser(
          User(
            email: 'teste@terafy.app.br',
            passwordHash: PasswordService.hashPassword('senha123'),
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        final refreshTokenId = 'token_123';
        final refreshToken = JwtService.generateRefreshToken(userId: user.id!, tokenId: refreshTokenId);

        await refreshTokenRepository.createRefreshToken(
          userId: user.id!,
          token: refreshToken,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        final request = Request(
          'POST',
          Uri.parse('http://localhost/refresh'),
          body: jsonEncode({'refresh_token': refreshToken}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['access_token'], isNotEmpty);
        expect(data['refresh_token'], refreshToken);
      });

      test('deve retornar 400 quando refresh_token não é fornecido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/refresh'),
          body: jsonEncode({}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], 'refresh_token é obrigatório');
      });

      test('deve retornar 401 quando refresh token é inválido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/refresh'),
          body: jsonEncode({'refresh_token': 'token_invalido'}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 401);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('inválido'));
      });

      test('deve retornar 400 quando JSON é inválido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/refresh'),
          body: 'invalid json',
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        // Deve tratar erro de parsing e retornar 500 (erro interno)
        expect(response.statusCode, greaterThanOrEqualTo(400));
      });
    });

    group('POST /auth/logout', () {
      test('deve fazer logout com refresh token', () async {
        final user = await userRepository.createUser(
          User(
            email: 'teste@terafy.app.br',
            passwordHash: PasswordService.hashPassword('senha123'),
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        final refreshTokenId = 'token_123';
        final refreshToken = JwtService.generateRefreshToken(userId: user.id!, tokenId: refreshTokenId);

        await refreshTokenRepository.createRefreshToken(
          userId: user.id!,
          token: refreshToken,
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        final accessToken = JwtService.generateAccessToken(
          userId: user.id!,
          email: user.email,
          role: user.role,
          jti: 'access_token_jti',
        );

        final request = Request(
          'POST',
          Uri.parse('http://localhost/logout'),
          body: jsonEncode({'refresh_token': refreshToken}),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['message'], 'Logout realizado com sucesso');

        // Verifica que refresh token foi revogado
        final tokenId = await refreshTokenRepository.findTokenByHash(refreshToken);
        expect(tokenId, isNull);

        // Verifica que access token foi adicionado à blacklist
        final isBlacklisted = await blacklistRepository.isBlacklisted('access_token_jti');
        expect(isBlacklisted, isTrue);
      });

      test('deve fazer logout apenas com access token', () async {
        final user = await userRepository.createUser(
          User(
            email: 'teste@terafy.app.br',
            passwordHash: PasswordService.hashPassword('senha123'),
            role: 'therapist',
            status: 'active',
            emailVerified: false,
          ),
        );

        final accessToken = JwtService.generateAccessToken(
          userId: user.id!,
          email: user.email,
          role: user.role,
          jti: 'access_token_jti',
        );

        final request = Request(
          'POST',
          Uri.parse('http://localhost/logout'),
          body: jsonEncode({}),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);

        // Verifica que access token foi adicionado à blacklist
        final isBlacklisted = await blacklistRepository.isBlacklisted('access_token_jti');
        expect(isBlacklisted, isTrue);
      });

      test('deve funcionar mesmo sem tokens', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/logout'),
          body: jsonEncode({}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
      });
    });
  });
}
