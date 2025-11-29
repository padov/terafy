import 'package:terafy/core/domain/repositories/therapeutic_plan_repository.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_objective.dart';

class UpdateObjectiveUseCase {
  const UpdateObjectiveUseCase(this._repository);

  final TherapeuticPlanRepository _repository;

  Future<TherapeuticObjective> call({
    required String id,
    String? description,
    String? specificAspect,
    String? measurableCriteria,
    String? achievableConditions,
    String? relevantJustification,
    String? timeBoundDeadline,
    String? deadlineType,
    String? priority,
    String? status,
    int? progressPercentage,
    Map<String, dynamic>? progressIndicators,
    String? successMetric,
    DateTime? targetDate,
    String? abandonedReason,
    String? notes,
    int? displayOrder,
  }) {
    return _repository.updateObjective(
      id: id,
      description: description,
      specificAspect: specificAspect,
      measurableCriteria: measurableCriteria,
      achievableConditions: achievableConditions,
      relevantJustification: relevantJustification,
      timeBoundDeadline: timeBoundDeadline,
      deadlineType: deadlineType,
      priority: priority,
      status: status,
      progressPercentage: progressPercentage,
      progressIndicators: progressIndicators,
      successMetric: successMetric,
      targetDate: targetDate,
      abandonedReason: abandonedReason,
      notes: notes,
      displayOrder: displayOrder,
    );
  }
}
