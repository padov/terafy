import 'package:terafy/core/domain/repositories/therapeutic_plan_repository.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan.dart';

class GetPlanUseCase {
  const GetPlanUseCase(this._repository);

  final TherapeuticPlanRepository _repository;

  Future<TherapeuticPlan> call(String id) {
    return _repository.fetchPlanById(id);
  }
}
