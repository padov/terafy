import 'package:terafy/core/domain/repositories/therapeutic_plan_repository.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_objective.dart';

class GetObjectiveUseCase {
  const GetObjectiveUseCase(this._repository);

  final TherapeuticPlanRepository _repository;

  Future<TherapeuticObjective> call(String id) {
    return _repository.fetchObjectiveById(id);
  }
}
