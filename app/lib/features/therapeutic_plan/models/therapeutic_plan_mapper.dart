import 'package:common/common.dart' as common;
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan.dart' as domain;
import 'therapeutic_objective.dart' as domain_obj;

/// Mapper para converter TherapeuticPlan do common package (backend) para o modelo de domínio do frontend
domain.TherapeuticPlan mapToDomainPlan(common.TherapeuticPlan plan) {
  return domain.TherapeuticPlan(
    id: plan.id?.toString() ?? '',
    patientId: plan.patientId.toString(),
    therapistId: plan.therapistId.toString(),
    approach: _mapApproachFromString(plan.approach),
    approachOther: plan.approachOther,
    recommendedFrequency: plan.recommendedFrequency,
    sessionDurationMinutes: plan.sessionDurationMinutes,
    estimatedDurationMonths: plan.estimatedDurationMonths,
    mainTechniques: plan.mainTechniques ?? const [],
    interventionStrategies: plan.interventionStrategies,
    resourcesToUse: plan.resourcesToUse,
    therapeuticTasks: plan.therapeuticTasks,
    monitoringIndicators: plan.monitoringIndicators,
    assessmentInstruments: plan.assessmentInstruments ?? const [],
    measurementFrequency: plan.measurementFrequency,
    scheduledReassessments: _parseReassessments(plan.scheduledReassessments),
    observations: plan.observations,
    availableResources: plan.availableResources,
    supportNetwork: plan.supportNetwork,
    status: _mapStatusFromString(plan.status),
    reviewedAt: plan.reviewedAt?.toLocal(),
    createdAt: plan.createdAt?.toLocal() ?? DateTime.now(),
    updatedAt: plan.updatedAt?.toLocal() ?? DateTime.now(),
  );
}

/// Mapper para converter TherapeuticPlan do domínio do frontend para o common package (backend)
common.TherapeuticPlan mapToCommonPlan(domain.TherapeuticPlan plan) {
  return common.TherapeuticPlan(
    id: int.tryParse(plan.id),
    patientId: int.parse(plan.patientId),
    therapistId: int.parse(plan.therapistId),
    approach: _mapApproachToString(plan.approach),
    approachOther: plan.approachOther,
    recommendedFrequency: plan.recommendedFrequency,
    sessionDurationMinutes: plan.sessionDurationMinutes,
    estimatedDurationMonths: plan.estimatedDurationMonths,
    mainTechniques: plan.mainTechniques.isNotEmpty ? plan.mainTechniques : null,
    interventionStrategies: plan.interventionStrategies,
    resourcesToUse: plan.resourcesToUse,
    therapeuticTasks: plan.therapeuticTasks,
    monitoringIndicators: plan.monitoringIndicators,
    assessmentInstruments: plan.assessmentInstruments.isNotEmpty ? plan.assessmentInstruments : null,
    measurementFrequency: plan.measurementFrequency,
    scheduledReassessments: plan.scheduledReassessments.isNotEmpty ? plan.scheduledReassessments : null,
    observations: plan.observations,
    availableResources: plan.availableResources,
    supportNetwork: plan.supportNetwork,
    status: _mapStatusToString(plan.status),
    reviewedAt: plan.reviewedAt?.toUtc(),
    createdAt: plan.createdAt.toUtc(),
    updatedAt: plan.updatedAt.toUtc(),
  );
}

