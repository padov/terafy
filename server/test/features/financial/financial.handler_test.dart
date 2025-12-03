import 'dart:convert';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:common/common.dart';
import 'package:server/features/financial/financial.handler.dart';
import 'package:server/features/financial/financial.controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockFinancialController extends Mock implements FinancialController {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      FinancialTransaction(
        therapistId: 1,
        patientId: 1,
        transactionDate: DateTime.now(),
        type: 'income',
        amount: 100.0,
        paymentMethod: 'credit_card',
        status: 'pendente',
        category: 'session',
      ),
    );
  });

  group('FinancialHandler', () {
    late _MockFinancialController controller;
    late FinancialHandler handler;

    setUp(() {
      controller = _MockFinancialController();
      handler = FinancialHandler(controller);
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

    group('POST /financial/transactions', () {
      test('deve retornar 201 quando cria transação com sucesso', () async {
        final now = DateTime.now();
        final transactionData = {
          // Não incluir therapistId aqui, pois o handler sobrescreve com accountId
          'patientId': 1,
          'transactionDate': now.toIso8601String(),
          'type': 'income',
          'amount': 100.0,
          'paymentMethod': 'credit_card',
          'status': 'pendente',
          'category': 'session',
        };

        final createdTransaction = FinancialTransaction(
          id: 1,
          therapistId: 1,
          patientId: 1,
          transactionDate: now,
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
          createdAt: now,
          updatedAt: now,
        );

        // O handler cria a transação usando fromJson com therapistId adicionado
        // Com registerFallbackValue, podemos usar any() para a transação
        // IMPORTANTE: Para argumentos nomeados, precisamos usar any(named: 'nomeDoParametro')
        when(
          () => controller.createTransaction(
            transaction: any(named: 'transaction'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => createdTransaction);

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/financial/transactions',
          body: transactionData,
          accountId: 1,
          userId: 1,
          userRole: 'therapist',
        );

        final response = await handler.handleCreateTransaction(request);

        // Verificar se o mock foi chamado
        verify(
          () => controller.createTransaction(
            transaction: any(named: 'transaction'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).called(1);

        expect(
          response.statusCode,
          201,
          reason:
              'Esperado 201, mas recebeu ${response.statusCode}. Verifique se o handler está chamando o controller corretamente.',
        );
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], equals(1));
        expect(data['amount'], 100.0);
        expect(data['patientId'], 1);
      });

      test('deve retornar 400 quando dados inválidos', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/financial/transactions',
          body: {}, // Dados inválidos
          accountId: 1,
        );

        final response = await handler.handleCreateTransaction(request);

        expect([400, 500], contains(response.statusCode));
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/financial/transactions'),
          body: jsonEncode({'amount': 100}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.handleCreateTransaction(request);

        expect(response.statusCode, 401);
      });

      test('deve retornar 400 quando body vazio', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/financial/transactions'),
          body: '',
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
        );

        final response = await handler.handleCreateTransaction(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando JSON inválido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/financial/transactions'),
          body: 'invalid json',
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
        );

        final response = await handler.handleCreateTransaction(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando therapist sem accountId', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/financial/transactions',
          body: {'patientId': 1, 'amount': 100.0},
          userId: 1,
          userRole: 'therapist',
          // accountId não fornecido
        );

        final response = await handler.handleCreateTransaction(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Conta de terapeuta não vinculada'));
      });

      test('deve retornar 400 quando admin sem therapistId', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/financial/transactions',
          body: {'patientId': 1, 'amount': 100.0},
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleCreateTransaction(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('therapistId'));
      });

      test('deve retornar 403 quando role não autorizado', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/financial/transactions',
          body: {'patientId': 1, 'amount': 100.0},
          userId: 1,
          userRole: 'patient',
        );

        final response = await handler.handleCreateTransaction(request);

        expect(response.statusCode, 403);
      });

      test('deve retornar 400 quando therapistId inválido (admin)', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/financial/transactions',
          body: {'patientId': 1, 'amount': 100.0, 'therapistId': 'invalid'},
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleCreateTransaction(request);

        expect(response.statusCode, 400);
      });

      test('deve tratar FinancialException', () async {
        when(
          () => controller.createTransaction(
            transaction: any(named: 'transaction'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(FinancialException('Valor inválido', 400));

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/financial/transactions',
          body: {
            'patientId': 1,
            'transactionDate': DateTime.now().toIso8601String(),
            'type': 'income',
            'amount': 100.0,
            'paymentMethod': 'credit_card',
            'status': 'pendente',
            'category': 'session',
          },
          accountId: 1,
        );

        final response = await handler.handleCreateTransaction(request);

        expect(response.statusCode, 400);
      });

      test('deve tratar exceções genéricas', () async {
        when(
          () => controller.createTransaction(
            transaction: any(named: 'transaction'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(Exception('Erro inesperado'));

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/financial/transactions',
          body: {
            'patientId': 1,
            'transactionDate': DateTime.now().toIso8601String(),
            'type': 'income',
            'amount': 100.0,
            'paymentMethod': 'credit_card',
            'status': 'pendente',
            'category': 'session',
          },
          accountId: 1,
        );

        final response = await handler.handleCreateTransaction(request);

        expect(response.statusCode, 500);
      });
    });

    group('GET /financial/transactions/:id', () {
      test('deve retornar 200 com transação quando encontrada', () async {
        final transaction = FinancialTransaction(
          id: 1,
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          () => controller.getTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenAnswer((_) async => transaction);

        final request = createAuthenticatedRequest(method: 'GET', path: '/financial/transactions/1', accountId: 1);

        final response = await handler.handleGetTransaction(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], equals(1));
      });

      test('deve retornar 404 quando transação não encontrada', () async {
        when(
          () => controller.getTransaction(transactionId: 999, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenAnswer((_) async => null);

        final request = createAuthenticatedRequest(method: 'GET', path: '/financial/transactions/999', accountId: 1);

        final response = await handler.handleGetTransaction(request, '999');

        expect(response.statusCode, 404);
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(method: 'GET', path: '/financial/transactions/abc', accountId: 1);

        final response = await handler.handleGetTransaction(request, 'abc');

        expect(response.statusCode, 400);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/financial/transactions/1'),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.handleGetTransaction(request, '1');

        expect(response.statusCode, 401);
      });

      test('deve tratar FinancialException', () async {
        when(
          () => controller.getTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenThrow(FinancialException('Erro ao buscar', 500));

        final request = createAuthenticatedRequest(method: 'GET', path: '/financial/transactions/1', accountId: 1);

        final response = await handler.handleGetTransaction(request, '1');

        expect(response.statusCode, 500);
      });

      test('deve tratar exceções genéricas', () async {
        when(
          () => controller.getTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenThrow(Exception('Erro inesperado'));

        final request = createAuthenticatedRequest(method: 'GET', path: '/financial/transactions/1', accountId: 1);

        final response = await handler.handleGetTransaction(request, '1');

        expect(response.statusCode, 500);
      });
    });

    group('GET /financial/transactions (list)', () {
      test('deve retornar 200 com lista de transações', () async {
        final transactions = [
          FinancialTransaction(
            id: 1,
            therapistId: 1,
            patientId: 1,
            transactionDate: DateTime.now(),
            type: 'income',
            amount: 100.0,
            paymentMethod: 'credit_card',
            status: 'pendente',
            category: 'session',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(
          () => controller.listTransactions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: null,
            sessionId: null,
            status: null,
            category: null,
            startDate: null,
            endDate: null,
          ),
        ).thenAnswer((_) async => transactions);

        final request = createAuthenticatedRequest(method: 'GET', path: '/financial', accountId: 1);

        final response = await handler.handleListTransactions(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as List;
        expect(data, hasLength(1));
      });

      test('deve filtrar por patientId', () async {
        when(
          () => controller.listTransactions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: 10,
            sessionId: null,
            status: null,
            category: null,
            startDate: null,
            endDate: null,
          ),
        ).thenAnswer((_) async => []);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/financial?patientId=10',
          accountId: 1,
        );

        final response = await handler.handleListTransactions(request);

        expect(response.statusCode, 200);
        verify(
          () => controller.listTransactions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: 10,
            sessionId: null,
            status: null,
            category: null,
            startDate: null,
            endDate: null,
          ),
        ).called(1);
      });

      test('deve filtrar por múltiplos parâmetros', () async {
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);

        when(
          () => controller.listTransactions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: 10,
            sessionId: 20,
            status: 'pago',
            category: 'sessao',
            startDate: startDate,
            endDate: endDate,
          ),
        ).thenAnswer((_) async => []);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/financial?patientId=10&sessionId=20&status=pago&category=sessao&startDate=2024-01-01&endDate=2024-01-31',
          accountId: 1,
        );

        final response = await handler.handleListTransactions(request);

        expect(response.statusCode, 200);
      });

      test('deve retornar 400 quando therapist sem accountId', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/financial',
          userId: 1,
          userRole: 'therapist',
          // accountId não fornecido
        );

        final response = await handler.handleListTransactions(request);

        expect(response.statusCode, 400);
      });

      test('deve permitir admin sem therapistId', () async {
        when(
          () => controller.listTransactions(
            userId: 1,
            userRole: 'admin',
            accountId: null,
            therapistId: null,
            patientId: null,
            sessionId: null,
            status: null,
            category: null,
            startDate: null,
            endDate: null,
          ),
        ).thenAnswer((_) async => []);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/financial',
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleListTransactions(request);

        expect(response.statusCode, 200);
      });

      test('deve permitir admin com therapistId', () async {
        when(
          () => controller.listTransactions(
            userId: 1,
            userRole: 'admin',
            accountId: null,
            therapistId: 5,
            patientId: null,
            sessionId: null,
            status: null,
            category: null,
            startDate: null,
            endDate: null,
          ),
        ).thenAnswer((_) async => []);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/financial?therapistId=5',
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleListTransactions(request);

        expect(response.statusCode, 200);
      });

      test('deve retornar 403 quando role não autorizado', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/financial',
          userId: 1,
          userRole: 'patient',
        );

        final response = await handler.handleListTransactions(request);

        expect(response.statusCode, 403);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/financial'),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.handleListTransactions(request);

        expect(response.statusCode, 401);
      });

      test('deve retornar lista vazia quando não há transações', () async {
        when(
          () => controller.listTransactions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: null,
            sessionId: null,
            status: null,
            category: null,
            startDate: null,
            endDate: null,
          ),
        ).thenAnswer((_) async => []);

        final request = createAuthenticatedRequest(method: 'GET', path: '/financial', accountId: 1);

        final response = await handler.handleListTransactions(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as List;
        expect(data, isEmpty);
      });

      test('deve tratar FinancialException', () async {
        when(
          () => controller.listTransactions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: null,
            sessionId: null,
            status: null,
            category: null,
            startDate: null,
            endDate: null,
          ),
        ).thenThrow(FinancialException('Erro ao listar', 500));

        final request = createAuthenticatedRequest(method: 'GET', path: '/financial', accountId: 1);

        final response = await handler.handleListTransactions(request);

        expect(response.statusCode, 500);
      });

      test('deve tratar exceções genéricas', () async {
        when(
          () => controller.listTransactions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: null,
            sessionId: null,
            status: null,
            category: null,
            startDate: null,
            endDate: null,
          ),
        ).thenThrow(Exception('Erro inesperado'));

        final request = createAuthenticatedRequest(method: 'GET', path: '/financial', accountId: 1);

        final response = await handler.handleListTransactions(request);

        expect(response.statusCode, 500);
      });
    });

    group('PUT /financial/transactions/:id', () {
      test('deve retornar 200 quando atualiza com sucesso', () async {
        final existingTransaction = FinancialTransaction(
          id: 1,
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final updatedTransaction = existingTransaction.copyWith(status: 'pago');

        when(
          () => controller.getTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenAnswer((_) async => existingTransaction);

        when(
          () => controller.updateTransaction(
            transactionId: 1,
            transaction: any(named: 'transaction'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => updatedTransaction);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/financial/transactions/1',
          body: {'status': 'pago'},
          accountId: 1,
        );

        final response = await handler.handleUpdateTransaction(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['status'], 'pago');
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/financial/transactions/abc',
          body: {'status': 'pago'},
          accountId: 1,
        );

        final response = await handler.handleUpdateTransaction(request, 'abc');

        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando body vazio', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/financial/transactions/1'),
          body: '',
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
        );

        final response = await handler.handleUpdateTransaction(request, '1');

        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando JSON inválido', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/financial/transactions/1'),
          body: 'invalid json',
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '1',
          },
        );

        final response = await handler.handleUpdateTransaction(request, '1');

        expect(response.statusCode, 400);
      });

      test('deve retornar 404 quando transação não encontrada', () async {
        when(
          () => controller.getTransaction(transactionId: 999, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenAnswer((_) async => null);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/financial/transactions/999',
          body: {'status': 'pago'},
          accountId: 1,
        );

        final response = await handler.handleUpdateTransaction(request, '999');

        expect(response.statusCode, 404);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/financial/transactions/1'),
          body: jsonEncode({'status': 'pago'}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.handleUpdateTransaction(request, '1');

        expect(response.statusCode, 401);
      });

      test('deve tratar FinancialException', () async {
        final existingTransaction = FinancialTransaction(
          id: 1,
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          () => controller.getTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenAnswer((_) async => existingTransaction);

        when(
          () => controller.updateTransaction(
            transactionId: 1,
            transaction: any(named: 'transaction'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(FinancialException('Valor inválido', 400));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/financial/transactions/1',
          body: {'amount': 0},
          accountId: 1,
        );

        final response = await handler.handleUpdateTransaction(request, '1');

        expect(response.statusCode, 400);
      });

      test('deve tratar FormatException', () async {
        final existingTransaction = FinancialTransaction(
          id: 1,
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          () => controller.getTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenAnswer((_) async => existingTransaction);

        when(
          () => controller.updateTransaction(
            transactionId: 1,
            transaction: any(named: 'transaction'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(FormatException('Formato inválido'));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/financial/transactions/1',
          body: {'transactionDate': 'invalid'},
          accountId: 1,
        );

        final response = await handler.handleUpdateTransaction(request, '1');

        expect(response.statusCode, 400);
      });

      test('deve tratar exceções genéricas', () async {
        final existingTransaction = FinancialTransaction(
          id: 1,
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          () => controller.getTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenAnswer((_) async => existingTransaction);

        when(
          () => controller.updateTransaction(
            transactionId: 1,
            transaction: any(named: 'transaction'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(Exception('Erro inesperado'));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/financial/transactions/1',
          body: {'status': 'pago'},
          accountId: 1,
        );

        final response = await handler.handleUpdateTransaction(request, '1');

        expect(response.statusCode, 500);
      });
    });

    group('DELETE /financial/transactions/:id', () {
      test('deve retornar 200 quando deleta com sucesso', () async {
        when(
          () => controller.deleteTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenAnswer((_) async {});

        final request = createAuthenticatedRequest(method: 'DELETE', path: '/financial/transactions/1', accountId: 1);

        final response = await handler.handleDeleteTransaction(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['message'], contains('deletada com sucesso'));
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/financial/transactions/abc',
          accountId: 1,
        );

        final response = await handler.handleDeleteTransaction(request, 'abc');

        expect(response.statusCode, 400);
      });

      test('deve retornar 404 quando transação não encontrada', () async {
        when(
          () => controller.deleteTransaction(transactionId: 999, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenThrow(FinancialException('Transação não encontrada', 404));

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/financial/transactions/999',
          accountId: 1,
        );

        final response = await handler.handleDeleteTransaction(request, '999');

        expect(response.statusCode, 404);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request(
          'DELETE',
          Uri.parse('http://localhost/financial/transactions/1'),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.handleDeleteTransaction(request, '1');

        expect(response.statusCode, 401);
      });

      test('deve tratar FinancialException', () async {
        when(
          () => controller.deleteTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenThrow(FinancialException('Transação paga não pode ser deletada', 400));

        final request = createAuthenticatedRequest(method: 'DELETE', path: '/financial/transactions/1', accountId: 1);

        final response = await handler.handleDeleteTransaction(request, '1');

        expect(response.statusCode, 400);
      });

      test('deve tratar exceções genéricas', () async {
        when(
          () => controller.deleteTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        ).thenThrow(Exception('Erro inesperado'));

        final request = createAuthenticatedRequest(method: 'DELETE', path: '/financial/transactions/1', accountId: 1);

        final response = await handler.handleDeleteTransaction(request, '1');

        expect(response.statusCode, 500);
      });
    });

    group('GET /financial/summary', () {
      test('deve retornar 200 com resumo financeiro', () async {
        final summary = {
          'totalPaidCount': 5,
          'totalPaidAmount': 500.0,
          'totalPendingCount': 3,
          'totalPendingAmount': 300.0,
        };

        when(
          () => controller.getFinancialSummary(
            therapistId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            startDate: null,
            endDate: null,
          ),
        ).thenAnswer((_) async => summary);

        final request = createAuthenticatedRequest(method: 'GET', path: '/financial/summary', accountId: 1);

        final response = await handler.handleGetFinancialSummary(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['totalPaidCount'], 5);
      });

      test('deve retornar 400 quando therapist sem accountId', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/financial/summary',
          userId: 1,
          userRole: 'therapist',
          // accountId não fornecido
        );

        final response = await handler.handleGetFinancialSummary(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando admin sem therapistId', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/financial/summary',
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleGetFinancialSummary(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando admin com therapistId inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/financial/summary?therapistId=invalid',
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleGetFinancialSummary(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 403 quando role não autorizado', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/financial/summary',
          userId: 1,
          userRole: 'patient',
        );

        final response = await handler.handleGetFinancialSummary(request);

        expect(response.statusCode, 403);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/financial/summary'),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.handleGetFinancialSummary(request);

        expect(response.statusCode, 401);
      });

      test('deve filtrar por período (startDate e endDate)', () async {
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);
        final summary = {
          'totalPaidCount': 2,
          'totalPaidAmount': 200.0,
          'totalPendingCount': 1,
          'totalPendingAmount': 100.0,
          'totalOverdueCount': 0,
          'totalOverdueAmount': 0.0,
          'totalCount': 3,
          'totalAmount': 300.0,
        };

        when(
          () => controller.getFinancialSummary(
            therapistId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            startDate: startDate,
            endDate: endDate,
          ),
        ).thenAnswer((_) async => summary);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/financial/summary?startDate=2024-01-01&endDate=2024-01-31',
          accountId: 1,
        );

        final response = await handler.handleGetFinancialSummary(request);

        expect(response.statusCode, 200);
        verify(
          () => controller.getFinancialSummary(
            therapistId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            startDate: startDate,
            endDate: endDate,
          ),
        ).called(1);
      });

      test('deve tratar FinancialException', () async {
        when(
          () => controller.getFinancialSummary(
            therapistId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            startDate: null,
            endDate: null,
          ),
        ).thenThrow(FinancialException('Erro ao buscar resumo', 500));

        final request = createAuthenticatedRequest(method: 'GET', path: '/financial/summary', accountId: 1);

        final response = await handler.handleGetFinancialSummary(request);

        expect(response.statusCode, 500);
      });

      test('deve tratar exceções genéricas', () async {
        when(
          () => controller.getFinancialSummary(
            therapistId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            startDate: null,
            endDate: null,
          ),
        ).thenThrow(Exception('Erro inesperado'));

        final request = createAuthenticatedRequest(method: 'GET', path: '/financial/summary', accountId: 1);

        final response = await handler.handleGetFinancialSummary(request);

        expect(response.statusCode, 500);
      });
    });
  });
}
