import 'package:terafy/core/domain/repositories/therapeutic_plan_repository.dart';

class DeleteObjectiveUseCase {
  const DeleteObjectiveUseCase(this._repository);

  final TherapeuticPlanRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteObjective(id);
  }
}
