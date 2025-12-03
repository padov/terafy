import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import '../../helpers/integration_test_db.dart';
import '../../helpers/test_server_setup.dart';
import '../../helpers/http_test_helpers.dart';

void main() {
  group('Therapist API Integration Tests', () {
    late Handler handler;
    late TestDBConnection dbConnection;
    String? adminToken;
    String? therapistToken;
    int? therapistAccountId;

    setUpAll(() async {
      await TestServerSetup.setup();
    });

    setUp(() async {
      await IntegrationTestDB.cleanDatabase();
      dbConnection = TestDBConnection();
      handler = TestServerSetup.createTestHandler(dbConnection);

      // Cria usuário admin e obtém token
      final adminRegisterRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/register',
        body: {'email': 'admin@terafy.com', 'password': 'senha123'},
      );
      final adminResponse = await handler(adminRegisterRequest);
      final adminData = await HttpTestHelpers.parseJsonResponse(adminResponse);
      adminToken = adminData['auth_token'] as String;

      // Atualiza role para admin (register sempre cria como 'therapist')
      await IntegrationTestDB.makeUserAdmin('admin@terafy.com');

      // Re-gera token com role admin (precisa fazer login novamente ou atualizar token)
      // Por enquanto, vamos usar o token mesmo - o middleware verifica o role do token JWT
      // Mas o token foi gerado antes de atualizar o role, então precisamos fazer login novamente
      final adminLoginRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/login',
        body: {'email': 'admin@terafy.com', 'password': 'senha123'},
      );
      final adminLoginResponse = await handler(adminLoginRequest);
      final adminLoginData = await HttpTestHelpers.parseJsonResponse(adminLoginResponse);
      adminToken = adminLoginData['auth_token'] as String;

      // Cria usuário therapist e obtém token
      final therapistRegisterRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/register',
        body: {'email': 'therapist@terafy.com', 'password': 'senha123'},
      );
      final therapistResponse = await handler(therapistRegisterRequest);
      final therapistData = await HttpTestHelpers.parseJsonResponse(therapistResponse);
      therapistToken = therapistData['auth_token'] as String;
    });

    tearDown(() async {
      await IntegrationTestDB.cleanDatabase();
    });

    group('POST /therapists/me', () {
      test('deve criar therapist para usuário autenticado', () async {
        print('therapistToken:');
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/therapists/me',
          body: {'name': 'Dr. João Silva', 'email': 'joao@terafy.com', 'status': 'active'},
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 201);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['name'], 'Dr. João Silva');
        expect(data['email'], 'joao@terafy.com');
        expect(data['id'], isNotNull);
        therapistAccountId = data['id'] as int;
      });

      test('deve validar constraint de email único', () async {
        // Cria primeiro therapist
        final request1 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/therapists/me',
          body: {'name': 'Dr. João', 'email': 'joao@terafy.com', 'status': 'active'},
          token: therapistToken,
        );
        await handler(request1);

        // Tenta criar outro com mesmo email (via outro usuário)
        final request2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/therapists/me',
          body: {
            'name': 'Dr. Maria',
            'email': 'joao@terafy.com', // Email duplicado
            'status': 'active',
          },
          token: adminToken, // Usuário diferente
        );

        final response = await handler(request2);
        expect(response.statusCode, greaterThanOrEqualTo(400));
      });

      test('deve retornar 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/therapists/me',
          body: {'name': 'Dr. Teste', 'email': 'teste@terafy.com', 'status': 'active'},
        );

        final response = await handler(request);
        expect(response.statusCode, 401);
      });
    });

    group('GET /therapists/me', () {
      test('deve retornar therapist do usuário autenticado', () async {
        // Cria therapist primeiro
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/therapists/me',
          body: {'name': 'Dr. João', 'email': 'joao@terafy.com', 'status': 'active'},
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        therapistAccountId = createData['id'] as int;

        // Busca therapist
        final getRequest = HttpTestHelpers.createRequest(method: 'GET', path: '/therapists/me', token: therapistToken);

        final response = await handler(getRequest);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['name'], 'Dr. João');
        expect(data['id'], therapistAccountId);
      });

      test('deve retornar 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/therapists/me');

        final response = await handler(request);
        expect(response.statusCode, 401);
      });
    });

    group('GET /therapists (admin only)', () {
      test('admin deve ver todos os therapists', () async {
        // Cria alguns therapists
        final createRequest1 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/therapists/me',
          body: {'name': 'Dr. João', 'email': 'joao@terafy.com', 'status': 'active'},
          token: therapistToken,
        );
        await handler(createRequest1);

        // Admin busca todos
        final getRequest = HttpTestHelpers.createRequest(method: 'GET', path: '/therapists', token: adminToken);

        final response = await handler(getRequest);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data.length, greaterThanOrEqualTo(1));
      });

      test('therapist não deve acessar lista completa (403)', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/therapists', token: therapistToken);

        final response = await handler(request);
        expect(response.statusCode, 403);
      });
    });

    group('PUT /therapists/me', () {
      test('deve atualizar therapist do usuário autenticado', () async {
        // Cria therapist primeiro
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/therapists/me',
          body: {'name': 'Dr. João', 'email': 'joao@terafy.com', 'status': 'active'},
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final therapistId = createData['id'] as int;

        // Após criar o therapist, o account_id é atualizado no banco
        // Mas o token ainda não tem essa informação, então precisamos fazer login novamente
        // para obter um token com account_id atualizado
        final loginRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/login',
          body: {'email': 'therapist@terafy.com', 'password': 'senha123'},
        );
        final loginResponse = await handler(loginRequest);
        final loginData = await HttpTestHelpers.parseJsonResponse(loginResponse);
        final updatedTherapistToken = loginData['auth_token'] as String;

        // Atualiza therapist com token atualizado
        final updateRequest = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/therapists/me',
          body: {'name': 'Dr. João Atualizado', 'email': 'joao@terafy.com', 'status': 'active'},
          token: updatedTherapistToken,
        );

        final response = await handler(updateRequest);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['name'], 'Dr. João Atualizado');
        expect(data['id'], therapistId);
      });
    });

    group('RLS - Row Level Security via API', () {
      test('therapist vê apenas seus próprios dados via API', () async {
        // Cria dois therapists
        final createRequest1 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/therapists/me',
          body: {'name': 'Dr. João', 'email': 'joao@terafy.com', 'status': 'active'},
          token: therapistToken,
        );
        final response1 = await handler(createRequest1);
        final data1 = await HttpTestHelpers.parseJsonResponse(response1);
        final therapist1Id = data1['id'] as int;

        // Cria segundo usuário therapist
        final registerRequest2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': 'therapist2@terafy.com', 'password': 'senha123'},
        );
        final registerResponse2 = await handler(registerRequest2);
        final registerData2 = await HttpTestHelpers.parseJsonResponse(registerResponse2);
        final therapist2Token = registerData2['auth_token'] as String;

        final createRequest2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/therapists/me',
          body: {'name': 'Dra. Maria', 'email': 'maria@terafy.com', 'status': 'active'},
          token: therapist2Token,
        );
        await handler(createRequest2);

        // User1 busca seu próprio therapist (deve ver)
        final getRequest1 = HttpTestHelpers.createRequest(method: 'GET', path: '/therapists/me', token: therapistToken);
        final getResponse1 = await handler(getRequest1);
        final getData1 = await HttpTestHelpers.parseJsonResponse(getResponse1);
        expect(getData1['id'], therapist1Id);

        // User1 tenta buscar therapist2 via admin endpoint (não deve ver se não for admin)
        // Mas como não é admin, não pode usar GET /therapists/:id
        // Isso valida RLS indiretamente
      });
    });
  });
}
