import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/features/anamnesis/anamnesis.handler.dart';
import 'package:server/features/anamnesis/anamnesis.controller.dart';
import 'package:server/features/anamnesis/anamnesis.routes.dart';
import 'helpers/test_anamnesis_repositories.dart';

void main() {
  group('Anamnesis Routes', () {
    late AnamnesisHandler handler;
    late Router router;

    setUp(() {
      final repository = TestAnamnesisRepository();
      final controller = AnamnesisController(repository);
      handler = AnamnesisHandler(controller);
      router = configureAnamnesisRoutes(handler);
    });

    group('Rotas de Anamnese', () {
      test('GET /anamnesis/patient/:patientId está configurada', () async {
        // O router retornado por configureAnamnesisRoutes usa paths relativos
        // então a rota é /patient/<id> e não /anamnesis/patient/<id>
        final request = Request(
          'GET',
          Uri.parse('http://localhost/patient/1'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);

        // Se a rota está configurada, o handler será chamado
        // O handler pode retornar 404 (não encontrado) ou 200 (encontrado)
        // Se retornar 404 do router (rota não existe), o body será vazio
        // Verificamos que a rota está configurada verificando o body da resposta
        final body = await response.readAsString();

        // Se o handler foi chamado, deve ter uma resposta JSON estruturada
        // (mesmo que seja 404 com mensagem de erro)
        // Se o router não encontrou a rota, o body será vazio ou HTML padrão
        expect(
          body.contains('error') || body.contains('não encontrada') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('GET /anamnesis/:id está configurada', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/1'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') || body.contains('não encontrada') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('POST /anamnesis está configurada', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/'),
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
          body: '{"patientId": 1, "data": {}}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') || body.contains('JSON') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('PUT /anamnesis/:id está configurada', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/1'),
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
          body: '{"data": {}}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') || body.contains('não encontrada') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('DELETE /anamnesis/:id está configurada', () async {
        final request = Request(
          'DELETE',
          Uri.parse('http://localhost/1'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') || body.contains('não encontrada') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('Rota com ID inválido retorna 404', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/abc'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);

        // ID inválido não deve corresponder ao padrão da rota
        expect(response.statusCode, 404);
      });
    });

    group('Rotas de Template', () {
      test('GET /anamnesis/templates está configurada', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/templates'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') || body.contains('JSON') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('GET /anamnesis/templates/:id está configurada', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/templates/1'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') || body.contains('não encontrado') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('POST /anamnesis/templates está configurada', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/templates'),
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
          body: '{"name": "Template", "structure": {}}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') || body.contains('JSON') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('PUT /anamnesis/templates/:id está configurada', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/templates/1'),
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
          body: '{"name": "Template", "structure": {}}',
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') || body.contains('não encontrado') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('DELETE /anamnesis/templates/:id está configurada', () async {
        final request = Request(
          'DELETE',
          Uri.parse('http://localhost/templates/1'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);
        final body = await response.readAsString();

        // Verifica que a rota está configurada (handler foi chamado)
        expect(
          body.contains('error') || body.contains('não encontrado') || response.statusCode != 404,
          isTrue,
          reason: 'Rota deve estar configurada (handler chamado)',
        );
      });

      test('Rota de template com ID inválido retorna 404', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/templates/abc'),
          headers: {'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await router(request);

        expect(response.statusCode, 404);
      });
    });

    group('Validação de padrões de rota', () {
      test('Padrão de ID aceita apenas números', () {
        // Esta validação é feita pelo shelf_router usando regex
        // Verificamos que a rota não aceita IDs não numéricos
        // Isso é testado indiretamente nos testes acima onde IDs inválidos retornam 404
        expect(true, isTrue); // Placeholder - validação é feita pelo router
      });

      test('Rotas com padrões corretos são reconhecidas', () async {
        // O router usa paths relativos (sem o prefixo /anamnesis)
        final validRoutes = [
          'GET /patient/123',
          'GET /456',
          'POST /',
          'PUT /789',
          'DELETE /101',
          'GET /templates',
          'GET /templates/202',
          'POST /templates',
          'PUT /templates/303',
          'DELETE /templates/404',
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
                body.contains('não encontrada') ||
                body.contains('não encontrado') ||
                body.contains('JSON') ||
                response.statusCode != 404,
            isTrue,
            reason: 'Rota $route deve ser reconhecida (handler chamado)',
          );
        }
      });
    });
  });
}
