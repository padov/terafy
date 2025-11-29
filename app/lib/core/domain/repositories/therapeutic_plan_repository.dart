import 'package:terafy/features/therapeutic_plan/models/therapeutic_objective.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan.dart' as domain;

abstract class TherapeuticPlanRepository {
  Future<List<domain.TherapeuticPlan>> fetchPlans({String? patientId, String? status});

  Future<domain.TherapeuticPlan> fetchPlanById(String id);

  Future<domain.TherapeuticPlan> createPlan({
    required String patientId,
    required String therapistId,
    required String approach,
    String? approachOther,
    String? recommendedFrequency,
    int? sessionDurationMinutes,
    int? estimatedDurationMonths,
    List<String>? mainTechniques,
    String? interventionStrategies,
    String? resourcesToUse,
    String? therapeuticTasks,
    Map<String, dynamic>? monitoringIndicators,
    List<String>? assessmentInstruments,
    String? measurementFrequency,
    String? observations,
    String? availableResources,
    String? supportNetwork,
    String? status,
  });

  Future<domain.TherapeuticPlan> updatePlan({
    required String id,
    String? patientId,
    String? therapistId,
    String? approach,
    String? approachOther,
    String? recommendedFrequency,
    int? sessionDurationMinutes,
    int? estimatedDurationMonths,
    List<String>? mainTechniques,
    String? interventionStrategies,
    String? resourcesToUse,
    String? therapeuticTasks,
    Map<String, dynamic>? monitoringIndicators,
    List<String>? assessmentInstruments,
    String? measurementFrequency,
    String? observations,
    String? availableResources,
    String? supportNetwork,
    String? status,
    DateTime? reviewedAt,
  });

  Future<void> deletePlan(String id);

  // Objectives
  Future<List<TherapeuticObjective>> fetchObjectives({
    String? planId,
    String? patientId,
    String? status,
    String? priority,
    String? deadlineType,
  });

  Future<TherapeuticObjective> fetchObjectiveById(String id);

  Future<TherapeuticObjective> createObjective({
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
  });

  Future<TherapeuticObjective> updateObjective({
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
  });

  Future<void> deleteObjective(String id);
}
