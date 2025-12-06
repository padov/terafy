import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:mocktail/mocktail.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/core/services/jwt_service.dart';
import 'package:server/features/auth/token_blacklist.repository.dart';

class MockTokenBlacklistRepository extends Mock implements TokenBlacklistRepository {}

void main() {
  group('Auth Middleware', () {
    late Handler handler;
    late MockTokenBlacklistRepository mockBlacklistRepository;

    setUp(() {
      mockBlacklistRepository = MockTokenBlacklistRepository();

      // Handler simples que retorna 200 OK e ecoa os headers injetados
      final innerHandler = (Request request) => Response.ok(
        'ok',
        headers: {'x-user-id': request.headers['x-user-id'] ?? '', 'x-user-role': request.headers['x-user-role'] ?? ''},
      );

      handler = authMiddleware(blacklistRepository: mockBlacklistRepository)(innerHandler);
    });

    group('Public Routes', () {
      test('deve permitir acesso a /ping sem token', () async {
        final request = Request('GET', Uri.parse('http://localhost/ping'));
        final response = await handler(request);
        expect(response.statusCode, equals(200));
      });

      test('deve permitir acesso a /auth/login sem token', () async {
        final request = Request('POST', Uri.parse('http://localhost/auth/login'));
        final response = await handler(request);
        expect(response.statusCode, equals(200));
      });

      test('deve permitir acesso a /auth/register sem token', () async {
        final request = Request('POST', Uri.parse('http://localhost/auth/register'));
        final response = await handler(request);
        expect(response.statusCode, equals(200));
      });

      test('deve normalizar paths (remover //)', () async {
        final request = Request('GET', Uri.parse('http://localhost//ping'));
        final response = await handler(request);
        expect(response.statusCode, equals(200));
      });
    });

    group('Token Validation', () {
      test('deve retornar 401 se header Authorization ausente', () async {
        final request = Request('GET', Uri.parse('http://localhost/protected'));
        final response = await handler(request);
        expect(response.statusCode, equals(401));
        expect(await response.readAsString(), contains('Token não fornecido'));
      });

      test('deve retornar 401 se header não começar com Bearer', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/protected'),
          headers: {'Authorization': 'Basic 123456'},
        );
        final response = await handler(request);
        expect(response.statusCode, equals(401));
      });

      test('deve retornar 401 se token for inválido', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/protected'),
          headers: {'Authorization': 'Bearer invalid_token'},
        );
        final response = await handler(request);
        expect(response.statusCode, equals(401));
        expect(await response.readAsString(), contains('Token inválido'));
      });

      test('deve retornar 401 se token não for do tipo access', () async {
        // Gera um refresh token
        final token = JwtService.generateRefreshToken(userId: 1, tokenId: 'uuid');

        final request = Request(
          'GET',
          Uri.parse('http://localhost/protected'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final response = await handler(request);
        expect(response.statusCode, equals(401));
        expect(await response.readAsString(), contains('Use access token'));
      });
    });

    group('Blacklist', () {
      test('deve retornar 401 se token estiver na blacklist', () async {
        final token = JwtService.generateAccessToken(
          userId: 1,
          email: 'test@example.com',
          role: 'user',
          jti: 'blocked_jti',
        );

        when(() => mockBlacklistRepository.isBlacklisted('blocked_jti')).thenAnswer((_) async => true);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/protected'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final response = await handler(request);
        expect(response.statusCode, equals(401));
        expect(await response.readAsString(), contains('Token revogado'));
      });

      test('deve permitir se token não estiver na blacklist', () async {
        final token = JwtService.generateAccessToken(
          userId: 1,
          email: 'test@example.com',
          role: 'user',
          jti: 'valid_jti',
        );

        when(() => mockBlacklistRepository.isBlacklisted('valid_jti')).thenAnswer((_) async => false);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/protected'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final response = await handler(request);
        expect(response.statusCode, equals(200));
      });
    });

    group('Request Enrichment', () {
      test('deve adicionar headers com informações do usuário', () async {
        final token = JwtService.generateAccessToken(
          userId: 123,
          email: 'test@example.com',
          role: 'admin',
          accountType: 'therapist',
          accountId: 456,
        );

        final request = Request(
          'GET',
          Uri.parse('http://localhost/protected'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(response.headers['x-user-id'], equals('123'));
        expect(response.headers['x-user-role'], equals('admin'));
      });
    });

    group('Helpers', () {
      test('getUserId deve extrair ID do header', () {
        final request = Request('GET', Uri.parse('http://localhost/'), headers: {'x-user-id': '123'});
        expect(getUserId(request), equals(123));
      });

      test('getUserRole deve extrair role do header', () {
        final request = Request('GET', Uri.parse('http://localhost/'), headers: {'x-user-role': 'admin'});
        expect(getUserRole(request), equals('admin'));
      });
    });

    group('requireAuth Middleware', () {
      test('deve bloquear se x-user-id não estiver presente', () async {
        final middleware = requireAuth();
        final handler = middleware((request) => Response.ok('ok'));

        final request = Request('GET', Uri.parse('http://localhost/'));
        final response = await handler(request);

        expect(response.statusCode, equals(401));
      });

      test('deve permitir se x-user-id estiver presente', () async {
        final middleware = requireAuth();
        final handler = middleware((request) => Response.ok('ok'));

        final request = Request('GET', Uri.parse('http://localhost/'), headers: {'x-user-id': '123'});
        final response = await handler(request);

        expect(response.statusCode, equals(200));
      });
    });
  });
}
