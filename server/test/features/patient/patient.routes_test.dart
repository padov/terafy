import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/features/patient/patient.handler.dart';
import 'package:server/features/patient/patient.controller.dart';
import 'package:server/features/patient/patient.routes.dart';
import 'package:mocktail/mocktail.dart';

class _MockPatientController extends Mock implements PatientController {}

void main() {
  group('Patient Routes', () {
    late PatientHandler handler;
    late Router router;

    setUp(() {
      final controller = _MockPatientController();
      handler = PatientHandler(controller);
      router = configurePatientRoutes(handler);
    });

    group('Rotas de Listagem e Criação', () {
      test('GET / está configurada', () async {
        // O router retornado por configurePatientRoutes usa paths relativos
        // então a rota é / e não /patients/
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
          body: '{"fullName": "Teste", "therapistId": 1}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') || body.contains('JSON') || body.contains('Autenticação') || response.statusCode != 404,
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
          body.contains('error') || body.contains('não encontrado') || body.contains('Autenticação') || response.statusCode != 404,
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
          body: '{"fullName": "Teste"}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') || body.contains('não encontrado') || body.contains('Autenticação') || response.statusCode != 404,
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
          body.contains('error') || body.contains('não encontrado') || body.contains('Autenticação') || response.statusCode != 404,
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
        // O router usa paths relativos (sem o prefixo /patients)
        final validRoutes = [
          'GET /',
          'POST /',
          'GET /123',
          'PUT /456',
          'DELETE /789',
        ];

        for (final route in validRoutes) {
          final parts = route.split(' ');
          final method = parts[0];
          final path = parts[1];

          final request = Request(
            method,
            Uri.parse('http://localhost$path'),
            headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
          );

          final response = await router(request);
          final body = await response.readAsString();

          // Rota deve ser reconhecida (handler foi chamado)
          // Pode retornar 404 do handler (recurso não encontrado), mas não 404 do router (rota não existe)
          expect(
            body.contains('error') ||
                body.contains('não encontrado') ||
                body.contains('Autenticação') ||
                response.statusCode != 404,
            isTrue,
            reason: 'Rota $route deve ser reconhecida (handler chamado)',
          );
        }
      });
    });
  });
}

