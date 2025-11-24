import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/financial_repository.dart';

class GetTransactionsUseCase {
  const GetTransactionsUseCase(this._repository);

  final FinancialRepository _repository;

  Future<List<FinancialTransaction>> call({
    int? therapistId,
    int? patientId,
    int? sessionId,
    String? status,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.fetchTransactions(
      therapistId: therapistId,
      patientId: patientId,
      sessionId: sessionId,
      status: status,
      category: category,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
