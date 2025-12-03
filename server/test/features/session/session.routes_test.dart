import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/features/session/session.handler.dart';
import 'package:server/features/session/session.controller.dart';
import 'package:server/features/session/session.routes.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionController extends Mock implements SessionController {}

void main() {
  group('Session Routes', () {
    late SessionHandler handler;
    late Router router;

    setUp(() {
      final controller = _MockSessionController();
      handler = SessionHandler(controller);
      router = configureSessionRoutes(handler);
    });

    group('Rotas de Listagem e Criação', () {
      test('GET / está configurada', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Se a rota está configurada, o handler será chamado
        // O handler pode retornar 404 (não encontrado) ou 200 (encontrado)
        // Se retornar 404 do router (rota não existe), o body será vazio
        expect(
          body.contains('error') || body.contains('Autenticação') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('POST / está configurada', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/'),
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
          body: '{"patientId": 1, "scheduledStartTime": "2024-01-01T10:00:00Z", "durationMinutes": 60}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') ||
              body.contains('JSON') ||
              body.contains('Autenticação') ||
              response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });
    });

    group('Rotas com ID', () {
      test('GET /<id> está configurada', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/1'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') ||
              body.contains('não encontrada') ||
              body.contains('Autenticação') ||
              response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('PUT /<id> está configurada', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/1'),
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
          body: '{"status": "completed"}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') ||
              body.contains('não encontrada') ||
              body.contains('Autenticação') ||
              response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('DELETE /<id> está configurada', () async {
        final request = Request(
          'DELETE',
          Uri.parse('http://localhost/1'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') ||
              body.contains('não encontrada') ||
              body.contains('Autenticação') ||
              response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });
    });

    group('Rota de próximo número', () {
      test('GET /next-number está configurada', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/next-number?patientId=1'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') ||
              body.contains('patientId') ||
              body.contains('Autenticação') ||
              response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });
    });

    group('Validação de padrões de rota', () {
      test('Rota com ID inválido (não numérico) retorna 404', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/abc'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);

        // ID inválido não deve corresponder ao padrão da rota [0-9]+
        expect(response.statusCode, 404);
      });

      test('Rotas com padrões corretos são reconhecidas', () async {
        // O router usa paths relativos (sem o prefixo /sessions)
        final validRoutes = [
          'GET /',
          'POST /',
          'GET /123',
          'PUT /456',
          'DELETE /789',
          'GET /next-number',
        ];

        for (final route in validRoutes) {
          final parts = route.split(' ');
          final method = parts[0];
          final path = parts[1];
          final uri = path == '/next-number'
              ? Uri.parse('http://localhost$path?patientId=1')
              : Uri.parse('http://localhost$path');

          final request = Request(
            method,
            uri,
            headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
            body: method == 'POST' || method == 'PUT'
                ? '{"patientId": 1, "scheduledStartTime": "2024-01-01T10:00:00Z", "durationMinutes": 60}'
                : null,
          );

          final response = await router(request);
          final body = await response.readAsString();

          // Rota deve ser reconhecida (handler foi chamado)
          // Pode retornar 404 do handler (recurso não encontrado), mas não 404 do router (rota não existe)
          expect(
            body.contains('error') ||
                body.contains('não encontrada') ||
                body.contains('Autenticação') ||
                body.contains('patientId') ||
                response.statusCode != 404,
            isTrue,
            reason: 'Rota $route deve ser reconhecida (handler chamado)',
          );
        }
      });
    });
  });
}

