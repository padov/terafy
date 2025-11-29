import 'package:terafy/core/domain/repositories/therapeutic_plan_repository.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_objective.dart';

class CreateObjectiveUseCase {
  const CreateObjectiveUseCase(this._repository);

  final TherapeuticPlanRepository _repository;

  Future<TherapeuticObjective> call({
    required String therapeuticPlanId,
    required String patientId,
    required String therapistId,
    required String description,
    required String specificAspect,
    required String measurableCriteria,
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
    String? notes,
    int? displayOrder,
  }) {
    return _repository.createObjective(
      therapeuticPlanId: therapeuticPlanId,
      patientId: patientId,
      therapistId: therapistId,
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
      notes: notes,
      displayOrder: displayOrder,
    );
  }
}
