import 'dart:convert';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:common/common.dart';
import 'package:server/features/anamnesis/anamnesis.handler.dart';
import 'package:server/features/anamnesis/anamnesis.controller.dart';
import 'helpers/test_anamnesis_repositories.dart';

void main() {
  group('AnamnesisHandler', () {
    late TestAnamnesisRepository repository;
    late AnamnesisController controller;
    late AnamnesisHandler handler;

    setUp(() {
      repository = TestAnamnesisRepository();
      controller = AnamnesisController(repository);
      handler = AnamnesisHandler(controller);
    });

    tearDown(() {
      repository.clear();
    });

    // Helper para criar request autenticado
    Request createAuthenticatedRequest({
      required String method,
      required String path,
      Map<String, dynamic>? body,
      Map<String, String>? headers,
    }) {
      final uri = Uri.parse('http://localhost$path');
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'x-user-id': '1',
        'x-user-role': 'therapist',
        'x-account-id': '1',
        ...?headers,
      };

      return Request(
        method,
        uri,
        body: body != null ? jsonEncode(body) : null,
        headers: defaultHeaders,
      );
    }

    group('GET /anamnesis/patient/:patientId', () {
      test('deve retornar anamnese quando encontrada', () async {
        final anamnesis = Anamnesis(
          id: 1,
          patientId: 1,
          therapistId: 1,
          data: {'test': 'value'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createAnamnesis(
          anamnesis,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/patient/1',
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], equals(1));
        expect(data['patientId'], equals(1));
      });

      test('deve retornar 404 quando anamnese não encontrada', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/patient/999',
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 404);
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/patient/invalid',
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 400);
      });
    });

    group('GET /anamnesis/:id', () {
      test('deve retornar anamnese quando encontrada', () async {
        final anamnesis = Anamnesis(
          id: 1,
          patientId: 1,
          therapistId: 1,
          data: {'test': 'value'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createAnamnesis(
          anamnesis,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/1',
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], equals(1));
      });

      test('deve retornar 404 quando não encontrada', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/999',
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 404);
      });
    });

    group('POST /anamnesis', () {
      test('deve criar anamnese com dados válidos', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {
            'patientId': 1,
            'therapistId': 1,
            'data': {
              'chief_complaint': {
                'description': 'Ansiedade',
                'intensity': 7,
              },
            },
          },
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 201);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], isNotNull);
        expect(data['patientId'], equals(1));
      });

      test('deve retornar 400 quando patientId está faltando', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {
            'therapistId': 1,
            'data': {},
          },
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando corpo está vazio', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis',
          body: null,
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 400);
      });
    });

    group('PUT /anamnesis/:id', () {
      test('deve atualizar anamnese existente', () async {
        final anamnesis = Anamnesis(
          id: 1,
          patientId: 1,
          therapistId: 1,
          data: {'old': 'value'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createAnamnesis(
          anamnesis,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/anamnesis/1',
          body: {
            'data': {
              'new': 'value',
            },
          },
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], equals(1));
      });

      test('deve retornar 404 quando anamnese não existe', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/anamnesis/999',
          body: {
            'data': {},
          },
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 404);
      });
    });

    group('DELETE /anamnesis/:id', () {
      test('deve deletar anamnese existente', () async {
        final anamnesis = Anamnesis(
          id: 1,
          patientId: 1,
          therapistId: 1,
          data: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createAnamnesis(
          anamnesis,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/anamnesis/1',
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/anamnesis/invalid',
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 400);
      });
    });

    group('GET /anamnesis/templates', () {
      test('deve retornar lista de templates', () async {
        final template = AnamnesisTemplate(
          id: 1,
          therapistId: 1,
          name: 'Template Teste',
          structure: {'sections': []},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createTemplate(
          template,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/templates',
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as List;
        expect(data.length, greaterThan(0));
      });
    });

    group('POST /anamnesis/templates', () {
      test('deve criar template com dados válidos', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: {
            'name': 'Novo Template',
            'category': 'adult',
            'structure': {
              'sections': [
                {
                  'id': 'test',
                  'title': 'Teste',
                  'order': 1,
                  'fields': [],
                },
              ],
            },
          },
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 201);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], isNotNull);
        expect(data['name'], equals('Novo Template'));
      });
    });

    group('PUT /anamnesis/templates/:id', () {
      test('deve atualizar template existente', () async {
        final template = AnamnesisTemplate(
          id: 1,
          therapistId: 1,
          name: 'Template Original',
          structure: {'sections': []},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createTemplate(
          template,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/anamnesis/templates/1',
          body: {
            'name': 'Template Atualizado',
            'category': 'adult',
            'structure': {'sections': []},
          },
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['name'], equals('Template Atualizado'));
      });
    });

    group('DELETE /anamnesis/templates/:id', () {
      test('deve deletar template existente', () async {
        final template = AnamnesisTemplate(
          id: 1,
          therapistId: 1,
          name: 'Template para Deletar',
          structure: {'sections': []},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createTemplate(
          template,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/anamnesis/templates/1',
        );

        final response = await handler.router.call(request);

        expect(response.statusCode, 200);
      });
    });
  });
}

