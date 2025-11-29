import 'package:terafy/core/domain/repositories/therapeutic_plan_repository.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_objective.dart';

class GetObjectivesUseCase {
  const GetObjectivesUseCase(this._repository);

  final TherapeuticPlanRepository _repository;

  Future<List<TherapeuticObjective>> call({
    String? planId,
    String? patientId,
    String? status,
    String? priority,
    String? deadlineType,
  }) {
    return _repository.fetchObjectives(
      planId: planId,
      patientId: patientId,
      status: status,
      priority: priority,
      deadlineType: deadlineType,
    );
  }
}
