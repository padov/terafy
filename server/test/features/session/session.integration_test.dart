import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import '../../helpers/integration_test_db.dart';
import '../../helpers/test_server_setup.dart';
import '../../helpers/http_test_helpers.dart';

void main() {
  group('Session API Integration Tests', () {
    late Handler handler;
    late TestDBConnection dbConnection;
    String? therapistToken;
    int? therapistId;

    setUpAll(() async {
      await TestServerSetup.setup();
    });

    setUp(() async {
      await IntegrationTestDB.cleanDatabase();
      dbConnection = TestDBConnection();
      handler = TestServerSetup.createTestHandler(dbConnection);

      // Cria usuário therapist e obtém token
      final registerRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/register',
        body: {'email': 'therapist@terafy.com', 'password': 'senha123'},
      );
      final registerResponse = await handler(registerRequest);
      final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
      therapistToken = registerData['auth_token'] as String;

      // Cria therapist
      final therapistRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/therapists/me',
        body: {'name': 'Dr. Teste', 'email': 'teste@terafy.app.br', 'status': 'active'},
        token: therapistToken,
      );
      final therapistResponse = await handler(therapistRequest);
      final therapistData = await HttpTestHelpers.parseJsonResponse(therapistResponse);
      therapistId = therapistData['id'] as int;

      // Faz novo login para obter token com account_id atualizado
      final loginRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/login',
        body: {'email': 'therapist@terafy.com', 'password': 'senha123'},
      );
      final loginResponse = await handler(loginRequest);
      final loginData = await HttpTestHelpers.parseJsonResponse(loginResponse);
      therapistToken = loginData['auth_token'] as String;
    });

    tearDown(() async {
      await IntegrationTestDB.cleanDatabase();
    });

    group('POST /sessions', () {
      test('deve criar sessão para therapist autenticado', () async {
        // Cria um paciente primeiro
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Teste',
            'email': 'paciente.teste@terafy.app.br',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        // Agora cria a sessão
        final scheduledStartTime = DateTime.now().add(Duration(days: 1));
        final durationMinutes = 60;
        final scheduledEndTime = scheduledStartTime.add(Duration(minutes: durationMinutes));
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': patientId,
            'scheduledStartTime': scheduledStartTime.toIso8601String(),
            'scheduledEndTime': scheduledEndTime.toIso8601String(),
            'durationMinutes': durationMinutes,
            'sessionNumber': 1,
            'type': 'onlineVideo',
            'modality': 'individual',
            'status': 'scheduled',
            'paymentStatus': 'pending',
            'currentRisk': 'low',
            'needsReferral': false,
          },
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], isNotNull);
        expect(data['therapistId'], therapistId);
      });

      test('deve retornar 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': 1,
            'scheduledStartTime': DateTime.now().toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 1,
            'type': 'onlineVideo',
            'modality': 'individual',
            'status': 'scheduled',
            'paymentStatus': 'pending',
          },
        );

        final response = await handler(request);
        expect(response.statusCode, 401);
      });
    });

    group('GET /sessions', () {
      test('deve listar sessões do therapist autenticado', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/sessions', token: therapistToken);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isA<List>());
      });
    });

    group('GET /sessions/next-number', () {
      test('deve retornar próximo número de sessão', () async {
        // Cria um paciente primeiro
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Next Number',
            'email': 'paciente.next@terafy.com',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/sessions/next-number?patientId=$patientId',
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['nextNumber'], isNotNull);
        expect(data['nextNumber'], 1); // Primeira sessão
      });

      test('deve incrementar número após criar sessões', () async {
        // Cria um paciente primeiro
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Increment',
            'email': 'paciente.increment@terafy.com',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        // Cria primeira sessão
        final session1Request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': patientId,
            'scheduledStartTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 1,
            'type': 'presential',
            'modality': 'individual',
            'status': 'scheduled',
            'paymentStatus': 'pending',
            'currentRisk': 'low',
            'needsReferral': false,
          },
          token: therapistToken,
        );
        await handler(session1Request);

        // Verifica próximo número
        final nextNumberRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/sessions/next-number?patientId=$patientId',
          token: therapistToken,
        );
        final nextNumberResponse = await handler(nextNumberRequest);
        final nextNumberData = await HttpTestHelpers.parseJsonResponse(nextNumberResponse);

        expect(nextNumberData['nextNumber'], 2);
      });
    });

    group('GET /sessions/<id>', () {
      test('deve retornar sessão específica', () async {
        // Cria paciente e sessão
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Get',
            'email': 'paciente.get@terafy.com',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': patientId,
            'scheduledStartTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 1,
            'type': 'presential',
            'modality': 'individual',
            'status': 'scheduled',
            'paymentStatus': 'pending',
            'currentRisk': 'low',
            'needsReferral': false,
          },
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final sessionId = createData['id'] as int;

        // Busca sessão
        final getRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/sessions/$sessionId',
          token: therapistToken,
        );
        final getResponse = await handler(getRequest);

        expect(getResponse.statusCode, 200);
        final getData = await HttpTestHelpers.parseJsonResponse(getResponse);
        expect(getData['id'], sessionId);
        expect(getData['patientId'], patientId);
      });

      test('deve retornar 404 quando sessão não existe', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/sessions/99999', token: therapistToken);

        final response = await handler(request);
        expect(response.statusCode, 404);
      });
    });

    group('PUT /sessions/<id>', () {
      test('deve atualizar sessão', () async {
        // Cria paciente e sessão
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Update',
            'email': 'paciente.update@terafy.com',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': patientId,
            'scheduledStartTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 1,
            'type': 'presential',
            'modality': 'individual',
            'status': 'scheduled',
            'paymentStatus': 'pending',
            'currentRisk': 'low',
            'needsReferral': false,
          },
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final sessionId = createData['id'] as int;

        // Atualiza sessão
        final updateRequest = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/sessions/$sessionId',
          body: {
            'patientId': patientId,
            'therapistId': therapistId,
            'scheduledStartTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 1,
            'type': 'presential',
            'modality': 'individual',
            'status': 'completed',
            'paymentStatus': 'paid',
            'currentRisk': 'low',
            'needsReferral': false,
            'sessionNotes': 'Sessão concluída com sucesso',
          },
          token: therapistToken,
        );
        final updateResponse = await handler(updateRequest);

        expect(updateResponse.statusCode, 200);
        final updateData = await HttpTestHelpers.parseJsonResponse(updateResponse);
        expect(updateData['status'], 'completed');
        expect(updateData['sessionNotes'], 'Sessão concluída com sucesso');
      });

      test('deve retornar 404 quando sessão não existe', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/sessions/99999',
          body: {
            'status': 'completed',
            'patientId': 1,
            'therapistId': therapistId,
            'scheduledStartTime': DateTime.now().toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 1,
            'type': 'presential',
            'modality': 'individual',
            'paymentStatus': 'pending',
          },
          token: therapistToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 404);
      });
    });

    group('DELETE /sessions/<id>', () {
      test('deve deletar sessão', () async {
        // Cria paciente e sessão
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Delete',
            'email': 'paciente.delete@terafy.com',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': patientId,
            'scheduledStartTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 1,
            'type': 'presential',
            'modality': 'individual',
            'status': 'scheduled',
            'paymentStatus': 'pending',
            'currentRisk': 'low',
            'needsReferral': false,
          },
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final sessionId = createData['id'] as int;

        // Deleta sessão
        final deleteRequest = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/sessions/$sessionId',
          token: therapistToken,
        );
        final deleteResponse = await handler(deleteRequest);

        expect(deleteResponse.statusCode, 200);

        // Verifica que sessão foi deletada
        final getRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/sessions/$sessionId',
          token: therapistToken,
        );
        final getResponse = await handler(getRequest);
        expect(getResponse.statusCode, 404);
      });

      test('deve retornar 404 quando sessão não existe', () async {
        final request = HttpTestHelpers.createRequest(method: 'DELETE', path: '/sessions/99999', token: therapistToken);

        final response = await handler(request);
        expect(response.statusCode, 404);
      });
    });

    group('GET /sessions - filtros', () {
      test('deve filtrar por patientId', () async {
        // Cria dois pacientes
        final patient1Request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Filtro 1',
            'email': 'paciente.filtro1@terafy.com',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patient1Response = await handler(patient1Request);
        final patient1Data = await HttpTestHelpers.parseJsonResponse(patient1Response);
        final patient1Id = patient1Data['id'] as int;

        final patient2Request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Filtro 2',
            'email': 'paciente.filtro2@terafy.com',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patient2Response = await handler(patient2Request);
        final patient2Data = await HttpTestHelpers.parseJsonResponse(patient2Response);
        final patient2Id = patient2Data['id'] as int;

        // Cria sessões para cada paciente
        await handler(
          HttpTestHelpers.createRequest(
            method: 'POST',
            path: '/sessions',
            body: {
              'patientId': patient1Id,
              'scheduledStartTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
              'durationMinutes': 60,
              'sessionNumber': 1,
              'type': 'presential',
              'modality': 'individual',
              'status': 'scheduled',
              'paymentStatus': 'pending',
              'currentRisk': 'low',
              'needsReferral': false,
            },
            token: therapistToken,
          ),
        );

        await handler(
          HttpTestHelpers.createRequest(
            method: 'POST',
            path: '/sessions',
            body: {
              'patientId': patient2Id,
              'scheduledStartTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
              'durationMinutes': 60,
              'sessionNumber': 1,
              'type': 'presential',
              'modality': 'individual',
              'status': 'scheduled',
              'paymentStatus': 'pending',
              'currentRisk': 'low',
              'needsReferral': false,
            },
            token: therapistToken,
          ),
        );

        // Filtra por patientId
        final filterRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/sessions?patientId=$patient1Id',
          token: therapistToken,
        );
        final filterResponse = await handler(filterRequest);

        expect(filterResponse.statusCode, 200);
        final filterData = await HttpTestHelpers.parseJsonListResponse(filterResponse);
        expect(filterData.length, 1);
        expect(filterData[0]['patientId'], patient1Id);
      });

      test('deve filtrar por status', () async {
        // Cria paciente
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Status',
            'email': 'paciente.status@terafy.com',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        // Cria sessões com status diferentes
        await handler(
          HttpTestHelpers.createRequest(
            method: 'POST',
            path: '/sessions',
            body: {
              'patientId': patientId,
              'scheduledStartTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
              'durationMinutes': 60,
              'sessionNumber': 1,
              'type': 'presential',
              'modality': 'individual',
              'status': 'scheduled',
              'paymentStatus': 'pending',
              'currentRisk': 'low',
              'needsReferral': false,
            },
            token: therapistToken,
          ),
        );

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': patientId,
            'scheduledStartTime': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 2,
            'type': 'presential',
            'modality': 'individual',
            'status': 'completed',
            'paymentStatus': 'paid',
            'currentRisk': 'low',
            'needsReferral': false,
          },
          token: therapistToken,
        );
        await handler(createRequest);

        // Filtra por status
        final filterRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/sessions?status=completed',
          token: therapistToken,
        );
        final filterResponse = await handler(filterRequest);

        expect(filterResponse.statusCode, 200);
        final filterData = await HttpTestHelpers.parseJsonListResponse(filterResponse);
        expect(filterData.every((s) => s['status'] == 'completed'), isTrue);
      });
    });
  });
}
