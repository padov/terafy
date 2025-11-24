import 'package:terafy/core/domain/repositories/financial_repository.dart';

class DeleteTransactionUseCase {
  const DeleteTransactionUseCase(this._repository);

  final FinancialRepository _repository;

  Future<void> call(int transactionId) {
    return _repository.deleteTransaction(transactionId);
  }
}
