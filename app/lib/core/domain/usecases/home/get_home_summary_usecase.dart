import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/home_repository.dart';

class GetHomeSummaryUseCase {
  const GetHomeSummaryUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeSummary> call({DateTime? referenceDate, int? therapistId}) {
    return _repository.fetchSummary(
      referenceDate: referenceDate,
      therapistId: therapistId,
    );
  }
}
