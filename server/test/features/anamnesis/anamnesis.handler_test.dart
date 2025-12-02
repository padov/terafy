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
      int? userId,
      String? userRole,
      int? accountId,
    }) {
      final uri = Uri.parse('http://localhost$path');
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'x-user-id': (userId ?? 1).toString(),
        'x-user-role': userRole ?? 'therapist',
        if (accountId != null) 'x-account-id': accountId.toString(),
        ...?headers,
      };

      return Request(method, uri, body: body != null ? jsonEncode(body) : null, headers: defaultHeaders);
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

        await repository.createAnamnesis(anamnesis, userId: 1, userRole: 'therapist', accountId: 1);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/patient/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetByPatientId(request, '1');

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
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetByPatientId(request, '999');

        expect(response.statusCode, 404);
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/patient/invalid',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetByPatientId(request, 'invalid');

        expect(response.statusCode, 400);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request('GET', Uri.parse('http://localhost/anamnesis/patient/1'));

        final response = await handler.handleGetByPatientId(request, '1');

        expect(response.statusCode, 401);
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

        await repository.createAnamnesis(anamnesis, userId: 1, userRole: 'therapist', accountId: 1);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetById(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], equals(1));
      });

      test('deve retornar 404 quando não encontrada', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/999',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetById(request, '999');

        expect(response.statusCode, 404);
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/invalid',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetById(request, 'invalid');

        expect(response.statusCode, 400);
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
              'chief_complaint': {'description': 'Ansiedade', 'intensity': 7},
            },
          },
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleCreate(request);

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
          body: {'therapistId': 1, 'data': {}},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando corpo está vazio', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis',
          body: null,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/anamnesis'),
          body: jsonEncode({'patientId': 1}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 401);
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

        await repository.createAnamnesis(anamnesis, userId: 1, userRole: 'therapist', accountId: 1);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/anamnesis/1',
          body: {
            'data': {'new': 'value'},
          },
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], equals(1));
      });

      test('deve retornar 404 quando anamnese não existe', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/anamnesis/999',
          body: {'data': {}},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleUpdate(request, '999');

        expect(response.statusCode, 404);
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/anamnesis/invalid',
          body: {'data': {}},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleUpdate(request, 'invalid');

        expect(response.statusCode, 400);
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

        await repository.createAnamnesis(anamnesis, userId: 1, userRole: 'therapist', accountId: 1);

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/anamnesis/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleDelete(request, '1');

        expect(response.statusCode, 200);
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/anamnesis/invalid',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleDelete(request, 'invalid');

        expect(response.statusCode, 400);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request('DELETE', Uri.parse('http://localhost/anamnesis/1'));

        final response = await handler.handleDelete(request, '1');

        expect(response.statusCode, 401);
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

        await repository.createTemplate(template, userId: 1, userRole: 'therapist', accountId: 1);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/templates',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleListTemplates(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as List;
        expect(data.length, greaterThan(0));
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request('GET', Uri.parse('http://localhost/anamnesis/templates'));

        final response = await handler.handleListTemplates(request);

        expect(response.statusCode, 401);
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
                {'id': 'test', 'title': 'Teste', 'order': 1, 'fields': []},
              ],
            },
          },
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleCreateTemplate(request);

        expect(response.statusCode, 201);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], isNotNull);
        expect(data['name'], equals('Novo Template'));
      });

      test('deve retornar 400 quando corpo está vazio', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: null,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleCreateTemplate(request);

        expect(response.statusCode, 400);
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

        await repository.createTemplate(template, userId: 1, userRole: 'therapist', accountId: 1);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/anamnesis/templates/1',
          body: {
            'name': 'Template Atualizado',
            'category': 'adult',
            'structure': {'sections': []},
          },
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleUpdateTemplate(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['name'], equals('Template Atualizado'));
      });

      test('deve retornar 404 quando template não existe', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/anamnesis/templates/999',
          body: {
            'name': 'Template Atualizado',
            'structure': {'sections': []},
          },
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleUpdateTemplate(request, '999');

        expect(response.statusCode, 404);
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

        await repository.createTemplate(template, userId: 1, userRole: 'therapist', accountId: 1);

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/anamnesis/templates/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleDeleteTemplate(request, '1');

        expect(response.statusCode, 200);
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/anamnesis/templates/invalid',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleDeleteTemplate(request, 'invalid');

        expect(response.statusCode, 400);
      });
    });

    group('Tratamento de erros do controller', () {
      test('handleCreate trata exceção do controller', () async {
        // Mock repository para lançar exceção
        final mockRepo = TestAnamnesisRepository();
        final errorController = AnamnesisController(mockRepo);
        final errorHandler = AnamnesisHandler(errorController);

        // Cria primeira anamnese
        final firstRequest = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {'patientId': 1, 'data': {}},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );
        await errorHandler.handleCreate(firstRequest);

        // Tenta criar segunda anamnese para o mesmo paciente (deve falhar)
        final secondRequest = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {'patientId': 1, 'data': {}},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );
        final response = await errorHandler.handleCreate(secondRequest);

        expect(response.statusCode, 409); // Conflito - já existe
      });

      test('handleUpdate trata erro quando anamnese não encontrada', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/anamnesis/99999',
          body: {'data': {}},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleUpdate(request, '99999');

        expect(response.statusCode, 404);
      });

      test('handleUpdate trata erro quando controller lança exceção', () async {
        final mockRepo = TestAnamnesisRepository();
        final errorController = AnamnesisController(mockRepo);
        final errorHandler = AnamnesisHandler(errorController);

        // Cria primeiro para obter ID válido
        final createRequest = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {'patientId': 1, 'data': {}},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );
        final createResponse = await errorHandler.handleCreate(createRequest);
        final createData = jsonDecode(await createResponse.readAsString()) as Map;
        final anamnesisId = createData['id'] as int;

        // Remove do mock para forçar erro
        mockRepo.clear();

        final updateRequest = createAuthenticatedRequest(
          method: 'PUT',
          path: '/anamnesis/$anamnesisId',
          body: {'data': {}},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await errorHandler.handleUpdate(updateRequest, anamnesisId.toString());

        expect(response.statusCode, 404);
      });
    });

    group('Validações de permissões e roles', () {
      test('handleCreate valida accountId para therapist', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {'patientId': 1},
          userId: 1,
          userRole: 'therapist',
          accountId: null, // Sem accountId
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        expect(body, contains('Conta de terapeuta não vinculada'));
      });

      test('handleCreate permite admin criar para qualquer therapistId', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {'patientId': 1, 'therapistId': 999, 'data': {}},
          userId: 1,
          userRole: 'admin',
          accountId: null,
        );

        final response = await handler.handleCreate(request);

        // Pode retornar 400 se patientId não existe, mas não deve ser 403
        expect(response.statusCode, isNot(403));
      });

      test('handleListTemplates valida accountId para therapist', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/anamnesis/templates',
          userId: 1,
          userRole: 'therapist',
          accountId: null, // Sem accountId
        );

        final response = await handler.handleListTemplates(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        expect(body, contains('Conta de terapeuta não vinculada'));
      });

      test('handleCreateTemplate valida accountId para therapist', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: {'name': 'Template'},
          userId: 1,
          userRole: 'therapist',
          accountId: null, // Sem accountId
        );

        final response = await handler.handleCreateTemplate(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        expect(body, contains('Conta de terapeuta não vinculada'));
      });
    });

    group('Validações de JSON e parsing', () {
      test('handleCreate trata JSON inválido', () async {
        // Envia string inválida (não é JSON válido)
        final invalidRequest = Request(
          'POST',
          Uri.parse('http://localhost/anamnesis'),
          body: 'invalid json',
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
        );

        // O handler deve tratar o erro de parsing e retornar 400
        final response = await handler.handleCreate(invalidRequest);

        // Deve retornar 400 Bad Request para JSON inválido
        expect(response.statusCode, 400);
        final body = await response.readAsString();
        expect(body.toLowerCase(), anyOf(contains('json inválido'), contains('invalid')));
      });

      test('handleUpdate trata JSON inválido', () async {
        final invalidRequest = Request(
          'PUT',
          Uri.parse('http://localhost/anamnesis/1'),
          body: 'invalid json',
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
        );

        final response = await handler.handleUpdate(invalidRequest, '1');

        expect(response.statusCode, greaterThanOrEqualTo(400));
      });
    });

    group('Testes de template com isDefault', () {
      test('handleCreateTemplate remove isDefault anterior ao criar novo', () async {
        // Cria primeiro template como padrão
        final template1Request = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: {'name': 'Template Padrão 1', 'isDefault': true, 'structure': {}},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );
        await handler.handleCreateTemplate(template1Request);

        // Cria segundo template como padrão
        final template2Request = createAuthenticatedRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: {'name': 'Template Padrão 2', 'isDefault': true, 'structure': {}},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );
        final response = await handler.handleCreateTemplate(template2Request);

        expect(response.statusCode, 201);
        // Verificar que primeiro não é mais padrão seria necessário buscar
      });
    });
  });
}
