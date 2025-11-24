import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/financial_repository.dart';

class UpdateTransactionUseCase {
  const UpdateTransactionUseCase(this._repository);

  final FinancialRepository _repository;

  Future<FinancialTransaction> call(
    int transactionId,
    FinancialTransaction transaction,
  ) {
    return _repository.updateTransaction(transactionId, transaction);
  }
}
