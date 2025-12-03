import 'package:common/common.dart';
import 'package:mocktail/mocktail.dart';
import 'package:server/features/financial/financial.controller.dart';
import 'package:server/features/financial/financial.repository.dart';
import 'package:server/features/session/session.repository.dart';
import 'package:test/test.dart';

class _MockFinancialRepository extends Mock implements FinancialRepository {}

class _MockSessionRepository extends Mock implements SessionRepository {}

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
    registerFallbackValue(
      Session(
        patientId: 1,
        therapistId: 1,
        scheduledStartTime: DateTime.now(),
        durationMinutes: 60,
        sessionNumber: 1,
        type: 'presential',
        modality: 'individual',
        status: 'completed',
        paymentStatus: 'pending',
      ),
    );
  });

  late _MockFinancialRepository repository;
  late _MockSessionRepository sessionRepository;
  late FinancialController controller;

  final sampleTransaction = FinancialTransaction(
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

  setUp(() {
    repository = _MockFinancialRepository();
    sessionRepository = _MockSessionRepository();
    controller = FinancialController(repository, sessionRepository);
  });

  group('FinancialController - createTransaction', () {
    test('deve criar transação com dados válidos', () async {
      when(
        () => repository.createTransaction(
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleTransaction);

      final result = await controller.createTransaction(
        transaction: sampleTransaction,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.id, equals(1));
      expect(result.amount, 100.0);
    });

    test('deve validar valor maior que zero', () async {
      final invalidTransaction = sampleTransaction.copyWith(amount: 0.0);

      expect(
        () => controller.createTransaction(
          transaction: invalidTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(
          isA<FinancialException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', contains('Valor deve ser maior que zero')),
        ),
      );
    });

    test('deve validar data de vencimento posterior à data da transação', () async {
      final invalidTransaction = sampleTransaction.copyWith(
        transactionDate: DateTime(2024, 1, 15),
        dueDate: DateTime(2024, 1, 10), // Antes da transação
      );

      expect(
        () => controller.createTransaction(
          transaction: invalidTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<FinancialException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve validar ID do terapeuta', () async {
      final invalidTransaction = sampleTransaction.copyWith(therapistId: 0);

      expect(
        () => controller.createTransaction(
          transaction: invalidTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<FinancialException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve validar ID do paciente', () async {
      final invalidTransaction = sampleTransaction.copyWith(patientId: 0);

      expect(
        () => controller.createTransaction(
          transaction: invalidTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<FinancialException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve validar data de pagamento posterior à data da transação', () async {
      final invalidTransaction = sampleTransaction.copyWith(
        transactionDate: DateTime(2024, 1, 15),
        paidAt: DateTime(2024, 1, 10), // Antes da transação
      );

      expect(
        () => controller.createTransaction(
          transaction: invalidTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<FinancialException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve usar bypassRLS quando role é admin', () async {
      when(
        () => repository.createTransaction(
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => sampleTransaction);

      await controller.createTransaction(transaction: sampleTransaction, userId: 1, userRole: 'admin', accountId: null);

      verify(
        () => repository.createTransaction(
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).called(1);
    });

    test('deve tratar exceções do repositório', () async {
      when(
        () => repository.createTransaction(
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro do banco'));

      expect(
        () => controller.createTransaction(
          transaction: sampleTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(
          isA<FinancialException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('Erro ao criar transação')),
        ),
      );
    });
  });

  group('FinancialController - getTransaction', () {
    test('deve retornar transação quando encontrada', () async {
      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleTransaction);

      final result = await controller.getTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1);

      expect(result, isNotNull);
      expect(result!.id, equals(1));
      expect(result.amount, 100.0);
    });

    test('deve retornar null quando transação não existe', () async {
      when(
        () => repository.getTransactionById(
          transactionId: 999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      final result = await controller.getTransaction(
        transactionId: 999,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result, isNull);
    });

    test('deve usar bypassRLS quando role é admin', () async {
      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => sampleTransaction);

      await controller.getTransaction(transactionId: 1, userId: 1, userRole: 'admin', accountId: null);

      verify(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).called(1);
    });

    test('deve tratar exceções do repositório', () async {
      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro do banco'));

      expect(
        () => controller.getTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(
          isA<FinancialException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('Erro ao buscar transação')),
        ),
      );
    });
  });

  group('FinancialController - listTransactions', () {
    test('deve listar transações com sucesso', () async {
      final transactions = [sampleTransaction, sampleTransaction.copyWith(id: 2, amount: 200.0)];

      when(
        () => repository.listTransactions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          therapistId: null,
          patientId: null,
          sessionId: null,
          status: null,
          category: null,
          startDate: null,
          endDate: null,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => transactions);

      final result = await controller.listTransactions(userId: 1, userRole: 'therapist', accountId: 1);

      expect(result, hasLength(2));
      expect(result.first.id, equals(1));
      expect(result.last.id, equals(2));
    });

    test('deve filtrar por therapistId', () async {
      // O controller usa accountId ?? therapistId, então quando accountId é null e therapistId é 5,
      // o repository recebe accountId: 5
      when(
        () => repository.listTransactions(
          userId: 1,
          userRole: 'admin',
          accountId: 5, // accountId ?? therapistId = 5
          therapistId: 5,
          patientId: null,
          sessionId: null,
          status: null,
          category: null,
          startDate: null,
          endDate: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => [sampleTransaction]);

      final result = await controller.listTransactions(userId: 1, userRole: 'admin', accountId: null, therapistId: 5);

      expect(result, hasLength(1));
      expect(result.first.id, equals(1));
      verify(
        () => repository.listTransactions(
          userId: 1,
          userRole: 'admin',
          accountId: 5, // accountId ?? therapistId = 5
          therapistId: 5,
          patientId: null,
          sessionId: null,
          status: null,
          category: null,
          startDate: null,
          endDate: null,
          bypassRLS: true,
        ),
      ).called(1);
    });

    test('deve filtrar por patientId', () async {
      when(
        () => repository.listTransactions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          therapistId: null,
          patientId: 10,
          sessionId: null,
          status: null,
          category: null,
          startDate: null,
          endDate: null,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => [sampleTransaction]);

      final result = await controller.listTransactions(userId: 1, userRole: 'therapist', accountId: 1, patientId: 10);

      expect(result, hasLength(1));
    });

    test('deve filtrar por sessionId', () async {
      when(
        () => repository.listTransactions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          therapistId: null,
          patientId: null,
          sessionId: 20,
          status: null,
          category: null,
          startDate: null,
          endDate: null,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => [sampleTransaction]);

      final result = await controller.listTransactions(userId: 1, userRole: 'therapist', accountId: 1, sessionId: 20);

      expect(result, hasLength(1));
    });

    test('deve filtrar por status', () async {
      when(
        () => repository.listTransactions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          therapistId: null,
          patientId: null,
          sessionId: null,
          status: 'pago',
          category: null,
          startDate: null,
          endDate: null,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => [sampleTransaction.copyWith(status: 'pago')]);

      final result = await controller.listTransactions(userId: 1, userRole: 'therapist', accountId: 1, status: 'pago');

      expect(result, hasLength(1));
      expect(result.first.status, 'pago');
    });

    test('deve filtrar por category', () async {
      when(
        () => repository.listTransactions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          therapistId: null,
          patientId: null,
          sessionId: null,
          status: null,
          category: 'sessao',
          startDate: null,
          endDate: null,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => [sampleTransaction]);

      final result = await controller.listTransactions(
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
        category: 'sessao',
      );

      expect(result, hasLength(1));
    });

    test('deve filtrar por período (startDate e endDate)', () async {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);

      when(
        () => repository.listTransactions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          therapistId: null,
          patientId: null,
          sessionId: null,
          status: null,
          category: null,
          startDate: startDate,
          endDate: endDate,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => [sampleTransaction]);

      final result = await controller.listTransactions(
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, hasLength(1));
    });

    test('deve usar bypassRLS quando role é admin', () async {
      when(
        () => repository.listTransactions(
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
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => [sampleTransaction]);

      await controller.listTransactions(userId: 1, userRole: 'admin', accountId: null);

      verify(
        () => repository.listTransactions(
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
          bypassRLS: true,
        ),
      ).called(1);
    });

    test('deve tratar exceções do repositório', () async {
      when(
        () => repository.listTransactions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          therapistId: null,
          patientId: null,
          sessionId: null,
          status: null,
          category: null,
          startDate: null,
          endDate: null,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro do banco'));

      expect(
        () => controller.listTransactions(userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(
          isA<FinancialException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('Erro ao listar transações')),
        ),
      );
    });
  });

  group('FinancialController - updateTransaction', () {
    test('deve atualizar transação quando encontrada', () async {
      final updated = sampleTransaction.copyWith(status: 'pago');

      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleTransaction);

      when(
        () => repository.updateTransaction(
          transactionId: 1,
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => updated);

      final result = await controller.updateTransaction(
        transactionId: 1,
        transaction: updated,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.status, 'pago');
    });

    test('deve lançar exceção quando transação não encontrada', () async {
      when(
        () => repository.getTransactionById(
          transactionId: 999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      expect(
        () => controller.updateTransaction(
          transactionId: 999,
          transaction: sampleTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<FinancialException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('deve validar valor maior que zero ao atualizar', () async {
      final invalidTransaction = sampleTransaction.copyWith(amount: 0.0);

      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleTransaction);

      expect(
        () => controller.updateTransaction(
          transactionId: 1,
          transaction: invalidTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<FinancialException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve validar data de vencimento ao atualizar', () async {
      final invalidTransaction = sampleTransaction.copyWith(
        transactionDate: DateTime(2024, 1, 15),
        dueDate: DateTime(2024, 1, 10), // Antes da transação
      );

      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleTransaction);

      expect(
        () => controller.updateTransaction(
          transactionId: 1,
          transaction: invalidTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<FinancialException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve validar data de pagamento ao atualizar', () async {
      final invalidTransaction = sampleTransaction.copyWith(
        transactionDate: DateTime(2024, 1, 15),
        paidAt: DateTime(2024, 1, 10), // Antes da transação
      );

      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleTransaction);

      expect(
        () => controller.updateTransaction(
          transactionId: 1,
          transaction: invalidTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<FinancialException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve validar estorno não maior que valor original', () async {
      final existingTransaction = sampleTransaction.copyWith(amount: 100.0);
      final invalidTransaction = sampleTransaction.copyWith(
        type: 'estorno',
        amount: 150.0, // Maior que o original
      );

      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => existingTransaction);

      expect(
        () => controller.updateTransaction(
          transactionId: 1,
          transaction: invalidTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(
          isA<FinancialException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', contains('Valor do estorno não pode ser maior')),
        ),
      );
    });

    test('deve atualizar sessão quando status muda para pago', () async {
      final existingTransaction = sampleTransaction.copyWith(status: 'pendente', sessionId: 10);
      final updatedTransaction = sampleTransaction.copyWith(status: 'pago', sessionId: 10);

      final session = Session(
        id: 10,
        therapistId: 1,
        patientId: 1,
        scheduledStartTime: DateTime.now(),
        durationMinutes: 60,
        sessionNumber: 1,
        type: 'presential',
        modality: 'individual',
        status: 'completed',
        paymentStatus: 'pending',
      );

      // O controller chama getTransactionById duas vezes (linhas 173 e 194)
      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => existingTransaction);

      when(
        () => repository.updateTransaction(
          transactionId: 1,
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => updatedTransaction);

      when(
        () => sessionRepository.getSessionById(
          sessionId: 10,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => session);

      when(
        () => sessionRepository.updateSession(
          sessionId: 10,
          session: any(named: 'session'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => session.copyWith(paymentStatus: 'paid'));

      final result = await controller.updateTransaction(
        transactionId: 1,
        transaction: updatedTransaction,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.status, 'pago');
      verify(
        () => sessionRepository.updateSession(
          sessionId: 10,
          session: any(named: 'session'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('não deve atualizar sessão quando status já era pago', () async {
      final existingTransaction = sampleTransaction.copyWith(status: 'pago', sessionId: 10);
      final updatedTransaction = sampleTransaction.copyWith(status: 'pago', sessionId: 10);

      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => existingTransaction);

      when(
        () => repository.updateTransaction(
          transactionId: 1,
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => updatedTransaction);

      await controller.updateTransaction(
        transactionId: 1,
        transaction: updatedTransaction,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      verifyNever(
        () => sessionRepository.updateSession(
          sessionId: any(named: 'sessionId'),
          session: any(named: 'session'),
          userId: any(named: 'userId'),
          userRole: any(named: 'userRole'),
          accountId: any(named: 'accountId'),
          bypassRLS: any(named: 'bypassRLS'),
        ),
      );
    });

    test('não deve falhar transação se erro ao atualizar sessão', () async {
      final existingTransaction = sampleTransaction.copyWith(status: 'pendente', sessionId: 10);
      final updatedTransaction = sampleTransaction.copyWith(status: 'pago', sessionId: 10);

      // O controller chama getTransactionById duas vezes (linhas 173 e 194)
      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => existingTransaction);

      when(
        () => repository.updateTransaction(
          transactionId: 1,
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => updatedTransaction);

      when(
        () => sessionRepository.getSessionById(
          sessionId: 10,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro ao buscar sessão'));

      // Não deve lançar exceção, apenas logar o erro
      final result = await controller.updateTransaction(
        transactionId: 1,
        transaction: updatedTransaction,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.status, 'pago');
      expect(result.sessionId, 10);
      // Verifica que a transação foi atualizada mesmo com erro na sessão
      verify(
        () => repository.updateTransaction(
          transactionId: 1,
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('deve usar bypassRLS quando role é admin', () async {
      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => sampleTransaction);

      when(
        () => repository.updateTransaction(
          transactionId: 1,
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => sampleTransaction);

      await controller.updateTransaction(
        transactionId: 1,
        transaction: sampleTransaction,
        userId: 1,
        userRole: 'admin',
        accountId: null,
      );

      verify(
        () => repository.updateTransaction(
          transactionId: 1,
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).called(1);
    });

    test('deve tratar exceções do repositório', () async {
      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro do banco'));

      expect(
        () => controller.updateTransaction(
          transactionId: 1,
          transaction: sampleTransaction,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(
          isA<FinancialException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('Erro ao atualizar transação')),
        ),
      );
    });
  });

  group('FinancialController - deleteTransaction', () {
    test('deve deletar transação quando encontrada e não paga', () async {
      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleTransaction); // Status pendente

      when(
        () => repository.deleteTransaction(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async {});

      await controller.deleteTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1);

      verify(
        () => repository.deleteTransaction(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('deve lançar exceção quando transação não encontrada', () async {
      when(
        () => repository.getTransactionById(
          transactionId: 999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      expectLater(
        controller.deleteTransaction(transactionId: 999, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(isA<FinancialException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('deve validar que transação paga não pode ser deletada', () async {
      final paidTransaction = sampleTransaction.copyWith(status: 'pago');

      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => paidTransaction);

      expectLater(
        controller.deleteTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(
          isA<FinancialException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', contains('Não é possível deletar uma transação já paga')),
        ),
      );
    });

    test('deve usar bypassRLS quando role é admin', () async {
      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => sampleTransaction);

      when(
        () => repository.deleteTransaction(
          transactionId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async {});

      await controller.deleteTransaction(transactionId: 1, userId: 1, userRole: 'admin', accountId: null);

      verify(
        () => repository.deleteTransaction(
          transactionId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).called(1);
    });

    test('deve tratar exceções do repositório', () async {
      when(
        () => repository.getTransactionById(
          transactionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro do banco'));

      expect(
        () => controller.deleteTransaction(transactionId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(
          isA<FinancialException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('Erro ao deletar transação')),
        ),
      );
    });
  });

  group('FinancialController - getFinancialSummary', () {
    test('deve retornar resumo financeiro corretamente', () async {
      final summary = {
        'totalPaidCount': 5,
        'totalPaidAmount': 500.0,
        'totalPendingCount': 3,
        'totalPendingAmount': 300.0,
        'totalOverdueCount': 1,
        'totalOverdueAmount': 100.0,
        'totalCount': 9,
        'totalAmount': 900.0,
      };

      when(
        () => repository.getFinancialSummary(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          startDate: null,
          endDate: null,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => summary);

      final result = await controller.getFinancialSummary(
        therapistId: 1,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result['totalPaidCount'], 5);
      expect(result['totalPaidAmount'], 500.0);
      expect(result['totalPendingCount'], 3);
    });

    test('deve validar ID do terapeuta', () async {
      expect(
        () => controller.getFinancialSummary(therapistId: 0, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(isA<FinancialException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve validar período (data inicial antes da final)', () async {
      expect(
        () => controller.getFinancialSummary(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 10), // Antes da inicial
        ),
        throwsA(isA<FinancialException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve filtrar por período corretamente', () async {
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
        () => repository.getFinancialSummary(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          startDate: startDate,
          endDate: endDate,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => summary);

      final result = await controller.getFinancialSummary(
        therapistId: 1,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
        startDate: startDate,
        endDate: endDate,
      );

      expect(result['totalCount'], 3);
      verify(
        () => repository.getFinancialSummary(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          startDate: startDate,
          endDate: endDate,
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('deve usar bypassRLS quando role é admin', () async {
      final summary = {
        'totalPaidCount': 0,
        'totalPaidAmount': 0.0,
        'totalPendingCount': 0,
        'totalPendingAmount': 0.0,
        'totalOverdueCount': 0,
        'totalOverdueAmount': 0.0,
        'totalCount': 0,
        'totalAmount': 0.0,
      };

      // O controller usa accountId ?? therapistId, então quando accountId é null e therapistId é 1,
      // o repository recebe accountId: 1
      when(
        () => repository.getFinancialSummary(
          therapistId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: 1, // accountId ?? therapistId = 1
          startDate: null,
          endDate: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => summary);

      await controller.getFinancialSummary(therapistId: 1, userId: 1, userRole: 'admin', accountId: null);

      verify(
        () => repository.getFinancialSummary(
          therapistId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: 1, // accountId ?? therapistId = 1
          startDate: null,
          endDate: null,
          bypassRLS: true,
        ),
      ).called(1);
    });

    test('deve tratar exceções do repositório', () async {
      when(
        () => repository.getFinancialSummary(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          startDate: null,
          endDate: null,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro do banco'));

      expect(
        () => controller.getFinancialSummary(therapistId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(
          isA<FinancialException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('Erro ao buscar resumo financeiro')),
        ),
      );
    });
  });
}
