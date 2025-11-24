import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/financial_repository.dart';

class GetTransactionUseCase {
  const GetTransactionUseCase(this._repository);

  final FinancialRepository _repository;

  Future<FinancialTransaction?> call(int transactionId) {
    return _repository.fetchTransaction(transactionId);
  }
}