/// Mapper para converter TherapeuticObjective do common package (backend) para o modelo de domínio do frontend
domain_obj.TherapeuticObjective mapToDomainObjective(common.TherapeuticObjective objective) {
  return domain_obj.TherapeuticObjective(
    id: objective.id?.toString() ?? '',
    therapeuticPlanId: objective.therapeuticPlanId.toString(),
    patientId: objective.patientId.toString(),
    therapistId: objective.therapistId.toString(),
    description: objective.description,
    specificAspect: objective.specificAspect,
    measurableCriteria: objective.measurableCriteria,
    achievableConditions: objective.achievableConditions,
    relevantJustification: objective.relevantJustification,
    timeBoundDeadline: objective.timeBoundDeadline,
    deadlineType: _mapDeadlineTypeFromString(objective.deadlineType),
    priority: _mapPriorityFromString(objective.priority),
    status: _mapObjectiveStatusFromString(objective.status),
    progressPercentage: objective.progressPercentage,
    progressIndicators: objective.progressIndicators,
    successMetric: objective.successMetric,
    measurableGoals: _parseListOfMaps(objective.measurableGoals),
    relatedInterventions: _parseListOfMaps(objective.relatedInterventions),
    targetDate: objective.targetDate?.toLocal(),
    startedAt: objective.startedAt?.toLocal(),
    completedAt: objective.completedAt?.toLocal(),
    abandonedAt: objective.abandonedAt?.toLocal(),
    abandonedReason: objective.abandonedReason,
    notes: objective.notes,
    displayOrder: objective.displayOrder,
    createdAt: objective.createdAt?.toLocal() ?? DateTime.now(),
    updatedAt: objective.updatedAt?.toLocal() ?? DateTime.now(),
  );
}

/// Mapper para converter TherapeuticObjective do domínio do frontend para o common package (backend)
common.TherapeuticObjective mapToCommonObjective(domain_obj.TherapeuticObjective objective) {
  return common.TherapeuticObjective(
    id: int.tryParse(objective.id),
    therapeuticPlanId: int.parse(objective.therapeuticPlanId),
    patientId: int.parse(objective.patientId),
    therapistId: int.parse(objective.therapistId),
    description: objective.description,
    specificAspect: objective.specificAspect,
    measurableCriteria: objective.measurableCriteria,
    achievableConditions: objective.achievableConditions,
    relevantJustification: objective.relevantJustification,
    timeBoundDeadline: objective.timeBoundDeadline,
    deadlineType: _mapDeadlineTypeToString(objective.deadlineType),
    priority: _mapPriorityToString(objective.priority),
    status: _mapObjectiveStatusToString(objective.status),
    progressPercentage: objective.progressPercentage,
    progressIndicators: objective.progressIndicators,
    successMetric: objective.successMetric,
    measurableGoals: objective.measurableGoals.isNotEmpty ? objective.measurableGoals : null,
    relatedInterventions: objective.relatedInterventions.isNotEmpty ? objective.relatedInterventions : null,
    targetDate: objective.targetDate?.toUtc(),
    startedAt: objective.startedAt?.toUtc(),
    completedAt: objective.completedAt?.toUtc(),
    abandonedAt: objective.abandonedAt?.toUtc(),
    abandonedReason: objective.abandonedReason,
    notes: objective.notes,
    displayOrder: objective.displayOrder,
    createdAt: objective.createdAt.toUtc(),
    updatedAt: objective.updatedAt.toUtc(),
  );
}

// Helper functions for enums

domain.TherapeuticApproach _mapApproachFromString(String approach) {
  switch (approach.toLowerCase().replaceAll('_', '')) {
    case 'cognitivebehavioral':
      return domain.TherapeuticApproach.cognitiveBehavioral;
    case 'psychodynamic':
      return domain.TherapeuticApproach.psychodynamic;
    case 'humanistic':
      return domain.TherapeuticApproach.humanistic;
    case 'systemic':
      return domain.TherapeuticApproach.systemic;
    case 'existential':
      return domain.TherapeuticApproach.existential;
    case 'gestalt':
      return domain.TherapeuticApproach.gestalt;
    case 'integrative':
      return domain.TherapeuticApproach.integrative;
    case 'other':
      return domain.TherapeuticApproach.other;
  }
  return domain.TherapeuticApproach.cognitiveBehavioral;
}

String _mapApproachToString(domain.TherapeuticApproach approach) {
  switch (approach) {
    case domain.TherapeuticApproach.cognitiveBehavioral:
      return 'cognitive_behavioral';
    case domain.TherapeuticApproach.psychodynamic:
      return 'psychodynamic';
    case domain.TherapeuticApproach.humanistic:
      return 'humanistic';
    case domain.TherapeuticApproach.systemic:
      return 'systemic';
    case domain.TherapeuticApproach.existential:
      return 'existential';
    case domain.TherapeuticApproach.gestalt:
      return 'gestalt';
    case domain.TherapeuticApproach.integrative:
      return 'integrative';
    case domain.TherapeuticApproach.other:
      return 'other';
  }
}

