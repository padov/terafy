import 'package:common/common.dart';

abstract class FinancialRepository {
  Future<List<FinancialTransaction>> fetchTransactions({
    int? therapistId,
    int? patientId,
    int? sessionId,
    String? status,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<FinancialTransaction?> fetchTransaction(int transactionId);

  Future<FinancialTransaction> createTransaction(
    FinancialTransaction transaction,
  );

  Future<FinancialTransaction> updateTransaction(
    int transactionId,
    FinancialTransaction transaction,
  );

  Future<void> deleteTransaction(int transactionId);

  Future<Map<String, dynamic>> fetchFinancialSummary({
    required int therapistId,
    DateTime? startDate,
    DateTime? endDate,
  });
}
