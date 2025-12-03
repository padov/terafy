import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import '../../helpers/integration_test_db.dart';
import '../../helpers/test_server_setup.dart';
import '../../helpers/http_test_helpers.dart';

void main() {
  group('Home API Integration Tests', () {
    late Handler handler;
    late TestDBConnection dbConnection;
    late String therapistToken;
    late String adminToken;
    late int therapistId;

    setUpAll(() async {
      await TestServerSetup.setup();
    });

    setUp(() async {
      await IntegrationTestDB.cleanDatabase();
      dbConnection = TestDBConnection();
      handler = TestServerSetup.createTestHandler(dbConnection);

      // Cria usuário terapeuta
      final therapistRegisterRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/register',
        body: {'email': 'therapist@terafy.com', 'password': 'senha123'},
      );
      final therapistRegisterResponse = await handler(therapistRegisterRequest);
      final therapistData = await HttpTestHelpers.parseJsonResponse(therapistRegisterResponse);
      therapistToken = therapistData['auth_token'] as String;

      // Cria perfil de terapeuta
      final createTherapistRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/therapists/me',
        token: therapistToken,
        body: {'name': 'Dr. Terapeuta Teste', 'email': 'therapist@terafy.com', 'phone': '11999999999'},
      );
      final createTherapistResponse = await handler(createTherapistRequest);
      final therapistProfile = await HttpTestHelpers.parseJsonResponse(createTherapistResponse);
      therapistId = therapistProfile['id'] as int;

      // Faz login novamente para atualizar o token com o accountId (therapistId)
      final loginRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/login',
        body: {'email': 'therapist@terafy.com', 'password': 'senha123'},
      );
      final loginResponse = await handler(loginRequest);
      final loginData = await HttpTestHelpers.parseJsonResponse(loginResponse);
      therapistToken = loginData['auth_token'] as String;

      // Cria usuário admin
      final adminRegisterRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/register',
        body: {'email': 'admin@terafy.com', 'password': 'senha123'},
      );
      final adminRegisterResponse = await handler(adminRegisterRequest);
      final adminData = await HttpTestHelpers.parseJsonResponse(adminRegisterResponse);
      adminToken = adminData['auth_token'] as String;

      // TODO: Atualizar role do admin no banco (se necessário)
    });

    tearDown(() async {
      await IntegrationTestDB.cleanDatabase();
    });

    group('GET /home/summary', () {
      test('deve retornar resumo vazio quando não há dados', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/home/summary', token: therapistToken);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['therapistId'], therapistId);
        expect(data['todayPendingSessions'], 0);
        expect(data['todayConfirmedSessions'], 0);
        expect(data['monthlySessions'], 0);
        expect(data['monthlyCompletionRate'], 0.0);
        expect(data['listOfTodaySessions'], isEmpty);
        expect(data['pendingSessions'], isEmpty);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/home/summary');

        final response = await handler(request);
        expect(response.statusCode, 401);
      });

      test('deve retornar 400 quando therapist não tem perfil completo', () async {
        // Cria novo usuário sem perfil de terapeuta
        final newUserRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': 'newuser@terafy.com', 'password': 'senha123'},
        );
        final newUserResponse = await handler(newUserRequest);
        final newUserData = await HttpTestHelpers.parseJsonResponse(newUserResponse);
        final newUserToken = newUserData['auth_token'] as String;

        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/home/summary', token: newUserToken);

        final response = await handler(request);
        expect(response.statusCode, 400);
        final body = await response.readAsString();
        expect(body, contains('Conta de terapeuta não vinculada'));
      });

      test('deve aceitar parâmetro de data', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/home/summary?date=2024-02-15',
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['referenceDate'], contains('2024-02-15'));
      });

      test('deve retornar 400 quando data é inválida', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/home/summary?date=invalid-date',
          token: therapistToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 400);
        final body = await response.readAsString();
        expect(body, contains('Parâmetro de data inválido'));
      });

      test('deve retornar resumo com compromissos quando existem', () async {
        // Cria um paciente
        final createPatientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          token: therapistToken,
          body: {'full_name': 'Paciente Teste', 'email': 'paciente@teste.com', 'phone': '11988888888'},
        );
        final createPatientResponse = await handler(createPatientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(createPatientResponse);
        final patientId = patientData['id'] as int;

        // Cria um agendamento para hoje
        final now = DateTime.now();
        final startTime = DateTime(now.year, now.month, now.day, 10, 0);
        final endTime = startTime.add(const Duration(hours: 1));

        final createAppointmentRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/schedule/appointments',
          token: therapistToken,
          body: {
            'patientId': patientId,
            'type': 'session',
            'status': 'confirmed',
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
          },
        );
        await handler(createAppointmentRequest);

        // Busca resumo
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/home/summary', token: therapistToken);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['todayConfirmedSessions'], 1);
        expect(data['listOfTodaySessions'], hasLength(1));
        expect(data['listOfTodaySessions'][0]['patientName'], 'Paciente Teste');
        expect(data['listOfTodaySessions'][0]['status'], 'confirmed');
      });

      test('deve retornar sessões pendentes quando existem', () async {
        // Cria um paciente
        final createPatientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          token: therapistToken,
          body: {'full_name': 'Paciente Teste', 'email': 'paciente@teste.com', 'phone': '11988888888'},
        );
        final createPatientResponse = await handler(createPatientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(createPatientResponse);
        final patientId = patientData['id'] as int;

        // Cria uma sessão pendente (draft)
        final createSessionRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/sessions',
          token: therapistToken,
          body: {
            'patientId': patientId,
            'scheduledStartTime': DateTime.now().toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 1,
            'type': 'presential',
            'modality': 'individual',
            'status': 'draft',
            'paymentStatus': 'pending',
          },
        );
        await handler(createSessionRequest);

        // Busca resumo
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/home/summary', token: therapistToken);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['pendingSessions'], hasLength(1));
        expect(data['pendingSessions'][0]['patientName'], 'Paciente Teste');
        expect(data['pendingSessions'][0]['sessionNumber'], 1);
        expect(data['pendingSessions'][0]['status'], contains('draft'));
      });

      test('deve calcular taxa de conclusão mensal corretamente', () async {
        // Cria um paciente
        final createPatientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          token: therapistToken,
          body: {'full_name': 'Paciente Teste', 'email': 'paciente@teste.com', 'phone': '11988888888'},
        );
        final createPatientResponse = await handler(createPatientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(createPatientResponse);
        final patientId = patientData['id'] as int;

        // Cria 2 agendamentos completados e 1 pendente neste mês
        final now = DateTime.now();
        for (var i = 0; i < 3; i++) {
          final startTime = DateTime(now.year, now.month, i + 1, 10, 0);
          final endTime = startTime.add(const Duration(hours: 1));
          final status = i < 2 ? 'completed' : 'confirmed';

          final createAppointmentRequest = HttpTestHelpers.createRequest(
            method: 'POST',
            path: '/schedule/appointments',
            token: therapistToken,
            body: {
              'patientId': patientId,
              'type': 'session',
              'status': status,
              'startTime': startTime.toIso8601String(),
              'endTime': endTime.toIso8601String(),
            },
          );
          await handler(createAppointmentRequest);
        }

        // Busca resumo
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/home/summary', token: therapistToken);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['monthlySessions'], 3);
        expect(data['monthlyCompletionRate'], closeTo(0.67, 0.01)); // 2/3 ≈ 0.67
      });
    });
  });
}
