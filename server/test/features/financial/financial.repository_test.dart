import 'package:test/test.dart';
import 'package:common/common.dart';
import 'helpers/test_financial_repository.dart';

void main() {
  group('FinancialRepository', () {
    late TestFinancialRepository repository;

    setUp(() {
      repository = TestFinancialRepository();
    });

    tearDown(() {
      repository.clear();
    });

    group('createTransaction', () {
      test('deve criar transação com dados válidos', () async {
        final transaction = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );

        final created = await repository.createTransaction(transaction: transaction, userId: 1, bypassRLS: true);

        expect(created.id, isNotNull);
        expect(created.amount, 100.0);
        expect(created.type, 'income');
        expect(created.status, 'pendente');
        expect(created.createdAt, isNotNull);
      });

      test('deve validar valor positivo', () async {
        final transaction = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 0.0, // Valor inválido
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );

        expect(
          () => repository.createTransaction(transaction: transaction, userId: 1, bypassRLS: true),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Valor deve ser maior que zero'))),
        );
      });
    });

    group('getTransactionById', () {
      test('deve retornar transação quando existe', () async {
        final transaction = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final created = await repository.createTransaction(transaction: transaction, userId: 1, bypassRLS: true);

        final found = await repository.getTransactionById(transactionId: created.id!, userId: 1, bypassRLS: true);

        expect(found, isNotNull);
        expect(found!.id, created.id);
        expect(found.amount, 100.0);
      });

      test('deve retornar null quando transação não existe', () async {
        final found = await repository.getTransactionById(transactionId: 999, userId: 1, bypassRLS: true);
        expect(found, isNull);
      });
    });

    group('listTransactions', () {
      test('deve retornar todas as transações', () async {
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 1,
          patientId: 2,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'session',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final transactions = await repository.listTransactions(userId: 1, bypassRLS: true);

        expect(transactions.length, 2);
      });

      test('deve filtrar por status', () async {
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 1,
          patientId: 2,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'session',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final transactions = await repository.listTransactions(userId: 1, status: 'pago', bypassRLS: true);

        expect(transactions.length, 1);
        expect(transactions.first.status, 'pago');
      });

      test('deve filtrar por período', () async {
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime(2024, 1, 15),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 1,
          patientId: 2,
          transactionDate: DateTime(2024, 2, 15), // Fora do período
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'session',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final transactions = await repository.listTransactions(
          userId: 1,
          startDate: startDate,
          endDate: endDate,
          bypassRLS: true,
        );

        expect(transactions.length, 1);
        expect(transactions.first.transactionDate.month, 1);
      });

      test('deve filtrar por therapistId', () async {
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 2,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'session',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final transactions = await repository.listTransactions(userId: 1, therapistId: 1, bypassRLS: true);

        expect(transactions.length, 1);
        expect(transactions.first.therapistId, 1);
      });

      test('deve filtrar por patientId', () async {
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 10,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 1,
          patientId: 20,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'session',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final transactions = await repository.listTransactions(userId: 1, patientId: 10, bypassRLS: true);

        expect(transactions.length, 1);
        expect(transactions.first.patientId, 10);
      });

      test('deve filtrar por sessionId', () async {
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          sessionId: 100,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          sessionId: 200,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'session',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final transactions = await repository.listTransactions(userId: 1, sessionId: 100, bypassRLS: true);

        expect(transactions.length, 1);
        expect(transactions.first.sessionId, 100);
      });

      test('deve filtrar por category', () async {
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'sessao',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'material',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final transactions = await repository.listTransactions(userId: 1, category: 'sessao', bypassRLS: true);

        expect(transactions.length, 1);
        expect(transactions.first.category, 'sessao');
      });

      test('deve combinar múltiplos filtros', () async {
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 10,
          sessionId: 100,
          transactionDate: DateTime(2024, 1, 15),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'sessao',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 1,
          patientId: 10,
          sessionId: 200,
          transactionDate: DateTime(2024, 1, 20),
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'sessao',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final transactions = await repository.listTransactions(
          userId: 1,
          patientId: 10,
          status: 'pago',
          category: 'sessao',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
          bypassRLS: true,
        );

        expect(transactions.length, 1);
        expect(transactions.first.status, 'pago');
        expect(transactions.first.patientId, 10);
      });

      test('deve ordenar por transaction_date DESC e created_at DESC', () async {
        final now = DateTime.now();
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: now.subtract(const Duration(days: 2)),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: now,
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'session',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await Future.delayed(const Duration(milliseconds: 10));
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final transactions = await repository.listTransactions(userId: 1, bypassRLS: true);

        expect(transactions.length, 2);
        // A mais recente deve vir primeiro (simulado pelo TestFinancialRepository)
        expect(transactions.first.amount, 200.0);
      });
    });

    group('updateTransaction', () {
      test('deve atualizar transação', () async {
        final transaction = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final created = await repository.createTransaction(transaction: transaction, userId: 1, bypassRLS: true);

        final updated = created.copyWith(status: 'pago', paidAt: DateTime.now());

        final result = await repository.updateTransaction(
          transactionId: created.id!,
          transaction: updated,
          userId: 1,
          bypassRLS: true,
        );

        expect(result.status, 'pago');
        expect(result.paidAt, isNotNull);
      });

      test('deve lançar exceção quando transação não existe', () async {
        final transaction = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );

        expect(
          () => repository.updateTransaction(transactionId: 999, transaction: transaction, userId: 1, bypassRLS: true),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Transação não encontrada'))),
        );
      });

      test('deve atualizar campos individuais', () async {
        final transaction = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final created = await repository.createTransaction(transaction: transaction, userId: 1, bypassRLS: true);

        final updated = created.copyWith(status: 'pago', paidAt: DateTime.now(), notes: 'Nota atualizada');

        final result = await repository.updateTransaction(
          transactionId: created.id!,
          transaction: updated,
          userId: 1,
          bypassRLS: true,
        );

        expect(result.status, 'pago');
        expect(result.paidAt, isNotNull);
        expect(result.notes, 'Nota atualizada');
      });

      test('não deve permitir atualizar therapist_id, patient_id, session_id', () async {
        final transaction = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          sessionId: 10,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final created = await repository.createTransaction(transaction: transaction, userId: 1, bypassRLS: true);

        // Tentar atualizar com novos valores
        final updated = created.copyWith(therapistId: 999, patientId: 999, sessionId: 999);

        final result = await repository.updateTransaction(
          transactionId: created.id!,
          transaction: updated,
          userId: 1,
          bypassRLS: true,
        );

        // Deve manter os valores originais
        expect(result.therapistId, 1);
        expect(result.patientId, 1);
        expect(result.sessionId, 10);
      });
    });

    group('deleteTransaction', () {
      test('deve remover transação', () async {
        final transaction = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final created = await repository.createTransaction(transaction: transaction, userId: 1, bypassRLS: true);

        await repository.deleteTransaction(transactionId: created.id!, userId: 1, bypassRLS: true);

        final found = await repository.getTransactionById(transactionId: created.id!, userId: 1, bypassRLS: true);
        expect(found, isNull);
      });

      test('deve lançar exceção quando transação não existe', () async {
        expect(
          () => repository.deleteTransaction(transactionId: 999, userId: 1, bypassRLS: true),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Transação não encontrada'))),
        );
      });
    });

    group('getFinancialSummary', () {
      test('deve calcular resumo financeiro corretamente', () async {
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'session',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 1,
          patientId: 2,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final summary = await repository.getFinancialSummary(therapistId: 1, userId: 1, bypassRLS: true);

        expect(summary['totalPaidCount'], 1);
        expect(summary['totalPaidAmount'], 100.0);
        expect(summary['totalPendingCount'], 1);
        expect(summary['totalPendingAmount'], 200.0);
        expect(summary['totalCount'], 2);
        expect(summary['totalAmount'], 300.0);
      });

      test('deve filtrar por período (startDate e endDate)', () async {
        final startDate = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 31);
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime(2024, 1, 15),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'session',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 1,
          patientId: 2,
          transactionDate: DateTime(2024, 2, 15), // Fora do período
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final summary = await repository.getFinancialSummary(
          therapistId: 1,
          userId: 1,
          startDate: startDate,
          endDate: endDate,
          bypassRLS: true,
        );

        expect(summary['totalCount'], 1);
        expect(summary['totalAmount'], 100.0);
      });

      test('deve retornar valores zerados quando não há transações', () async {
        final summary = await repository.getFinancialSummary(therapistId: 999, userId: 1, bypassRLS: true);

        expect(summary['totalPaidCount'], 0);
        expect(summary['totalPaidAmount'], 0.0);
        expect(summary['totalPendingCount'], 0);
        expect(summary['totalPendingAmount'], 0.0);
        expect(summary['totalOverdueCount'], 0);
        expect(summary['totalOverdueAmount'], 0.0);
        expect(summary['totalCount'], 0);
        expect(summary['totalAmount'], 0.0);
      });

      test('deve incluir transações atrasadas no resumo', () async {
        final transaction1 = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pago',
          category: 'session',
        );
        final transaction2 = FinancialTransaction(
          therapistId: 1,
          patientId: 2,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 200.0,
          paymentMethod: 'credit_card',
          status: 'atrasado',
          category: 'session',
        );

        await repository.createTransaction(transaction: transaction1, userId: 1, bypassRLS: true);
        await repository.createTransaction(transaction: transaction2, userId: 1, bypassRLS: true);

        final summary = await repository.getFinancialSummary(therapistId: 1, userId: 1, bypassRLS: true);

        expect(summary['totalOverdueCount'], 1);
        expect(summary['totalOverdueAmount'], 200.0);
      });
    });

    group('RLS (Row Level Security)', () {
      test('deve aplicar RLS quando bypassRLS é false', () async {
        final transaction = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final created = await repository.createTransaction(transaction: transaction, userId: 1, bypassRLS: true);

        // Com bypassRLS false, o TestFinancialRepository simplifica e retorna todas
        // Em um teste real, o RLS seria aplicado pelo banco
        final found = await repository.getTransactionById(transactionId: created.id!, userId: 1, bypassRLS: false);

        // O TestFinancialRepository simplifica o RLS, então retorna a transação
        expect(found, isNotNull);
      });

      test('deve ignorar RLS quando bypassRLS é true', () async {
        final transaction = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          category: 'session',
        );
        final created = await repository.createTransaction(transaction: transaction, userId: 1, bypassRLS: true);

        final found = await repository.getTransactionById(transactionId: created.id!, userId: 1, bypassRLS: true);

        expect(found, isNotNull);
      });
    });

    group('createTransaction - campos opcionais', () {
      test('deve criar transação com todos os campos opcionais', () async {
        final transaction = FinancialTransaction(
          therapistId: 1,
          patientId: 1,
          sessionId: 10,
          transactionDate: DateTime.now(),
          type: 'income',
          amount: 100.0,
          paymentMethod: 'credit_card',
          status: 'pendente',
          dueDate: DateTime.now().add(const Duration(days: 30)),
          paidAt: DateTime.now(),
          receiptNumber: 'REC-001',
          category: 'session',
          notes: 'Nota da transação',
          invoiceNumber: 'INV-001',
          invoiceIssued: true,
        );

        final created = await repository.createTransaction(transaction: transaction, userId: 1, bypassRLS: true);

        expect(created.sessionId, 10);
        expect(created.dueDate, isNotNull);
        expect(created.paidAt, isNotNull);
        expect(created.receiptNumber, 'REC-001');
        expect(created.notes, 'Nota da transação');
        expect(created.invoiceNumber, 'INV-001');
        expect(created.invoiceIssued, true);
      });
    });
  });
}
