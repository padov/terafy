import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import '../../helpers/integration_test_db.dart';
import '../../helpers/test_server_setup.dart';
import '../../helpers/http_test_helpers.dart';

void main() {
  group('Financial API Integration Tests', () {
    late Handler handler;
    late TestDBConnection dbConnection;
    String? therapistToken;
    String? adminToken;
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
      therapistToken = loginData['auth_token'] as String;

      // Cria usuário admin
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final random = (timestamp % 1000000).toString().padLeft(6, '0');
      final uniqueAdminEmail = 'admin_$random@terafy.com';

      final registerAdminRequest = HttpTestHelpers.createRequest(
        method: 'POST',
        path: '/auth/register',
        body: {'email': uniqueAdminEmail, 'password': 'senha123'},
      );
      final registerAdminResponse = await handler(registerAdminRequest);
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

    group('POST /financial', () {
      test('deve criar transação financeira', () async {
        // Primeiro, cria um paciente para vincular à transação
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Teste',
            'email': 'paciente@terafy.com',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        // Cria transação financeira
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 150.0,
            'patientId': patientId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pago',
            'category': 'sessao',
            'notes': 'Sessão de terapia',
          },
          token: therapistToken,
        );

        final response = await handler(request);

        expect(response.statusCode, 201);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], isNotNull);
        expect(data['therapistId'], therapistId);
        expect(data['patientId'], patientId);
        expect(data['amount'], 150.0);
      });

      test('deve retornar 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'income',
            'amount': 150.0,
            'description': 'Sessão de terapia',
            'transactionDate': DateTime.now().toIso8601String(),
          },
        );

        final response = await handler(request);
        expect(response.statusCode, 401);
      });

      test('deve retornar 400 quando amount <= 0', () async {
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Validação',
            'email': 'paciente.validacao@terafy.com',
            'phones': ['11999999999'],
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 0.0,
            'patientId': patientId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pendente',
            'category': 'sessao',
          },
          token: therapistToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando therapist sem accountId', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'therapist_sem_perfil_$random@terafy.com';

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
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 150.0,
            'patientId': 1,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pendente',
            'category': 'sessao',
          },
          token: tokenSemPerfil,
        );

        final response = await handler(request);
        expect(response.statusCode, 400);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['error'], contains('Conta de terapeuta não vinculada'));
      });

      test('deve retornar 400 quando admin sem therapistId', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 150.0,
            'patientId': 1,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pendente',
            'category': 'sessao',
          },
          token: adminToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 400);
        final body = await HttpTestHelpers.parseJsonResponse(response);
        expect(body['error'], contains('therapistId'));
      });

      test('deve retornar 400 quando body vazio', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/financial'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $therapistToken'},
          body: '',
        );

        final response = await handler(request);
        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando JSON inválido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/financial'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $therapistToken'},
          body: 'invalid json',
        );

        final response = await handler(request);
        expect(response.statusCode, 400);
      });
    });

    group('GET /financial', () {
      test('deve listar transações do therapist autenticado', () async {
        // Cria um paciente primeiro
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Lista',
            'email': 'paciente.lista@terafy.com',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        // Cria uma transação para ter dados para listar
        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 200.0,
            'patientId': patientId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pago',
            'category': 'sessao',
          },
          token: therapistToken,
        );
        await handler(createRequest);

        // Lista transações
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/financial', token: therapistToken);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isA<List>());
        expect(data.length, greaterThanOrEqualTo(1));
      });

      test('deve retornar lista vazia quando não há transações', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/financial', token: therapistToken);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isA<List>());
        expect(data, isEmpty);
      });

      test('deve filtrar por patientId', () async {
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Filtro',
            'email': 'paciente.filtro@terafy.com',
            'phones': ['11999999999'],
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 200.0,
            'patientId': patientId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pago',
            'category': 'sessao',
          },
          token: therapistToken,
        );
        await handler(createRequest);

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/financial?patientId=$patientId',
          token: therapistToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isA<List>());
        expect(data.length, greaterThanOrEqualTo(1));
      });

      test('deve filtrar por status', () async {
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Status',
            'email': 'paciente.status@terafy.com',
            'phones': ['11999999999'],
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 200.0,
            'patientId': patientId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pago',
            'category': 'sessao',
          },
          token: therapistToken,
        );
        await handler(createRequest);

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/financial?status=pago',
          token: therapistToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isA<List>());
      });

      test('deve retornar 400 quando therapist sem accountId', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'therapist_sem_perfil2_$random@terafy.com';

        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail, 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final tokenSemPerfil = registerData['auth_token'] as String;

        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/financial', token: tokenSemPerfil);

        final response = await handler(request);
        expect(response.statusCode, 400);
      });

      test('admin lista todas as transações', () async {
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Admin',
            'email': 'paciente.admin@terafy.com',
            'phones': ['11999999999'],
            'therapistId': therapistId,
          },
          token: adminToken,
        );
        final patientResponse = await handler(patientRequest);
        if (patientResponse.statusCode >= 400) {
          final errorBody = await patientResponse.readAsString();
          fail('Falha ao criar paciente: ${patientResponse.statusCode} - $errorBody');
        }
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int?;
        if (patientId == null) {
          fail('ID do paciente não foi retornado na criação');
        }

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 200.0,
            'patientId': patientId,
            'therapistId': therapistId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pago',
            'category': 'sessao',
          },
          token: adminToken,
        );
        await handler(createRequest);

        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/financial', token: adminToken);

        final response = await handler(request);
        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isA<List>());
      });

      test('admin filtra por therapistId', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/financial?therapistId=$therapistId',
          token: adminToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonListResponse(response);
        expect(data, isA<List>());
      });
    });

    group('GET /financial/:id', () {
      test('deve retornar transação quando encontrada', () async {
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Get',
            'email': 'paciente.get@terafy.com',
            'phones': ['11999999999'],
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 200.0,
            'patientId': patientId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pago',
            'category': 'sessao',
          },
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final transactionId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/financial/$transactionId',
          token: therapistToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], equals(transactionId));
        expect(data['amount'], 200.0);
      });

      test('deve retornar 404 quando transação não existe', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/financial/99999', token: therapistToken);

        final response = await handler(request);
        expect(response.statusCode, 404);
      });

      test('deve retornar 404 quando ID inválido (não corresponde ao padrão da rota)', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/financial/abc', token: therapistToken);

        final response = await handler(request);
        // A rota usa regex [0-9]+, então IDs não numéricos retornam 404 (rota não encontrada)
        expect(response.statusCode, 404);
      });

      test('deve retornar 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/financial/1');

        final response = await handler(request);
        expect(response.statusCode, 401);
      });

      test('admin acessa qualquer transação', () async {
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Admin Get',
            'email': 'paciente.admin.get@terafy.com',
            'phones': ['11999999999'],
            'therapistId': therapistId,
          },
          token: adminToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 200.0,
            'patientId': patientId,
            'therapistId': therapistId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pago',
            'category': 'sessao',
          },
          token: adminToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final transactionId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/financial/$transactionId',
          token: adminToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['id'], equals(transactionId));
      });
    });

    group('PUT /financial/:id', () {
      test('deve atualizar transação com sucesso', () async {
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Update',
            'email': 'paciente.update@terafy.com',
            'phones': ['11999999999'],
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 200.0,
            'patientId': patientId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pendente',
            'category': 'sessao',
          },
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final transactionId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/financial/$transactionId',
          body: {'status': 'pago', 'paidAt': DateTime.now().toIso8601String()},
          token: therapistToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['status'], 'pago');
      });

      test('deve retornar 404 quando ID inválido (não corresponde ao padrão da rota)', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/financial/abc',
          body: {'status': 'pago'},
          token: therapistToken,
        );

        final response = await handler(request);
        // A rota usa regex [0-9]+, então IDs não numéricos retornam 404 (rota não encontrada)
        expect(response.statusCode, 404);
      });

      test('deve retornar 404 quando transação não existe', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'PUT',
          path: '/financial/99999',
          body: {'status': 'pago'},
          token: therapistToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 404);
      });

      test('deve retornar 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'PUT', path: '/financial/1', body: {'status': 'pago'});

        final response = await handler(request);
        expect(response.statusCode, 401);
      });
    });

    group('DELETE /financial/:id', () {
      test('deve deletar transação com sucesso', () async {
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Delete',
            'email': 'paciente.delete@terafy.com',
            'phones': ['11999999999'],
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 200.0,
            'patientId': patientId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pendente',
            'category': 'sessao',
          },
          token: therapistToken,
        );
        final createResponse = await handler(createRequest);
        final createData = await HttpTestHelpers.parseJsonResponse(createResponse);
        final transactionId = createData['id'] as int;

        final request = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/financial/$transactionId',
          token: therapistToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data['message'], contains('deletada com sucesso'));

        // Verifica que foi removido
        final getRequest = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/financial/$transactionId',
          token: therapistToken,
        );
        final getResponse = await handler(getRequest);
        expect(getResponse.statusCode, 404);
      });

      test('deve retornar 404 quando ID inválido (não corresponde ao padrão da rota)', () async {
        final request = HttpTestHelpers.createRequest(method: 'DELETE', path: '/financial/abc', token: therapistToken);

        final response = await handler(request);
        // A rota usa regex [0-9]+, então IDs não numéricos retornam 404 (rota não encontrada)
        expect(response.statusCode, 404);
      });

      test('deve retornar 404 quando transação não existe', () async {
        final request = HttpTestHelpers.createRequest(
          method: 'DELETE',
          path: '/financial/99999',
          token: therapistToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 404);
      });

      test('deve retornar 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'DELETE', path: '/financial/1');

        final response = await handler(request);
        expect(response.statusCode, 401);
      });
    });

    group('GET /financial/summary', () {
      test('deve retornar resumo financeiro', () async {
        // Cria um paciente primeiro
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Resumo',
            'email': 'paciente.resumo@terafy.com',
            'phones': ['11999999999'],
            'birthDate': '1990-01-01',
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        // Cria algumas transações para ter dados no resumo
        final transaction1 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 150.0,
            'patientId': patientId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pago',
            'category': 'sessao',
          },
          token: therapistToken,
        );
        await handler(transaction1);

        final transaction2 = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 200.0,
            'patientId': patientId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'cartao_credito',
            'status': 'pendente',
            'category': 'sessao',
          },
          token: therapistToken,
        );
        await handler(transaction2);

        // Busca resumo financeiro
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/financial/summary', token: therapistToken);

        final response = await handler(request);

        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data, isA<Map>());
        expect(data['totalPaidCount'], isNotNull);
        expect(data['totalPaidAmount'], isNotNull);
        expect(data['totalPendingCount'], isNotNull);
        expect(data['totalPendingAmount'], isNotNull);
        expect(data['totalCount'], isNotNull);
        expect(data['totalAmount'], isNotNull);
      });

      test('deve filtrar por período (startDate e endDate)', () async {
        final patientRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente Período',
            'email': 'paciente.periodo@terafy.com',
            'phones': ['11999999999'],
          },
          token: therapistToken,
        );
        final patientResponse = await handler(patientRequest);
        final patientData = await HttpTestHelpers.parseJsonResponse(patientResponse);
        final patientId = patientData['id'] as int;

        final createRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/financial',
          body: {
            'type': 'recebimento',
            'amount': 150.0,
            'patientId': patientId,
            'transactionDate': DateTime.now().toIso8601String(),
            'paymentMethod': 'dinheiro',
            'status': 'pago',
            'category': 'sessao',
          },
          token: therapistToken,
        );
        await handler(createRequest);

        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now().add(const Duration(days: 30));

        final request = HttpTestHelpers.createRequest(
          method: 'GET',
          path: '/financial/summary?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}',
          token: therapistToken,
        );

        final response = await handler(request);
        expect(response.statusCode, 200);
        final data = await HttpTestHelpers.parseJsonResponse(response);
        expect(data, isA<Map>());
      });

      test('deve retornar 400 quando therapist sem accountId', () async {
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random = (timestamp % 1000000).toString().padLeft(6, '0');
        final uniqueEmail = 'therapist_sem_perfil3_$random@terafy.com';

        final registerRequest = HttpTestHelpers.createRequest(
          method: 'POST',
          path: '/auth/register',
          body: {'email': uniqueEmail, 'password': 'senha123'},
        );
        final registerResponse = await handler(registerRequest);
        final registerData = await HttpTestHelpers.parseJsonResponse(registerResponse);
        final tokenSemPerfil = registerData['auth_token'] as String;

        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/financial/summary', token: tokenSemPerfil);

        final response = await handler(request);
        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando admin sem therapistId', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/financial/summary', token: adminToken);

        final response = await handler(request);
        expect(response.statusCode, 400);
      });

      test('deve retornar 401 sem autenticação', () async {
        final request = HttpTestHelpers.createRequest(method: 'GET', path: '/financial/summary');

        final response = await handler(request);
        expect(response.statusCode, 401);
      });
    });
  });
}
