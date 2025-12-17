import 'package:common/common.dart';
import 'package:server/features/financial/financial.repository.dart';

class FinancialException implements Exception {
  FinancialException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class FinancialController {
  FinancialController(this._repository);

  final FinancialRepository _repository;

  Future<FinancialTransaction> createTransaction({
    required FinancialTransaction transaction,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      // Validações básicas
      if (transaction.therapistId <= 0) {
        throw FinancialException('ID do terapeuta inválido', 400);
      }

      if (transaction.patientId <= 0) {
        throw FinancialException('ID do paciente inválido', 400);
      }

      if (transaction.amount <= 0) {
        throw FinancialException('Valor deve ser maior que zero', 400);
      }

      if (transaction.dueDate != null && transaction.transactionDate.isAfter(transaction.dueDate!)) {
        throw FinancialException('Data de vencimento deve ser posterior ou igual à data da transação', 400);
      }

      if (transaction.paidAt != null && transaction.transactionDate.isAfter(transaction.paidAt!)) {
        throw FinancialException('Data de pagamento deve ser posterior ou igual à data da transação', 400);
      }

      final created = await _repository.createTransaction(
        transaction: transaction,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return created;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is FinancialException) rethrow;
      throw FinancialException('Erro ao criar transação: ${e.toString()}', 500);
    }
  }

  Future<FinancialTransaction?> getTransaction({
    required int transactionId,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      return await _repository.getTransactionById(
        transactionId: transactionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is FinancialException) rethrow;
      throw FinancialException('Erro ao buscar transação: ${e.toString()}', 500);
    }
  }

  Future<List<FinancialTransaction>> listTransactions({
    required int userId,
    String? userRole,
    int? accountId,
    int? therapistId,
    int? patientId,
    String? status,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.func();
    try {
      return await _repository.listTransactions(
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? therapistId,
        therapistId: therapistId,
        patientId: patientId,
        status: status,
        category: category,
        startDate: startDate,
        endDate: endDate,
        bypassRLS: userRole == 'admin',
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is FinancialException) rethrow;
      throw FinancialException('Erro ao listar transações: ${e.toString()}', 500);
    }
  }

  Future<FinancialTransaction> updateTransaction({
    required int transactionId,
    required FinancialTransaction transaction,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      // Validações básicas
      if (transaction.amount <= 0) {
        throw FinancialException('Valor deve ser maior que zero', 400);
      }

      if (transaction.dueDate != null && transaction.transactionDate.isAfter(transaction.dueDate!)) {
        throw FinancialException('Data de vencimento deve ser posterior ou igual à data da transação', 400);
      }

      if (transaction.paidAt != null && transaction.transactionDate.isAfter(transaction.paidAt!)) {
        throw FinancialException('Data de pagamento deve ser posterior ou igual à data da transação', 400);
      }

      // Verificar se a transação existe
      final existing = await _repository.getTransactionById(
        transactionId: transactionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (existing == null) {
        throw FinancialException('Transação não encontrada', 404);
      }

      // Validação: não permitir estorno maior que valor original
      if (transaction.type == 'estorno' && transaction.amount > existing.amount) {
        throw FinancialException('Valor do estorno não pode ser maior que o valor original da transação', 400);
      }

      // Buscar transação atual para verificar mudança de status
      final currentTransaction = await _repository.getTransactionById(
        transactionId: transactionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (currentTransaction == null) {
        throw FinancialException('Transação não encontrada', 404);
      }

      final updated = await _repository.updateTransaction(
        transactionId: transactionId,
        transaction: transaction,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return updated;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is FinancialException) rethrow;
      throw FinancialException('Erro ao atualizar transação: ${e.toString()}', 500);
    }
  }

  Future<void> deleteTransaction({
    required int transactionId,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      // Verificar se a transação existe
      final existing = await _repository.getTransactionById(
        transactionId: transactionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (existing == null) {
        throw FinancialException('Transação não encontrada', 404);
      }

      // Validação: não permitir deletar transação já paga (ou implementar soft delete)
      if (existing.status == 'paid') {
        throw FinancialException('Não é possível deletar uma transação já paga', 400);
      }

      await _repository.deleteTransaction(
        transactionId: transactionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is FinancialException) rethrow;
      throw FinancialException('Erro ao deletar transação: ${e.toString()}', 500);
    }
  }

  Future<Map<String, dynamic>> getFinancialSummary({
    required int therapistId,
    required int userId,
    String? userRole,
    int? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.func();
    try {
      if (therapistId <= 0) {
        throw FinancialException('ID do terapeuta inválido', 400);
      }

      if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
        throw FinancialException('Data inicial deve ser anterior ou igual à data final', 400);
      }

      return await _repository.getFinancialSummary(
        therapistId: therapistId,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? therapistId,
        startDate: startDate,
        endDate: endDate,
        bypassRLS: userRole == 'admin',
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is FinancialException) rethrow;
      throw FinancialException('Erro ao buscar resumo financeiro: ${e.toString()}', 500);
    }
  }

  Future<Map<String, dynamic>> getDashboardMetrics({
    required int therapistId,
    required int userId,
    String? userRole,
    int? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.func();
    try {
      if (therapistId <= 0) {
        throw FinancialException('ID do terapeuta inválido', 400);
      }

      if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
        throw FinancialException('Data inicial deve ser anterior ou igual à data final', 400);
      }

      return await _repository.getDashboardMetrics(
        therapistId: therapistId,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? therapistId,
        startDate: startDate,
        endDate: endDate,
        bypassRLS: userRole == 'admin',
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is FinancialException) rethrow;
      throw FinancialException('Erro ao buscar métricas do dashboard: ${e.toString()}', 500);
    }
  }
}
