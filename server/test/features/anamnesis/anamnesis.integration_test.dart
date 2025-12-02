import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import '../../helpers/integration_test_db.dart';
import '../../helpers/test_server_setup.dart';
import '../../helpers/http_test_helpers.dart';

void main() {
  group('Anamnesis API Integration Tests', () {
    late Handler handler;
    late TestDBConnection dbConnection;
    String? therapistToken;
    int? therapistId;
    int? patientId;

    setUpAll(() async {
      await TestServerSetup.setup();
      // Cria uma única instância de DBConnection para todos os testes
      dbConnection = TestDBConnection();
    });

    setUp(() async {
      await IntegrationTestDB.cleanDatabase();
      // Pequena espera para garantir que a limpeza foi completada
      await Future.delayed(Duration(milliseconds: 100));
      // Reutiliza a mesma dbConnection, apenas recria o handler
      handler = TestServerSetup.createTestHandler(dbConnection);

      // Pequena espera adicional para garantir que o handler está pronto
      await Future.delayed(Duration(milliseconds: 50));

      // Gera email único para este teste usando timestamp, microsegundos e número aleatório para evitar colisões
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final random = (timestamp % 1000000).toString().padLeft(6, '0');
      // Adiciona um número aleatório adicional para garantir unicidade em execuções paralelas
      final additionalRandom = (timestamp % 10000).toString().padLeft(4, '0');
      final uniqueEmail = 'therapist_${random}_$additionalRandom@terafy.com';
      final uniquePatientEmail = 'paciente_${random}_$additionalRandom@terafy.com';

      // Cria usuário therapist e obtém token
      final registerRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/register',
        body: {'email': uniqueEmail, 'password': 'senha123'},
      );
      final registerResponse = await handler(registerRequest);
      if (registerResponse.statusCode >= 400) {
        final errorBody = await registerResponse.readAsString();
        fail('Falha ao registrar usuário: ${registerResponse.statusCode} - $errorBody');
      }
      final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
      therapistToken = registerData['auth_token'] as String?;
      if (therapistToken == null) {
        fail('Token de autenticação não foi retornado no registro');
      }

      // Cria therapist
      final therapistRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/therapists/me',
        body: {'name': 'Dr. Teste', 'email': uniqueEmail, 'status': 'active'},
        token: therapistToken!,
      );
      final therapistResponse = await handler(therapistRequest);
      if (therapistResponse.statusCode >= 400) {
        final errorBody = await therapistResponse.readAsString();
        fail('Falha ao criar therapist: ${therapistResponse.statusCode} - $errorBody');
      }
      final therapistData = await HttpTestHelpers.parseJsonResponse(therapistResponse);
      therapistId = therapistData['id'] as int?;
      if (therapistId == null) {
        fail('ID do therapist não foi retornado');
      }

      // Faz novo login para obter token com account_id atualizado
      final loginRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/login',
        body: {'email': uniqueEmail, 'password': 'senha123'},
      );
      final loginResponse = await handler(loginRequest);
      if (loginResponse.statusCode >= 400) {
        final errorBody = await loginResponse.readAsString();
        fail('Falha no login: ${loginResponse.statusCode} - $errorBody');
      }
      final loginData = await HttpTestHelpers.parseJsonResponse(loginResponse);
      therapistToken = loginData['auth_token'] as String?;
      if (therapistToken == null) {
        fail('Token de autenticação não foi retornado no login');
      }

      // Cria paciente
      final patientRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/patients',
        body: {
          'fullName': 'Paciente Teste',
          'email': uniquePatientEmail,
          'phones': ['11999999999'],
          'birthDate': '1990-01-01',
        },
        token: therapistToken!,
      );
      final patientResponse = await handler(patientRequest);
      if (patientResponse.statusCode >= 400) {
        final errorBody = await patientResponse.readAsString();
        fail('Falha ao criar paciente: ${patientResponse.statusCode} - $errorBody');
      }
      final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
      patientId = patientData['id'] as int?;
      if (patientId == null) {
        fail('ID do paciente não foi retornado');
      }

      // Garante que não existe nenhuma anamnesis para este paciente antes de começar os testes
      // (segurança extra caso cleanDatabase tenha falhado parcialmente)
      try {
        final checkRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/anamnesis/patient/$patientId',
          token: therapistToken,
        );
        final checkResponse = await handler(checkRequest);
        if (checkResponse.statusCode == 200) {
          final checkData = await HttpTestHelpers.parseJsonResponse(checkResponse);
          final existingId = checkData['id'] as int?;
          if (existingId != null) {
            await handler(
              HttpTestHelpers.createRequest(method: 'DELETE', path: '/anamnesis/$existingId', token: therapistToken!),
            );
          }
        }
      } catch (e) {
        // Ignora erro - provavelmente não existe anamnesis
      }
    });

    tearDown(() async {
      await IntegrationTestDB.cleanDatabase();
    });

    tearDownAll(() async {
      // Fecha todas as conexões do pool ao final dos testes
      await TestDBConnection.closeAllConnections();
    });

    group('POST /anamnesis', () {
      test('deve criar anamnese com dados válidos', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {
            'patientId': patientId,
            'data': {
              'chief_complaint': {'description': 'Ansiedade', 'intensity': 7},
            },
          },
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 201);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], isNotNull);
        expect(data['patientId'], equals(patientId));
        expect(data['therapistId'], equals(therapistId));
        expect(data['data'], isNotNull);

        // Limpa a anamnesis criada para não interferir com outros testes
        final anamnesisId = data['id'] as int;
        await handler(
          HttpTestHelpers.createRequest(method: 'DELETE', path: '/anamnesis/$anamnesisId', token: therapistToken),
        );
      });

      test('deve retornar 400 quando patientId está faltando', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {'data': {}},
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando corpo está vazio', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis',
          body: null,
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 409 quando já existe anamnese para o paciente', () async {
        // Cria primeira anamnese
        final createRequest1 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {'patientId': patientId, 'data': {}},
          token: therapistToken,
        );
        final createResponse1 = await handler(createRequest1);
        final createData1 = await HttpTestHelpers.parseJsonResponse(createResponse1);
        final anamnesisId = createData1['id'] as int;

        // Tenta criar segunda anamnese para o mesmo paciente
        final createRequest2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {'patientId': patientId, 'data': {}},
          token: therapistToken,
        );

        final response = await handler(createRequest2);

        expect(response.statusCode, 409);

        // Limpa a anamnesis criada
        await handler(
          HttpTestHelpers.createRequest(method: 'DELETE', path: '/anamnesis/$anamnesisId', token: therapistToken),
        );
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {'patientId': patientId},
        );

        final response = await handler(request);

        expect(response.statusCode, 401);
      });
    });

    group('GET /anamnesis/patient/:patientId', () {
      test('deve retornar anamnese quando encontrada', () async {
        // Cria anamnese primeiro
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {
            'patientId': patientId,
            'data': {'test': 'value'},
          },
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final anamnesisId = createData['id'] as int;

        // Busca por patientId
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/anamnesis/patient/$patientId',
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], isNotNull);
        expect(data['patientId'], equals(patientId));

        // Limpa a anamnesis criada
        await handler(
          HttpTestHelpers.createRequest(method: 'DELETE', path: '/anamnesis/$anamnesisId', token: therapistToken),
        );
      });

      test('deve retornar 404 quando anamnese não encontrada', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/anamnesis/patient/99999',
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      // Nota: IDs inválidos (não numéricos) são bloqueados pelo router regex [0-9]+
      // e retornam 404 antes de chegar ao handler, então não precisamos testar isso aqui

      test('deve retornar 401 quando não autenticado', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/anamnesis/patient/$patientId');

        final response = await handler(request);

        expect(response.statusCode, 401);
      });
    });

    group('GET /anamnesis/:id', () {
      test('deve retornar anamnese quando encontrada', () async {
        // Cria anamnese primeiro
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {
            'patientId': patientId,
            'data': {'test': 'value'},
          },
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final anamnesisId = createData['id'] as int;

        // Busca por ID
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/anamnesis/$anamnesisId',
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], equals(anamnesisId));

        // Limpa a anamnesis criada
        await handler(
          HttpTestHelpers.createRequest(method: 'DELETE', path: '/anamnesis/$anamnesisId', token: therapistToken),
        );
      });

      test('deve retornar 404 quando não encontrada', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/anamnesis/99999', token: therapistToken);

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      // Nota: IDs inválidos são bloqueados pelo router regex [0-9]+ e retornam 404
    });

    group('PUT /anamnesis/:id', () {
      test('deve atualizar anamnese existente', () async {
        // Cria anamnese primeiro
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {
            'patientId': patientId,
            'data': {'old': 'value'},
          },
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        expect(createResponse.statusCode, 201, reason: 'Deve criar anamnese com sucesso');
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final anamnesisId = createData['id'];
        expect(anamnesisId, isNotNull, reason: 'ID da anamnese não deve ser null');

        // Atualiza
        final updateRequest = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/anamnesis/$anamnesisId',
          body: {
            'data': {'new': 'value', 'updated': true},
            'completedAt': DateTime.now().toIso8601String(),
          },
          token: therapistToken,
        );

        final response = await handler(updateRequest);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], equals(anamnesisId));
        expect(data['data']['new'], equals('value'));

        // Limpa a anamnesis criada
        await handler(
          HttpTestHelpers.createRequest(method: 'DELETE', path: '/anamnesis/$anamnesisId', token: therapistToken),
        );
      });

      test('deve retornar 404 quando anamnese não existe', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/anamnesis/99999',
          body: {'data': {}},
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      // Nota: IDs inválidos são bloqueados pelo router regex [0-9]+ e retornam 404
    });

    group('DELETE /anamnesis/:id', () {
      test('deve deletar anamnese existente', () async {
        // Cria anamnese primeiro
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis',
          body: {'patientId': patientId, 'data': {}},
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        expect(createResponse.statusCode, 201, reason: 'Deve criar anamnese com sucesso');
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final anamnesisId = createData['id'] as int;
        expect(anamnesisId, isNotNull, reason: 'ID da anamnese deve ser válido');

        // Verifica que a anamnese existe antes de deletar
        final verifyRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/anamnesis/$anamnesisId',
          token: therapistToken,
        );
        final verifyResponse = await handler(verifyRequest);
        expect(verifyResponse.statusCode, 200, reason: 'Anamnese deve existir antes de deletar');

        // Deleta
        final deleteRequest = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/anamnesis/$anamnesisId',
          token: therapistToken,
        );

        final deleteResponse = await handler(deleteRequest);

        expect(deleteResponse.statusCode, 200, reason: 'Deve retornar 200 ao deletar com sucesso');

        // Verifica que foi deletada
        final getRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/anamnesis/$anamnesisId',
          token: therapistToken,
        );

        final getResponse = await handler(getRequest);
        expect(getResponse.statusCode, 404, reason: 'Anamnese deve retornar 404 após ser deletada');
      });

      // Nota: IDs inválidos são bloqueados pelo router regex [0-9]+ e retornam 404

      test('deve retornar 401 quando não autenticado', () async {
        final request = HttpTestHelpers.createRequest(method: 'DELETE', path: '/anamnesis/1');

        final response = await handler(request);

        expect(response.statusCode, 401);
      });
    });

    group('GET /anamnesis/templates', () {
      test('deve retornar lista de templates', () async {
        // Cria template primeiro
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: {
            'name': 'Template Teste',
            'category': 'adult',
            'structure': {'sections': []},
          },
          token: therapistToken,
        );
        await handler(createRequest);

        // Lista templates
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/anamnesis/templates',
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isA<List>());
        expect(data.length, greaterThan(0));
      });

      test('deve filtrar por categoria', () async {
        // Cria templates
        await handler(
          HttpTestHelpers.createRequest(
            method: 'POST',
            path: '/anamnesis/templates',
            body: {'name': 'Template Adult', 'category': 'adult', 'structure': {}},
            token: therapistToken,
          ),
        );

        await handler(
          HttpTestHelpers.createRequest(
            method: 'POST',
            path: '/anamnesis/templates',
            body: {'name': 'Template Child', 'category': 'child', 'structure': {}},
            token: therapistToken,
          ),
        );

        // Lista apenas de categoria adult
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/anamnesis/templates?category=adult',
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data.every((t) => t['category'] == 'adult'), isTrue);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/anamnesis/templates');

        final response = await handler(request);

        expect(response.statusCode, 401);
      });
    });

    group('GET /anamnesis/templates/:id', () {
      test('deve retornar template quando encontrado', () async {
        // Cria template primeiro
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: {'name': 'Template Teste', 'structure': {}},
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final templateId = createData['id'] as int;

        // Busca por ID
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/anamnesis/templates/$templateId',
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], equals(templateId));
        expect(data['name'], equals('Template Teste'));
      });

      test('deve retornar 404 quando não encontrado', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/anamnesis/templates/99999',
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      // Nota: IDs inválidos são bloqueados pelo router regex [0-9]+ e retornam 404
    });

    group('POST /anamnesis/templates', () {
      test('deve criar template com dados válidos', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: {
            'name': 'Novo Template',
            'description': 'Descrição do template',
            'category': 'adult',
            'structure': {
              'sections': [
                {'id': 'section1', 'title': 'Seção 1', 'fields': []},
              ],
            },
          },
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 201);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], isNotNull);
        expect(data['name'], equals('Novo Template'));
        expect(data['therapistId'], equals(therapistId));
      });

      test('deve retornar 400 quando corpo está vazio', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: null,
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: {'name': 'Template'},
        );

        final response = await handler(request);

        expect(response.statusCode, 401);
      });
    });

    group('PUT /anamnesis/templates/:id', () {
      test('deve atualizar template existente', () async {
        // Cria template primeiro
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: {'name': 'Template Original', 'structure': {}},
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final templateId = createData['id'] as int;

        // Atualiza
        final updateRequest = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/anamnesis/templates/$templateId',
          body: {'name': 'Template Atualizado', 'description': 'Nova descrição', 'structure': {}},
          token: therapistToken,
        );

        final response = await handler(updateRequest);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['name'], equals('Template Atualizado'));
        expect(data['description'], equals('Nova descrição'));
      });

      test('deve retornar 404 quando template não existe', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/anamnesis/templates/99999',
          body: {'name': 'Template', 'structure': {}},
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      // Nota: IDs inválidos são bloqueados pelo router regex [0-9]+ e retornam 404
    });

    group('DELETE /anamnesis/templates/:id', () {
      test('deve deletar template existente', () async {
        // Cria template primeiro
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/anamnesis/templates',
          body: {'name': 'Template para Deletar', 'structure': {}},
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final templateId = createData['id'] as int;

        // Deleta
        final request = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/anamnesis/templates/$templateId',
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);

        // Verifica que foi deletado
        final getRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/anamnesis/templates/$templateId',
          token: therapistToken,
        );

        final getResponse = await handler(getRequest);
        expect(getResponse.statusCode, 404);
      });

      // Nota: IDs inválidos são bloqueados pelo router regex [0-9]+ e retornam 404

      test('deve retornar 401 quando não autenticado', () async {
        final request = HttpTestHelpers.createRequest(method: 'DELETE', path: '/anamnesis/templates/1');

        final response = await handler(request);

        expect(response.statusCode, 401);
      });
    });
  });
}
