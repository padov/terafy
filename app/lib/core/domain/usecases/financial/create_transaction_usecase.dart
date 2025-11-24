import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/financial_repository.dart';

class CreateTransactionUseCase {
  const CreateTransactionUseCase(this._repository);

  final FinancialRepository _repository;

  Future<FinancialTransaction> call(FinancialTransaction transaction) {
    return _repository.createTransaction(transaction);
  }
}
