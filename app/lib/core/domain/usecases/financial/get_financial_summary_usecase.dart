import 'package:terafy/core/domain/repositories/financial_repository.dart';

class GetFinancialSummaryUseCase {
  const GetFinancialSummaryUseCase(this._repository);

  final FinancialRepository _repository;

  Future<Map<String, dynamic>> call({
    required int therapistId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.fetchFinancialSummary(
      therapistId: therapistId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
