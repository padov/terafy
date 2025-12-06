import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:server/core/middleware/authorization_middleware.dart';

void main() {
  group('Authorization Middleware', () {
    final simpleHandler = (Request request) => Response.ok('ok');

    group('requireRole', () {
      test('deve retornar 401 se não autenticado', () async {
        final handler = requireRole('admin')(simpleHandler);
        final request = Request('GET', Uri.parse('http://localhost/'));
        final response = await handler(request);
        expect(response.statusCode, equals(401));
      });

      test('deve retornar 403 se role incorreta', () async {
        final handler = requireRole('admin')(simpleHandler);
        final request = Request('GET', Uri.parse('http://localhost/'), headers: {'x-user-role': 'user'});
        final response = await handler(request);
        expect(response.statusCode, equals(403));
      });

      test('deve permitir se role correta', () async {
        final handler = requireRole('admin')(simpleHandler);
        final request = Request('GET', Uri.parse('http://localhost/'), headers: {'x-user-role': 'admin'});
        final response = await handler(request);
        expect(response.statusCode, equals(200));
      });
    });

    group('requireAnyRole', () {
      test('deve retornar 401 se não autenticado', () async {
        final handler = requireAnyRole(['admin', 'therapist'])(simpleHandler);
        final request = Request('GET', Uri.parse('http://localhost/'));
        final response = await handler(request);
        expect(response.statusCode, equals(401));
      });

      test('deve retornar 403 se role não permitida', () async {
        final handler = requireAnyRole(['admin', 'therapist'])(simpleHandler);
        final request = Request('GET', Uri.parse('http://localhost/'), headers: {'x-user-role': 'patient'});
        final response = await handler(request);
        expect(response.statusCode, equals(403));
      });

      test('deve permitir se role permitida', () async {
        final handler = requireAnyRole(['admin', 'therapist'])(simpleHandler);
        final request = Request('GET', Uri.parse('http://localhost/'), headers: {'x-user-role': 'therapist'});
        final response = await handler(request);
        expect(response.statusCode, equals(200));
      });
    });

    group('requireResourceAccess', () {
      final resourceHandler = requireResourceAccess(resourceIdExtractor: (req, id) => int.tryParse(id))(simpleHandler);

      test('deve retornar 401 se não autenticado', () async {
        final request = Request('GET', Uri.parse('http://localhost/users/1'));
        final response = await resourceHandler(request);
        expect(response.statusCode, equals(401));
      });

      test('deve permitir admin acessar qualquer recurso (bypass)', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/users/1'),
          headers: {'x-user-id': '999', 'x-user-role': 'admin', 'x-account-id': '999'},
        );
        final response = await resourceHandler(request);
        expect(response.statusCode, equals(200));
      });

      test('deve permitir usuário acessar seu próprio recurso', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/users/123'),
          headers: {'x-user-id': '1', 'x-user-role': 'user', 'x-account-id': '123'},
        );
        final response = await resourceHandler(request);
        expect(response.statusCode, equals(200));
      });

      test('deve negar acesso a recurso de outro usuário', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/users/456'),
          headers: {'x-user-id': '1', 'x-user-role': 'user', 'x-account-id': '123'},
        );
        final response = await resourceHandler(request);
        expect(response.statusCode, equals(403));
      });

      test('deve retornar 400 se ID do recurso inválido', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/users/abc'),
          headers: {'x-user-id': '1', 'x-user-role': 'user', 'x-account-id': '123'},
        );
        final response = await resourceHandler(request);
        expect(response.statusCode, equals(400));
      });

      test('deve verificar allowedRoles se fornecido', () async {
        final restrictedHandler = requireResourceAccess(
          resourceIdExtractor: (req, id) => int.tryParse(id),
          allowedRoles: ['therapist'],
        )(simpleHandler);

        // User role não permitida
        final request1 = Request(
          'GET',
          Uri.parse('http://localhost/users/123'),
          headers: {'x-user-id': '1', 'x-user-role': 'patient', 'x-account-id': '123'},
        );
        final response1 = await restrictedHandler(request1);
        expect(response1.statusCode, equals(403));

        // Therapist role permitida
        final request2 = Request(
          'GET',
          Uri.parse('http://localhost/users/123'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '123'},
        );
        final response2 = await restrictedHandler(request2);
        expect(response2.statusCode, equals(200));
      });
    });

    group('checkResourceAccess', () {
      test('deve retornar null se acesso permitido', () {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/'),
          headers: {'x-user-id': '1', 'x-user-role': 'user', 'x-account-id': '123'},
        );

        final result = checkResourceAccess(request: request, resourceId: 123);

        expect(result, isNull);
      });

      test('deve retornar Response 403 se acesso negado', () {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/'),
          headers: {'x-user-id': '1', 'x-user-role': 'user', 'x-account-id': '123'},
        );

        final result = checkResourceAccess(request: request, resourceId: 456);

        expect(result, isNotNull);
        expect(result!.statusCode, equals(403));
      });
    });
  });
}
