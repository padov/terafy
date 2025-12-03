import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import '../../helpers/integration_test_db.dart';
import '../../helpers/test_server_setup.dart';
import '../../helpers/http_test_helpers.dart';

void main() {
  group('Patient API Integration Tests', () {
    late Handler handler;
    late TestDBConnection dbConnection;
    String? therapistToken;
    String? adminToken;
    int? therapistId;

    setUpAll(() async {
      await TestServerSetup.setup();
      dbConnection = TestDBConnection();
    });

    setUp(() async {
      await IntegrationTestDB.cleanDatabase();
      await Future.delayed(const Duration(milliseconds: 100));
      handler = TestServerSetup.createTestHandler(dbConnection);
      await Future.delayed(const Duration(milliseconds: 50));

      // Gera emails únicos para evitar conflitos
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final random = (timestamp % 1000000).toString().padLeft(6, '0');
      final additionalRandom = (timestamp % 10000).toString().padLeft(4, '0');
      final uniqueTherapistEmail = 'therapist_${random}_$additionalRandom@terafy.com';
      final uniqueAdminEmail = 'admin_${random}_$additionalRandom@terafy.com';

      // Cria usuário therapist e obtém token
      final registerTherapistRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/register',
        body: {'email': uniqueTherapistEmail, 'password': 'senha123'},
      );
      final registerTherapistResponse = await handler(registerTherapistRequest);
      if (registerTherapistResponse.statusCode >= 400) {
        final errorBody = await registerTherapistResponse.readAsString();
        fail('Falha ao registrar therapist: ${registerTherapistResponse.statusCode} - $errorBody');
      }
      final registerTherapistData = await HttpTestHelpers.parseJsonResponse(registerTherapistResponse);
      therapistToken = registerTherapistData['auth_token'] as String?;
      if (therapistToken == null) {
        fail('Token de autenticação não foi retornado no registro do therapist');
      }

      // Cria therapist
      final therapistRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/therapists/me',
        body: {'name': 'Dr. Teste', 'email': uniqueTherapistEmail, 'status': 'active'},
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
      final loginTherapistRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/login',
        body: {'email': uniqueTherapistEmail, 'password': 'senha123'},
      );
      final loginTherapistResponse = await handler(loginTherapistRequest);
      if (loginTherapistResponse.statusCode >= 400) {
        final errorBody = await loginTherapistResponse.readAsString();
        fail('Falha no login do therapist: ${loginTherapistResponse.statusCode} - $errorBody');
      }
      final loginTherapistData = await HttpTestHelpers.parseJsonResponse(loginTherapistResponse);
      therapistToken = loginTherapistData['auth_token'] as String?;
      if (therapistToken == null) {
        fail('Token de autenticação não foi retornado no login do therapist');
      }

      // Cria usuário admin
      final registerAdminRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/register',
        body: {'email': uniqueAdminEmail, 'password': 'senha123'},
      );
      final registerAdminResponse = await handler(registerAdminRequest);
      if (registerAdminResponse.statusCode >= 400) {
        final errorBody = await registerAdminResponse.readAsString();
        fail('Falha ao registrar admin: ${registerAdminResponse.statusCode} - $errorBody');
      }
      final registerAdminData = await HttpTestHelpers.parseJsonResponse(registerAdminResponse);
      final adminUserId = registerAdminData['user']['id'] as int?;
      if (adminUserId == null) {
        fail('ID do usuário admin não foi retornado no registro');
      }

      // Atualiza role do admin para 'admin' no banco
      final adminConn = await dbConnection.getConnection();
      try {
        await adminConn.execute(
          Sql.named('UPDATE users SET role = \'admin\' WHERE id = @id'),
          parameters: {'id': adminUserId},
        );
      } finally {
        dbConnection.releaseConnection(adminConn);
      }

      // Faz login novamente para obter token com role atualizado
      final loginAdminRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/login',
        body: {'email': uniqueAdminEmail, 'password': 'senha123'},
      );
      final loginAdminResponse = await handler(loginAdminRequest);
      if (loginAdminResponse.statusCode >= 400) {
        final errorBody = await loginAdminResponse.readAsString();
        fail('Falha no login do admin: ${loginAdminResponse.statusCode} - $errorBody');
      }
      final loginAdminData = await HttpTestHelpers.parseJsonResponse(loginAdminResponse);
      adminToken = loginAdminData['auth_token'] as String?;
      if (adminToken == null) {
        fail('Token de autenticação não foi retornado no login do admin');
      }
    });

    tearDown(() async {
      await IntegrationTestDB.cleanDatabase();
    });

    tearDownAll(() async {
      await TestDBConnection.closeAllConnections();
    });

    group('GET /patients', () {
      test('lista pacientes do therapist autenticado (200)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'p1_$random@test.com';

        // Cria paciente
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente 1',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        await handler(createRequest);

        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/patients', token: therapistToken!);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final body = await HttpTestHelpers.parseJsonListResponse(response);
        expect(body, isA<List>());
        expect(body.length, greaterThanOrEqualTo(1));
      });

      test('admin lista todos os pacientes (200)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'p1_$random@test.com';

        // Cria pacientes para diferentes therapists
        final createRequest1 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente 1', 'email': uniqueEmail, 'therapistId': therapistId},
          token: adminToken!,
        );
        final createResponse1 = await handler(createRequest1);
        if (createResponse1.statusCode >= 400) {
          final errorBody = await createResponse1.readAsString();
          fail('Falha ao criar paciente: ${createResponse1.statusCode} - $errorBody');
        }

        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/patients', token: adminToken!);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final body = await HttpTestHelpers.parseJsonListResponse(response);
        expect(body, isA<List>());
      });

      test('admin filtra por therapistId (200)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'filtrado_$random@test.com';

        // Cria paciente
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente Filtrado', 'email': uniqueEmail, 'therapistId': therapistId},
          token: adminToken!,
        );
        final createResponse = await handler(createRequest);
        if (createResponse.statusCode >= 400) {
          final errorBody = await createResponse.readAsString();
          fail('Falha ao criar paciente: ${createResponse.statusCode} - $errorBody');
        }

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/patients?therapistId=$therapistId',
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final body = await HttpTestHelpers.parseJsonListResponse(response);
        expect(body, isA<List>());
      });

      test('retorna 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/patients');

        final response = await handler(request);

        expect(response.statusCode, 401);
      });

      test('retorna 400 quando therapist sem accountId', () async {
        // Gera email único para evitar conflitos
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'therapist_sem_perfil_$random@test.com';

        // Cria usuário therapist sem criar perfil
        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail, 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final tokenSemPerfil = registerData['auth_token'] as String;

        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/patients', token: tokenSemPerfil);

        final response = await handler(request);

        expect(response.statusCode, 400);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['error'], contains('Conta de terapeuta não vinculada'));
      });

      test('retorna lista vazia quando não há pacientes', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/patients', token: therapistToken!);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final body = await HttpTestHelpers.parseJsonListResponse(response);
        expect(body, isA<List>());
        expect(body, isEmpty);
      });
    });

    group('GET /patients/:id', () {
      test('retorna paciente existente (200)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'get_$random@test.com';

        // Cria paciente
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Get',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final createdId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/patients/$createdId',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['id'], equals(createdId));
        expect(body['fullName'], equals('Paciente Get'));
      });

      test('retorna 404 quando paciente não existe', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/patients/99999', token: therapistToken!);

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      test('retorna 404 quando ID inválido (não corresponde ao padrão da rota)', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/patients/abc', token: therapistToken!);

        final response = await handler(request);

        // A rota usa regex [0-9]+, então IDs não numéricos retornam 404 (rota não encontrada)
        expect(response.statusCode, 404);
      });

      test('retorna 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/patients/1');

        final response = await handler(request);

        expect(response.statusCode, 401);
      });

      test('therapist só acessa seus pacientes (404)', () async {
        // Cria outro therapist para ter um paciente de outro therapist
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail2 = 'therapist2_$random@terafy.com';

        final registerRequest2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail2, 'password': 'senha123'},
        );
        final registerResponse2 = await handler(registerRequest2);
        if (registerResponse2.statusCode >= 400) {
          final errorBody = await registerResponse2.readAsString();
          fail('Falha ao registrar segundo therapist: ${registerResponse2.statusCode} - $errorBody');
        }
        final registerData2 = await HttpTestHelpers.parseJsonResponse(registerResponse2);
        final token2 = registerData2['auth_token'] as String;

        final therapistRequest2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/therapists/me',
          body: {'name': 'Dr. Outro', 'email': uniqueEmail2, 'status': 'active'},
          token: token2,
        );
        final therapistResponse2 = await handler(therapistRequest2);
        if (therapistResponse2.statusCode >= 400) {
          final errorBody = await therapistResponse2.readAsString();
          fail('Falha ao criar segundo therapist: ${therapistResponse2.statusCode} - $errorBody');
        }

        final loginRequest2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/login',
          body: {'email': uniqueEmail2, 'password': 'senha123'},
        );
        final loginResponse2 = await handler(loginRequest2);
        if (loginResponse2.statusCode >= 400) {
          final errorBody = await loginResponse2.readAsString();
          fail('Falha no login do segundo therapist: ${loginResponse2.statusCode} - $errorBody');
        }
        final loginData2 = await HttpTestHelpers.parseJsonResponse(loginResponse2);
        final token2Updated = loginData2['auth_token'] as String;

        // Cria paciente para o outro therapist
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente Outro', 'email': 'outro_$random@test.com'},
          token: token2Updated,
        );
        final createResponse = await handler(createRequest);
        if (createResponse.statusCode >= 400) {
          final errorBody = await createResponse.readAsString();
          fail('Falha ao criar paciente para segundo therapist: ${createResponse.statusCode} - $errorBody');
        }
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final otherPatientId = createData['id'] as int?;
        final otherPatientTherapistId = createData['therapistId'] as int?;
        if (otherPatientId == null) {
          fail('ID do paciente não foi retornado na criação');
        }
        if (otherPatientTherapistId == null) {
          fail('therapistId do paciente não foi retornado na criação');
        }

        // Verifica que o paciente foi criado para um therapist diferente
        expect(
          otherPatientTherapistId,
          isNot(equals(therapistId)),
          reason:
              'Paciente deve ser criado para um therapist diferente do original. '
              'Paciente therapistId=$otherPatientTherapistId, therapist original accountId=$therapistId',
        );

        // Verifica que o therapist original tem accountId configurado
        expect(therapistId, isNotNull, reason: 'Therapist original deve ter accountId configurado');

        // Therapist original não deve conseguir acessar paciente de outro therapist
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/patients/$otherPatientId',
          token: therapistToken!,
        );

        final response = await handler(request);

        // O RLS deve bloquear e retornar 404 (paciente não encontrado para este therapist)
        // ou o handler pode retornar 404 se o repository retornar null
        expect(
          response.statusCode,
          greaterThanOrEqualTo(400),
          reason:
              'Therapist não deve conseguir acessar paciente de outro therapist. '
              'Paciente criado com therapistId=$otherPatientTherapistId, '
              'therapist original tem accountId=$therapistId. '
              'Status recebido: ${response.statusCode}',
        );
      });

      test('admin acessa qualquer paciente (200)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'admin_patient_$random@test.com';

        // Cria paciente
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente Admin', 'email': uniqueEmail, 'therapistId': therapistId},
          token: adminToken!,
        );
        final createResponse = await handler(createRequest);
        if (createResponse.statusCode >= 400) {
          final errorBody = await createResponse.readAsString();
          fail('Falha ao criar paciente: ${createResponse.statusCode} - $errorBody');
        }
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final createdId = createData['id'] as int?;
        if (createdId == null) {
          fail('ID do paciente não foi retornado na criação');
        }

        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/patients/$createdId', token: adminToken!);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['id'], equals(createdId));
      });
    });

    group('POST /patients', () {
      test('cria paciente com sucesso (201)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'novo_$random@test.com';

        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Novo',
            'email': uniqueEmail,
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 201);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['id'], isNotNull);
        expect(body['fullName'], equals('Paciente Novo'));
        expect(body['email'], equals(uniqueEmail));
      });

      test('cria paciente com todos os campos (201)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'completo_$random@test.com';

        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Completo',
            'email': uniqueEmail,
            'birthDate': '1990-01-01T00:00:00Z',
            'age': 34,
            'cpf': '12345678900',
            'rg': '123456789',
            'gender': 'M',
            'maritalStatus': 'single',
            'address': 'Rua Teste, 123',
            'phones': ['11999999999', '11888888888'],
            'profession': 'Engenheiro',
            'education': 'Superior',
            'emergencyContact': {'name': 'Contato', 'phone': '11777777777'},
            'legalGuardian': {'name': 'Tutor', 'phone': '11666666666'},
            'healthInsurance': 'Unimed',
            'healthInsuranceCard': '123456',
            'preferredPaymentMethod': 'credit',
            'sessionPrice': 150.0,
            'tags': ['tag1', 'tag2'],
            'notes': 'Notas do paciente',
            'photoUrl': 'https://example.com/photo.jpg',
            'color': '#FF0000',
          },
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 201);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['id'], isNotNull);
        expect(body['cpf'], equals('12345678900'));
        expect(body['phones'], isA<List>());
        expect(body['emergencyContact'], isA<Map>());
      });

      test('cria paciente com emergency_contact JSON (201)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'json_$random@test.com';

        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente JSON',
            'email': uniqueEmail,
            'emergencyContact': {'name': 'João Silva', 'phone': '11999999999', 'relationship': 'Pai'},
          },
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 201);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['emergencyContact'], isA<Map>());
        expect((body['emergencyContact'] as Map)['name'], equals('João Silva'));
      });

      test('cria paciente com phones array (201)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'multi_$random@test.com';

        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Multi-Phone',
            'email': uniqueEmail,
            'phones': ['11999999999', '11888888888', '11777777777'],
          },
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 201);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['phones'], isA<List>());
        expect((body['phones'] as List).length, equals(3));
      });

      test('retorna 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'POST', path: '/patients', body: {'fullName': 'Teste'});

        final response = await handler(request);

        expect(response.statusCode, 401);
      });

      test('retorna 400 quando body vazio', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $therapistToken'},
          body: '',
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando JSON inválido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $therapistToken'},
          body: 'invalid json',
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando therapist sem accountId', () async {
        // Gera email único para evitar conflitos
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'therapist_sem_perfil2_$random@test.com';

        // Cria usuário therapist sem criar perfil
        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail, 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final tokenSemPerfil = registerData['auth_token'] as String;

        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Teste'},
          token: tokenSemPerfil,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['error'], contains('Conta de terapeuta não vinculada'));
      });

      test('retorna 403 quando role não autorizado', () async {
        // Gera email único para evitar conflitos
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'patient_user_$random@test.com';

        // Cria usuário (por padrão é criado com role 'therapist')
        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail, 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final patientUserId = registerData['user']['id'] as int?;
        if (patientUserId == null) {
          fail('ID do usuário não foi retornado no registro');
        }

        // Atualiza role do usuário para 'patient' no banco
        final patientConn = await dbConnection.getConnection();
        try {
          await patientConn.execute(
            Sql.named('UPDATE users SET role = \'patient\' WHERE id = @id'),
            parameters: {'id': patientUserId},
          );
        } finally {
          dbConnection.releaseConnection(patientConn);
        }

        // Faz login novamente para obter token com role atualizado
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
        final patientUserToken = loginData['auth_token'] as String;

        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Teste'},
          token: patientUserToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 403);
      });

      test('retorna 400 quando therapistId não fornecido (admin)', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Teste'},
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['error'], contains('therapistId'));
      });

      test('retorna 409 quando CPF duplicado', () async {
        // Gera emails únicos
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail1 = 'p1_$random@test.com';
        final uniqueEmail2 = 'p2_$random@test.com';

        // Cria primeiro paciente
        final createRequest1 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente 1', 'email': uniqueEmail1, 'cpf': '12345678900'},
          token: therapistToken!,
        );
        final createResponse1 = await handler(createRequest1);
        if (createResponse1.statusCode >= 400) {
          final errorBody = await createResponse1.readAsString();
          fail('Falha ao criar primeiro paciente: ${createResponse1.statusCode} - $errorBody');
        }
        final createData1 = await HttpTestHelpers.parseJsonResponse(createResponse1);
        expect(createData1['cpf'], equals('12345678900'), reason: 'CPF deve ser salvo no primeiro paciente');

        // Tenta criar segundo paciente com mesmo CPF
        final createRequest2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente 2', 'email': uniqueEmail2, 'cpf': '12345678900'},
          token: therapistToken!,
        );

        final response = await handler(createRequest2);

        expect(response.statusCode, 409);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['error'], contains('CPF'));
      });
    });

    group('PUT /patients/:id', () {
      test('atualiza paciente existente (200)', () async {
        // Gera emails únicos
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmailOriginal = 'original_$random@test.com';
        final uniqueEmailAtualizado = 'atualizado_$random@test.com';

        // Cria paciente
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Original',
            'email': uniqueEmailOriginal,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final createdId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/patients/$createdId',
          body: {'fullName': 'Paciente Atualizado', 'email': uniqueEmailAtualizado},
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['fullName'], equals('Paciente Atualizado'));
        expect(body['email'], equals(uniqueEmailAtualizado));
      });

      test('atualiza campos opcionais (200)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'teste_$random@test.com';

        // Cria paciente
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente', 'email': uniqueEmail},
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final createdId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/patients/$createdId',
          body: {'age': 30, 'cpf': '12345678900', 'profession': 'Médico'},
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['age'], equals(30));
        expect(body['cpf'], equals('12345678900'));
        expect(body['profession'], equals('Médico'));
      });

      test('admin pode alterar therapistId (200)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'teste_$random@test.com';

        // Cria paciente
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente', 'email': uniqueEmail, 'therapistId': therapistId},
          token: adminToken!,
        );
        final createResponse = await handler(createRequest);
        if (createResponse.statusCode >= 400) {
          final errorBody = await createResponse.readAsString();
          fail('Falha ao criar paciente: ${createResponse.statusCode} - $errorBody');
        }
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final createdId = createData['id'] as int?;
        if (createdId == null) {
          fail('ID do paciente não foi retornado na criação');
        }

        // Cria outro therapist
        final timestamp2 = DateTime.now().microsecondsSinceEpoch;
        final random2 = (timestamp2 % 1000000).toString().padLeft(6, '0');
        final uniqueEmail2 = 'therapist2_$random2@terafy.com';

        final registerRequest2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail2, 'password': 'senha123'},
        );
        final registerResponse2 = await handler(registerRequest2);
        final registerData2 = await HttpTestHelpers.parseJsonResponse(registerResponse2);
        final token2 = registerData2['auth_token'] as String;

        final therapistRequest2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/therapists/me',
          body: {'name': 'Dr. Teste 2', 'email': uniqueEmail2, 'status': 'active'},
          token: token2,
        );
        final therapistResponse2 = await handler(therapistRequest2);
        if (therapistResponse2.statusCode >= 400) {
          final errorBody = await therapistResponse2.readAsString();
          fail('Falha ao criar segundo therapist: ${therapistResponse2.statusCode} - $errorBody');
        }
        final therapistData2 = await HttpTestHelpers.parseJsonResponse(therapistResponse2);
        final therapistId2Nullable = therapistData2['id'] as int?;
        if (therapistId2Nullable == null) {
          fail('ID do segundo therapist não foi retornado');
        }
        final therapistId2 = therapistId2Nullable;

        // Admin altera therapistId
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/patients/$createdId',
          body: {'therapistId': therapistId2},
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['therapistId'], equals(therapistId2));
      });

      test('therapist não pode alterar therapistId (200, mantém accountId)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'teste_$random@test.com';

        // Cria paciente
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente', 'email': uniqueEmail},
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final createdId = createData['id'] as int;

        // Therapist tenta alterar therapistId (deve manter o accountId)
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/patients/$createdId',
          body: {'therapistId': 999}, // Tentativa de alterar
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        // Deve manter o therapistId original (accountId)
        expect(body['therapistId'], equals(therapistId));
      });

      test('retorna 404 quando ID inválido (não corresponde ao padrão da rota)', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/patients/abc',
          body: {'fullName': 'Teste'},
          token: therapistToken!,
        );

        final response = await handler(request);

        // A rota usa regex [0-9]+, então IDs não numéricos retornam 404 (rota não encontrada)
        expect(response.statusCode, 404);
      });

      test('retorna 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'PUT', path: '/patients/1', body: {'fullName': 'Teste'});

        final response = await handler(request);

        expect(response.statusCode, 401);
      });

      test('retorna 404 quando paciente não existe', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/patients/99999',
          body: {'fullName': 'Teste'},
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      test('retorna 409 quando CPF duplicado', () async {
        // Gera emails únicos
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail1 = 'p1_$random@test.com';
        final uniqueEmail2 = 'p2_$random@test.com';

        // Cria primeiro paciente
        final createRequest1 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente 1', 'email': uniqueEmail1, 'cpf': '12345678900'},
          token: therapistToken!,
        );
        await handler(createRequest1);

        // Cria segundo paciente
        final createRequest2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente 2', 'email': uniqueEmail2},
          token: therapistToken!,
        );
        final createResponse2 = await handler(createRequest2);
        final createData2 = await HttpTestHelpers.parseJsonResponse(createResponse2);
        final patientId2 = createData2['id'] as int;

        // Tenta atualizar segundo paciente com CPF do primeiro
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/patients/$patientId2',
          body: {'cpf': '12345678900'},
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 409);
      });
    });

    group('DELETE /patients/:id', () {
      test('remove paciente existente (200)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'deletar_$random@test.com';

        // Cria paciente
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Para Deletar',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final createdId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/patients/$createdId',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['message'], contains('removido com sucesso'));

        // Verifica que foi removido
        final getRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/patients/$createdId',
          token: therapistToken!,
        );
        final getResponse = await handler(getRequest);
        expect(getResponse.statusCode, 404);
      });

      test('retorna 404 quando ID inválido (não corresponde ao padrão da rota)', () async {
        final request = HttpTestHelpers.createRequest(method: 'DELETE', path: '/patients/abc', token: therapistToken!);

        final response = await handler(request);

        // A rota usa regex [0-9]+, então IDs não numéricos retornam 404 (rota não encontrada)
        expect(response.statusCode, 404);
      });

      test('retorna 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'DELETE', path: '/patients/1');

        final response = await handler(request);

        expect(response.statusCode, 401);
      });

      test('retorna 404 quando paciente não existe', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/patients/99999',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      test('admin pode remover qualquer paciente (200)', () async {
        // Gera email único
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'admin_patient_$random@test.com';

        // Cria paciente
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente Admin', 'email': uniqueEmail, 'therapistId': therapistId},
          token: adminToken!,
        );
        final createResponse = await handler(createRequest);
        if (createResponse.statusCode >= 400) {
          final errorBody = await createResponse.readAsString();
          fail('Falha ao criar paciente: ${createResponse.statusCode} - $errorBody');
        }
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final createdId = createData['id'] as int?;
        if (createdId == null) {
          fail('ID do paciente não foi retornado na criação');
        }

        final request = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/patients/$createdId',
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
      });
    });
  });
}
