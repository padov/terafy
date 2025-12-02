import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import '../../helpers/integration_test_db.dart';
import '../../helpers/test_server_setup.dart';
import '../../helpers/http_test_helpers.dart';

void main() {
  group('Schedule API Integration Tests', () {
    late Handler handler;
    late TestDBConnection dbConnection;
    String? therapistToken;
    String? adminToken;
    int? therapistId;

    // Helper para criar usuário com role 'patient' e obter token
    Future<String> createPatientUserToken(String email) async {
      final registerRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/register',
        body: {'email': email, 'password': 'senha123'},
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
        body: {'email': email, 'password': 'senha123'},
      );
      final loginResponse = await handler(loginRequest);
      if (loginResponse.statusCode >= 400) {
        final errorBody = await loginResponse.readAsString();
        fail('Falha no login: ${loginResponse.statusCode} - $errorBody');
      }
      final loginData = await HttpTestHelpers.parseJsonResponse(loginResponse);
      return loginData['auth_token'] as String;
    }

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
      adminToken = registerAdminData['auth_token'] as String?;
      if (adminToken == null) {
        fail('Token de autenticação não foi retornado no registro do admin');
      }

      // Atualiza role para admin
      await IntegrationTestDB.makeUserAdmin(uniqueAdminEmail);

      // Re-faz login para obter token com role admin
      final adminLoginRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/login',
        body: {'email': uniqueAdminEmail, 'password': 'senha123'},
      );
      final adminLoginResponse = await handler(adminLoginRequest);
      final adminLoginData = await HttpTestHelpers.parseJsonResponse(adminLoginResponse);
      adminToken = adminLoginData['auth_token'] as String?;
    });

    tearDown(() async {
      await IntegrationTestDB.cleanDatabase();
    });

    tearDownAll(() async {
      await TestDBConnection.closeAllConnections();
    });

    group('GET /schedule/settings', () {
      test('retorna configurações padrão quando não existem', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/settings',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data, isA<Map>());
        expect(data['sessionDurationMinutes'], 50);
        expect(data['breakMinutes'], 10);
      });

      test('retorna configurações existentes', () async {
        // Primeiro cria configurações
        final updateRequest = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/settings',
          body: {'sessionDurationMinutes': 60, 'breakMinutes': 15},
          token: therapistToken!,
        );
        await handler(updateRequest);

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/settings',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['sessionDurationMinutes'], 60);
        expect(data['breakMinutes'], 15);
      });

      test('admin pode consultar qualquer therapist', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/settings?therapistId=$therapistId',
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['therapistId'], therapistId);
      });

      test('admin precisa fornecer therapistId', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/schedule/settings', token: adminToken!);

        final response = await handler(request);

        expect(response.statusCode, 400);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['error'], contains('therapistId'));
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'therapist_sem_perfil_$random@test.com';

        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail, 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final tokenSemPerfil = registerData['auth_token'] as String;

        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/schedule/settings', token: tokenSemPerfil);

        final response = await handler(request);

        expect(response.statusCode, 400);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['error'], contains('Conta de terapeuta não vinculada'));
      });

      test('retorna 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/schedule/settings');

        final response = await handler(request);
        expect(response.statusCode, 401);
      });

      test('retorna 403 quando role não autorizado', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'patient_user_$random@test.com';

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
          method: 'GET',
          path: '/schedule/settings',
          token: patientUserToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 403);
      });
    });

    group('PUT /schedule/settings', () {
      test('atualiza configurações com sucesso', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/settings',
          body: {'sessionDurationMinutes': 60, 'breakMinutes': 15, 'reminderEnabled': false},
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['sessionDurationMinutes'], 60);
        expect(data['breakMinutes'], 15);
        expect(data['reminderEnabled'], false);
      });

      test('cria configurações se não existirem', () async {
        // O setUp já limpa o banco, então as configurações não existem
        // Este teste verifica que podemos criar/atualizar configurações mesmo quando não existem
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/settings',
          body: {'sessionDurationMinutes': 45},
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['sessionDurationMinutes'], 45);
      });

      test('admin pode atualizar qualquer therapist', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/settings',
          body: {'therapistId': therapistId, 'sessionDurationMinutes': 90},
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['therapistId'], therapistId);
        expect(data['sessionDurationMinutes'], 90);
      });

      test('admin precisa fornecer therapistId', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/settings',
          body: {'sessionDurationMinutes': 60},
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['error'], contains('therapistId'));
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'therapist_sem_perfil2_$random@test.com';

        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail, 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final tokenSemPerfil = registerData['auth_token'] as String;

        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/settings',
          body: {'sessionDurationMinutes': 60},
          token: tokenSemPerfil,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando body vazio', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/schedule/settings'),
          body: '',
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${therapistToken!}'},
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando JSON inválido', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/schedule/settings'),
          body: 'invalid json',
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${therapistToken!}'},
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/settings',
          body: {'sessionDurationMinutes': 60},
        );

        final response = await handler(request);

        expect(response.statusCode, 401);
      });

      test('retorna 403 quando role não autorizado', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'patient_user2_$random@test.com';

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
          method: 'PUT',
          path: '/schedule/settings',
          body: {'sessionDurationMinutes': 60},
          token: patientUserToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 403);
      });
    });

    group('GET /schedule/appointments', () {
      test('lista agendamentos do therapist', () async {
        // Cria um agendamento primeiro
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'p1_$random@test.com';

        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Teste',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
          token: therapistToken!,
        );
        await handler(createRequest);

        final start = DateTime.now();
        final end = start.add(const Duration(days: 7));
        final startStr = Uri.encodeComponent(start.toIso8601String());
        final endStr = Uri.encodeComponent(end.toIso8601String());

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments?start=$startStr&end=$endStr',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isA<List>());
        expect(data.length, greaterThanOrEqualTo(1));
      });

      test('filtra por intervalo de datas', () async {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final startStr = Uri.encodeComponent(start.toIso8601String());
        final endStr = Uri.encodeComponent(end.toIso8601String());

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments?start=$startStr&end=$endStr',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isA<List>());
      });

      test('admin pode listar de qualquer therapist', () async {
        final start = DateTime.now();
        final end = start.add(const Duration(days: 7));
        final startStr = Uri.encodeComponent(start.toIso8601String());
        final endStr = Uri.encodeComponent(end.toIso8601String());

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments?therapistId=$therapistId&start=$startStr&end=$endStr',
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isA<List>());
      });

      test('admin precisa fornecer therapistId', () async {
        final start = DateTime.now();
        final end = start.add(const Duration(days: 7));
        final startStr = Uri.encodeComponent(start.toIso8601String());
        final endStr = Uri.encodeComponent(end.toIso8601String());

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments?start=$startStr&end=$endStr',
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['error'], contains('therapistId'));
      });

      test('retorna lista vazia quando não há agendamentos', () async {
        final start = DateTime(2025, 1, 1);
        final end = DateTime(2025, 1, 31);
        final startStr = Uri.encodeComponent(start.toIso8601String());
        final endStr = Uri.encodeComponent(end.toIso8601String());

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments?start=$startStr&end=$endStr',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isEmpty);
      });

      test('retorna 400 quando start/end não fornecidos', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['error'], contains('start e end são obrigatórios'));
      });

      test('retorna 400 quando intervalo inválido', () async {
        final start = DateTime(2024, 1, 31);
        final end = DateTime(2024, 1, 1);
        final startStr = Uri.encodeComponent(start.toIso8601String());
        final endStr = Uri.encodeComponent(end.toIso8601String());

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments?start=$startStr&end=$endStr',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['error'], contains('Intervalo de datas inválido'));
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'therapist_sem_perfil3_$random@test.com';

        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail, 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final tokenSemPerfil = registerData['auth_token'] as String;

        final start = DateTime.now();
        final end = start.add(const Duration(days: 7));
        final startStr = Uri.encodeComponent(start.toIso8601String());
        final endStr = Uri.encodeComponent(end.toIso8601String());

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments?start=$startStr&end=$endStr',
          token: tokenSemPerfil,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 401 sem autenticação', () async {
        final start = DateTime.now();
        final end = start.add(const Duration(days: 7));
        final startStr = Uri.encodeComponent(start.toIso8601String());
        final endStr = Uri.encodeComponent(end.toIso8601String());

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments?start=$startStr&end=$endStr',
        );

        final response = await handler(request);

        expect(response.statusCode, 401);
      });

      test('retorna 403 quando role não autorizado', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'patient_user3_$random@test.com';

        final patientUserToken = await createPatientUserToken(uniqueEmail);

        final start = DateTime.now();
        final end = start.add(const Duration(days: 7));
        final startStr = Uri.encodeComponent(start.toIso8601String());
        final endStr = Uri.encodeComponent(end.toIso8601String());

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments?start=$startStr&end=$endStr',
          token: patientUserToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 403);
      });
    });

    group('GET /schedule/appointments/:id', () {
      test('retorna agendamento existente', () async {
        // Cria agendamento
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'get_$random@test.com';

        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Get',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final appointmentId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments/$appointmentId',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], appointmentId);
      });

      test('retorna 404 quando não existe', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments/99999',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      test('retorna 404 quando ID não numérico (rota não encontrada)', () async {
        // A rota usa regex [0-9]+ então IDs não numéricos retornam 404
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments/abc',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      test('therapist só acessa seus agendamentos', () async {
        // Cria outro therapist
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail2 = 'therapist2_$random@terafy.com';

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
          body: {'name': 'Dr. Outro', 'email': uniqueEmail2, 'status': 'active'},
          token: token2,
        );
        await handler(therapistRequest2);

        final loginRequest2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/login',
          body: {'email': uniqueEmail2, 'password': 'senha123'},
        );
        final loginResponse2 = await handler(loginRequest2);
        final loginData2 = await HttpTestHelpers.parseJsonResponse(loginResponse2);
        final token2Updated = loginData2['auth_token'] as String;

        // Cria agendamento para o outro therapist
        final uniqueEmailP = 'p_outro_$random@test.com';
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Outro',
            'email': uniqueEmailP,
            'phones': ['11999999999'],
          },
          token: token2Updated,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
          token: token2Updated,
        );
        final createResponse = await handler(createRequest);
        expect(createResponse.statusCode, 201, reason: 'Agendamento do segundo therapist deve ser criado');
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final otherAppointmentId = createData['id'] as int;
        final otherAppointmentTherapistId = createData['therapistId'] as int;

        // Verifica que o therapist original tem accountId configurado
        expect(therapistId, isNotNull, reason: 'Therapist original deve ter accountId configurado');
        expect(
          otherAppointmentTherapistId,
          isNot(equals(therapistId)),
          reason:
              'Os therapists devem ter IDs diferentes. '
              'Therapist original: $therapistId, Segundo therapist: $otherAppointmentTherapistId',
        );

        // Therapist original não deve conseguir acessar (RLS bloqueia)
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments/$otherAppointmentId',
          token: therapistToken!,
        );

        final response = await handler(request);

        // RLS bloqueia o acesso, então o agendamento não é encontrado (404)
        // Se o RLS não estiver funcionando, pode retornar 200, então verificamos >= 400
        expect(
          response.statusCode,
          greaterThanOrEqualTo(400),
          reason:
              'Therapist não deve conseguir acessar agendamento de outro therapist. '
              'Agendamento criado com therapistId=$otherAppointmentTherapistId, '
              'therapist original tem accountId=$therapistId. '
              'Status recebido: ${response.statusCode}. '
              'Se recebeu 200, o RLS não está bloqueando corretamente.',
        );

        if (response.statusCode == 404) {
          final data = await HttpTestHelpers.parseJsonResponse(response);
          expect(data['error'], contains('não encontrado'));
        } else if (response.statusCode == 200) {
          // Se recebeu 200, o RLS não está funcionando - vamos verificar o conteúdo
          final data = await HttpTestHelpers.parseJsonResponse(response);
          // Se o RLS não estiver funcionando, o agendamento será retornado mesmo assim
          // Mas isso não deveria acontecer, então falhamos o teste
          fail(
            'RLS não está bloqueando acesso. '
            'Therapist com accountId=$therapistId conseguiu acessar agendamento '
            'com therapistId=$otherAppointmentTherapistId. '
            'Dados retornados: ${data.toString()}',
          );
        }
      });

      test('admin acessa qualquer agendamento', () async {
        // Cria agendamento
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'admin_patient_$random@test.com';

        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Admin',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final appointmentId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments/$appointmentId',
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], appointmentId);
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'therapist_sem_perfil4_$random@test.com';

        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail, 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final tokenSemPerfil = registerData['auth_token'] as String;

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments/1',
          token: tokenSemPerfil,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/schedule/appointments/1');

        final response = await handler(request);

        expect(response.statusCode, 401);
      });

      test('retorna 403 quando role não autorizado', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'patient_user4_$random@test.com';

        final patientUserToken = await createPatientUserToken(uniqueEmail);

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments/1',
          token: patientUserToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 403);
      });
    });

    group('POST /schedule/appointments', () {
      test('cria agendamento com sucesso', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'novo_$random@test.com';

        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Novo',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 201);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], isNotNull);
        expect(data['patientId'], patientId);
      });

      test('cria agendamento com todos os campos', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'completo_$random@test.com';

        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Completo',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
            'title': 'Sessão Completa',
            'description': 'Descrição da sessão',
            'location': 'Consultório 1',
            'onlineLink': 'https://meet.example.com/room',
            'color': '#FF0000',
            'notes': 'Notas do agendamento',
          },
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 201);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['title'], 'Sessão Completa');
        expect(data['description'], 'Descrição da sessão');
        expect(data['location'], 'Consultório 1');
      });

      test('admin pode criar para qualquer therapist', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'admin_patient2_$random@test.com';

        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Admin',
            'email': uniqueEmail,
            'phones': ['11999999999'],
            'therapistId': therapistId,
          },
          token: adminToken!,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'therapistId': therapistId,
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 201);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], isNotNull);
      });

      test('admin precisa fornecer therapistId', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': 1,
            'startTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'endTime': DateTime.now().add(const Duration(days: 1, hours: 1)).toIso8601String(),
          },
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['error'], contains('therapistId'));
      });

      test('retorna 400 quando body vazio', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/schedule/appointments'),
          body: '',
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${therapistToken!}'},
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando JSON inválido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/schedule/appointments'),
          body: 'invalid json',
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${therapistToken!}'},
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'therapist_sem_perfil5_$random@test.com';

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
          path: '/schedule/appointments',
          body: {'patientId': 1},
          token: tokenSemPerfil,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {'patientId': 1},
        );

        final response = await handler(request);

        expect(response.statusCode, 401);
      });

      test('retorna 403 quando role não autorizado', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'patient_user5_$random@test.com';

        final patientUserToken = await createPatientUserToken(uniqueEmail);

        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {'patientId': 1},
          token: patientUserToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 403);
      });

      // TODO: revisar
      // test('retorna 409 quando há conflito de horário', () async {
      //   final timestamp = DateTime.now().microsecondsSinceEpoch;
      //   final random = (timestamp % 1000000).toString().padLeft(6, '0');
      //   final uniqueEmail = 'conflito_$random@test.com';

      //   final patientRequest = HttpTestHelpers.createRequest(
      //     method: 'POST',
      //     path: '/patients',
      //     body: {
      //       'fullName': 'Paciente Conflito',
      //       'email': uniqueEmail,
      //       'phones': ['11999999999'],
      //     },
      //     token: therapistToken!,
      //   );
      //   final patientResponse = await handler(patientRequest);
      //   final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
      //   final patientId = patientData['id'] as int;

      //   final startTime = DateTime.now().add(const Duration(days: 1, hours: 10));
      //   final endTime = startTime.add(const Duration(hours: 1));

      //   // Cria primeiro agendamento
      //   final createRequest1 = HttpTestHelpers.createRequest(
      //     method: 'POST',
      //     path: '/schedule/appointments',
      //     body: {
      //       'patientId': patientId,
      //       'startTime': startTime.toIso8601String(),
      //       'endTime': endTime.toIso8601String(),
      //       'type': 'session',
      //       'status': 'reserved',
      //     },
      //     token: therapistToken!,
      //   );
      //   final response1 = await handler(createRequest1);
      //   expect(response1.statusCode, 201, reason: 'Primeiro agendamento deve ser criado com sucesso');

      //   // Tenta criar segundo agendamento com exatamente os mesmos horários do primeiro
      //   // Isso cria uma sobreposição clara: mesmo start_time e end_time
      //   final createRequest2 = HttpTestHelpers.createRequest(
      //     method: 'POST',
      //     path: '/schedule/appointments',
      //     body: {
      //       'patientId': patientId,
      //       'startTime': startTime.toIso8601String(), // Mesmo horário do primeiro
      //       'endTime': endTime.toIso8601String(), // Mesmo horário do primeiro
      //       'type': 'session',
      //       'status': 'reserved',
      //     },
      //     token: therapistToken!,
      //   );

      //   final response = await handler(createRequest2);

      //   expect(response.statusCode, 409, reason: 'Deve retornar 409 quando há conflito de horário');
      //   final data = await HttpTestHelpers.parseJsonResponse(response);
      //   expect(data['error'], contains('horário'));
      // });
    });

    group('PUT /schedule/appointments/:id', () {
      test('atualiza agendamento existente', () async {
        // Cria agendamento
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'update_$random@test.com';

        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Update',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final appointmentId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/appointments/$appointmentId',
          body: {
            'status': 'confirmed',
            'notes': 'Notas atualizadas',
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
          },
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['status'], 'confirmed');
        expect(data['notes'], 'Notas atualizadas');
      });

      test('atualiza campos opcionais', () async {
        // Cria agendamento
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'opcional_$random@test.com';

        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Opcional',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final appointmentId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/appointments/$appointmentId',
          body: {
            'title': 'Título Atualizado',
            'description': 'Descrição atualizada',
            'location': 'Novo Local',
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
          },
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['title'], 'Título Atualizado');
        expect(data['description'], 'Descrição atualizada');
        expect(data['location'], 'Novo Local');
      });

      test('admin pode atualizar qualquer agendamento', () async {
        // Cria agendamento
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'admin_update_$random@test.com';

        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Admin Update',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final appointmentId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/appointments/$appointmentId',
          body: {
            'therapistId': therapistId,
            'status': 'confirmed',
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
          },
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['status'], 'confirmed');
      });

      test('admin precisa fornecer therapistId', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/appointments/1',
          body: {
            'status': 'confirmed',
            'startTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'endTime': DateTime.now().add(const Duration(days: 1, hours: 1)).toIso8601String(),
          },
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['error'], contains('therapistId'));
      });

      test('retorna 404 quando ID não numérico (rota não encontrada)', () async {
        // A rota usa regex [0-9]+ então IDs não numéricos retornam 404
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/appointments/abc',
          body: {
            'status': 'confirmed',
            'startTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'endTime': DateTime.now().add(const Duration(days: 1, hours: 1)).toIso8601String(),
          },
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      test('retorna 400 quando body vazio', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/schedule/appointments/1'),
          body: '',
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${therapistToken!}'},
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando JSON inválido', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/schedule/appointments/1'),
          body: 'invalid json',
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${therapistToken!}'},
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'therapist_sem_perfil6_$random@test.com';

        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail, 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final tokenSemPerfil = registerData['auth_token'] as String;

        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/appointments/1',
          body: {
            'status': 'confirmed',
            'startTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'endTime': DateTime.now().add(const Duration(days: 1, hours: 1)).toIso8601String(),
          },
          token: tokenSemPerfil,
        );

        final response = await handler(request);

        expect(response.statusCode, 400);
      });

      test('retorna 404 quando não existe', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/appointments/99999',
          body: {
            'status': 'confirmed',
            'startTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'endTime': DateTime.now().add(const Duration(days: 1, hours: 1)).toIso8601String(),
          },
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      test('retorna 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/appointments/1',
          body: {
            'status': 'confirmed',
            'startTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'endTime': DateTime.now().add(const Duration(days: 1, hours: 1)).toIso8601String(),
          },
        );

        final response = await handler(request);

        expect(response.statusCode, 401);
      });

      test('retorna 403 quando role não autorizado', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'patient_user6_$random@test.com';

        final patientUserToken = await createPatientUserToken(uniqueEmail);

        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/schedule/appointments/1',
          body: {
            'status': 'confirmed',
            'startTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'endTime': DateTime.now().add(const Duration(days: 1, hours: 1)).toIso8601String(),
          },
          token: patientUserToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 403);
      });

      // TODO: revisar
      // test('retorna 409 quando há conflito de horário', () async {
      //   // Cria dois agendamentos
      //   final timestamp = DateTime.now().microsecondsSinceEpoch;
      //   final random = (timestamp % 1000000).toString().padLeft(6, '0');
      //   final uniqueEmail1 = 'conflito1_$random@test.com';
      //   final uniqueEmail2 = 'conflito2_$random@test.com';

      //   final patientRequest1 = HttpTestHelpers.createRequest(
      //     method: 'POST',
      //     path: '/patients',
      //     body: {
      //       'fullName': 'Paciente 1',
      //       'email': uniqueEmail1,
      //       'phones': ['11999999999'],
      //     },
      //     token: therapistToken!,
      //   );
      //   final patientResponse1 = await handler(patientRequest1);
      //   final patientData1 = await HttpTestHelpers.parseJsonResponse(patientResponse1);
      //   final patientId1 = patientData1['id'] as int;

      //   final patientRequest2 = HttpTestHelpers.createRequest(
      //     method: 'POST',
      //     path: '/patients',
      //     body: {
      //       'fullName': 'Paciente 2',
      //       'email': uniqueEmail2,
      //       'phones': ['11999999999'],
      //     },
      //     token: therapistToken!,
      //   );
      //   final patientResponse2 = await handler(patientRequest2);
      //   final patientData2 = await HttpTestHelpers.parseJsonResponse(patientResponse2);
      //   final patientId2 = patientData2['id'] as int;

      //   final startTime1 = DateTime.now().add(const Duration(days: 1, hours: 10));
      //   final endTime1 = startTime1.add(const Duration(hours: 1));

      //   final startTime2 = DateTime.now().add(const Duration(days: 1, hours: 12));
      //   final endTime2 = startTime2.add(const Duration(hours: 1));

      //   // Cria primeiro agendamento
      //   final createRequest1 = HttpTestHelpers.createRequest(
      //     method: 'POST',
      //     path: '/schedule/appointments',
      //     body: {
      //       'patientId': patientId1,
      //       'startTime': startTime1.toIso8601String(),
      //       'endTime': endTime1.toIso8601String(),
      //       'type': 'session',
      //       'status': 'reserved',
      //     },
      //     token: therapistToken!,
      //   );
      //   final createResponse1 = await handler(createRequest1);
      //   final createData1 = await HttpTestHelpers.parseJsonResponse(createResponse1);
      //   final appointmentId1 = createData1['id'] as int;

      //   // Cria segundo agendamento
      //   final createRequest2 = HttpTestHelpers.createRequest(
      //     method: 'POST',
      //     path: '/schedule/appointments',
      //     body: {
      //       'patientId': patientId2,
      //       'startTime': startTime2.toIso8601String(),
      //       'endTime': endTime2.toIso8601String(),
      //       'type': 'session',
      //       'status': 'reserved',
      //     },
      //     token: therapistToken!,
      //   );
      //   final createResponse2 = await handler(createRequest2);
      //   expect(createResponse2.statusCode, 201, reason: 'Segundo agendamento deve ser criado com sucesso');

      //   // Tenta atualizar primeiro agendamento para conflitar com o segundo
      //   // O segundo agendamento vai de startTime2 (12:00) até endTime2 (13:00)
      //   // Vamos atualizar o primeiro para começar exatamente no mesmo horário do segundo
      //   // Isso cria uma sobreposição clara: mesmo start_time e end_time
      //   final request = HttpTestHelpers.createRequest(
      //     method: 'PUT',
      //     path: '/schedule/appointments/$appointmentId1',
      //     body: {
      //       'startTime': startTime2.toIso8601String(), // Mesmo horário do segundo
      //       'endTime': endTime2.toIso8601String(), // Mesmo horário do segundo
      //       'status': 'reserved', // Mantém status
      //       'type': 'session', // Mantém type
      //     },
      //     token: therapistToken!,
      //   );

      //   final response = await handler(request);

      //   expect(response.statusCode, 409, reason: 'Deve retornar 409 quando há conflito de horário');
      //   final data = await HttpTestHelpers.parseJsonResponse(response);
      //   expect(data['error'], contains('horário'));
      // });
    });

    group('DELETE /schedule/appointments/:id', () {
      test('remove agendamento existente', () async {
        // Cria agendamento
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'delete_$random@test.com';

        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Delete',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final appointmentId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/schedule/appointments/$appointmentId',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['message'], contains('removido com sucesso'));

        // Verifica que foi removido
        final getRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/schedule/appointments/$appointmentId',
          token: therapistToken!,
        );
        final getResponse = await handler(getRequest);
        expect(getResponse.statusCode, 404);
      });

      test('admin pode remover qualquer agendamento', () async {
        // Cria agendamento
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'admin_delete_$random@test.com';

        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Admin Delete',
            'email': uniqueEmail,
            'phones': ['11999999999'],
          },
          token: therapistToken!,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 1));
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          body: {
            'patientId': patientId,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
          token: therapistToken!,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final appointmentId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/schedule/appointments/$appointmentId',
          token: adminToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
      });

      test('retorna 404 quando ID não numérico (rota não encontrada)', () async {
        // A rota usa regex [0-9]+ então IDs não numéricos retornam 404
        final request = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/schedule/appointments/abc',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      test('retorna 404 quando não existe', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/schedule/appointments/99999',
          token: therapistToken!,
        );

        final response = await handler(request);

        expect(response.statusCode, 404);
      });

      test('retorna 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'DELETE', path: '/schedule/appointments/1');

        final response = await handler(request);

        expect(response.statusCode, 401);
      });

      test('retorna 403 quando role não autorizado', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'patient_user7_$random@test.com';

        final patientUserToken = await createPatientUserToken(uniqueEmail);

        final request = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/schedule/appointments/1',
          token: patientUserToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 403);
      });
    });
  });
}