domain.TherapeuticPlanStatus _mapStatusFromString(String status) {
  switch (status.toLowerCase()) {
    case 'draft':
      return domain.TherapeuticPlanStatus.draft;
    case 'active':
      return domain.TherapeuticPlanStatus.active;
    case 'reviewing':
      return domain.TherapeuticPlanStatus.reviewing;
    case 'completed':
      return domain.TherapeuticPlanStatus.completed;
    case 'archived':
      return domain.TherapeuticPlanStatus.archived;
  }
  return domain.TherapeuticPlanStatus.draft;
}

String _mapStatusToString(domain.TherapeuticPlanStatus status) {
  switch (status) {
    case domain.TherapeuticPlanStatus.draft:
      return 'draft';
    case domain.TherapeuticPlanStatus.active:
      return 'active';
    case domain.TherapeuticPlanStatus.reviewing:
      return 'reviewing';
    case domain.TherapeuticPlanStatus.completed:
      return 'completed';
    case domain.TherapeuticPlanStatus.archived:
      return 'archived';
  }
}

domain_obj.ObjectiveDeadlineType _mapDeadlineTypeFromString(String type) {
  switch (type.toLowerCase().replaceAll('_', '')) {
    case 'shortterm':
      return domain_obj.ObjectiveDeadlineType.shortTerm;
    case 'mediumterm':
      return domain_obj.ObjectiveDeadlineType.mediumTerm;
    case 'longterm':
      return domain_obj.ObjectiveDeadlineType.longTerm;
  }
  return domain_obj.ObjectiveDeadlineType.mediumTerm;
}

String _mapDeadlineTypeToString(domain_obj.ObjectiveDeadlineType type) {
  return switch (type) {
    domain_obj.ObjectiveDeadlineType.shortTerm => 'short_term',
    domain_obj.ObjectiveDeadlineType.mediumTerm => 'medium_term',
    domain_obj.ObjectiveDeadlineType.longTerm => 'long_term',
  };
}

domain_obj.ObjectivePriority _mapPriorityFromString(String priority) {
  switch (priority.toLowerCase()) {
    case 'low':
      return domain_obj.ObjectivePriority.low;
    case 'medium':
      return domain_obj.ObjectivePriority.medium;
    case 'high':
      return domain_obj.ObjectivePriority.high;
    case 'urgent':
      return domain_obj.ObjectivePriority.urgent;
  }
  return domain_obj.ObjectivePriority.medium;
}

String _mapPriorityToString(domain_obj.ObjectivePriority priority) {
  return switch (priority) {
    domain_obj.ObjectivePriority.low => 'low',
    domain_obj.ObjectivePriority.medium => 'medium',
    domain_obj.ObjectivePriority.high => 'high',
    domain_obj.ObjectivePriority.urgent => 'urgent',
  };
}

domain_obj.ObjectiveStatus _mapObjectiveStatusFromString(String status) {
  switch (status.toLowerCase().replaceAll('_', '')) {
    case 'pending':
      return domain_obj.ObjectiveStatus.pending;
    case 'inprogress':
      return domain_obj.ObjectiveStatus.inProgress;
    case 'completed':
      return domain_obj.ObjectiveStatus.completed;
    case 'abandoned':
      return domain_obj.ObjectiveStatus.abandoned;
    case 'onhold':
      return domain_obj.ObjectiveStatus.onHold;
  }
  return domain_obj.ObjectiveStatus.pending;
}

String _mapObjectiveStatusToString(domain_obj.ObjectiveStatus status) {
  return switch (status) {
    domain_obj.ObjectiveStatus.pending => 'pending',
    domain_obj.ObjectiveStatus.inProgress => 'in_progress',
    domain_obj.ObjectiveStatus.completed => 'completed',
    domain_obj.ObjectiveStatus.abandoned => 'abandoned',
    domain_obj.ObjectiveStatus.onHold => 'on_hold',
  };
}

// Helper functions for parsing

List<Map<String, dynamic>> _parseReassessments(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().cast<Map<String, dynamic>>().toList();
  }
  return const [];
}

List<Map<String, dynamic>> _parseListOfMaps(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().cast<Map<String, dynamic>>().toList();
  }
  return const [];
}
