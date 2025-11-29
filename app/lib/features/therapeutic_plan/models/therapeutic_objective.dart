import 'package:equatable/equatable.dart';

enum ObjectiveDeadlineType { shortTerm, mediumTerm, longTerm }

enum ObjectivePriority { low, medium, high, urgent }

enum ObjectiveStatus { pending, inProgress, completed, abandoned, onHold }

class TherapeuticObjective extends Equatable {
  final String id;
  final String therapeuticPlanId;
  final String patientId;
  final String therapistId;

  // Descrição SMART do objetivo
  final String description;
  final String specificAspect;
  final String measurableCriteria;
  final String? achievableConditions;
  final String? relevantJustification;
  final String? timeBoundDeadline;

  // Classificação
  final ObjectiveDeadlineType deadlineType;
  final ObjectivePriority priority;
  final ObjectiveStatus status;

  // Progresso
  final int progressPercentage;
  final Map<String, dynamic>? progressIndicators;
  final String? successMetric;

  // Metas mensuráveis
  final List<Map<String, dynamic>> measurableGoals;

  // Intervenções relacionadas
  final List<Map<String, dynamic>> relatedInterventions;

  // Datas
  final DateTime? targetDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? abandonedAt;
  final String? abandonedReason;

  // Observações
  final String? notes;

  // Ordem de exibição
  final int displayOrder;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const TherapeuticObjective({
    required this.id,
    required this.therapeuticPlanId,
    required this.patientId,
    required this.therapistId,
    required this.description,
    required this.specificAspect,
    required this.measurableCriteria,
    this.achievableConditions,
    this.relevantJustification,
    this.timeBoundDeadline,
    this.deadlineType = ObjectiveDeadlineType.mediumTerm,
    this.priority = ObjectivePriority.medium,
    this.status = ObjectiveStatus.pending,
    this.progressPercentage = 0,
    this.progressIndicators,
    this.successMetric,
    this.measurableGoals = const [],
    this.relatedInterventions = const [],
    this.targetDate,
    this.startedAt,
    this.completedAt,
    this.abandonedAt,
    this.abandonedReason,
    this.notes,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == ObjectiveStatus.completed;
  bool get isInProgress => status == ObjectiveStatus.inProgress;
  bool get isPending => status == ObjectiveStatus.pending;
  bool get isAbandoned => status == ObjectiveStatus.abandoned;
  bool get isOnHold => status == ObjectiveStatus.onHold;

  TherapeuticObjective copyWith({
    String? id,
    String? therapeuticPlanId,
    String? patientId,
    String? therapistId,
    String? description,
    String? specificAspect,
    String? measurableCriteria,
    String? achievableConditions,
    String? relevantJustification,
    String? timeBoundDeadline,
    ObjectiveDeadlineType? deadlineType,
    ObjectivePriority? priority,
    ObjectiveStatus? status,
    int? progressPercentage,
    Map<String, dynamic>? progressIndicators,
    String? successMetric,
    List<Map<String, dynamic>>? measurableGoals,
    List<Map<String, dynamic>>? relatedInterventions,
    DateTime? targetDate,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? abandonedAt,
    String? abandonedReason,
    String? notes,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TherapeuticObjective(
      id: id ?? this.id,
      therapeuticPlanId: therapeuticPlanId ?? this.therapeuticPlanId,
      patientId: patientId ?? this.patientId,
      therapistId: therapistId ?? this.therapistId,
      description: description ?? this.description,
      specificAspect: specificAspect ?? this.specificAspect,
      measurableCriteria: measurableCriteria ?? this.measurableCriteria,
      achievableConditions: achievableConditions ?? this.achievableConditions,
      relevantJustification: relevantJustification ?? this.relevantJustification,
      timeBoundDeadline: timeBoundDeadline ?? this.timeBoundDeadline,
      deadlineType: deadlineType ?? this.deadlineType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      progressIndicators: progressIndicators ?? this.progressIndicators,
      successMetric: successMetric ?? this.successMetric,
      measurableGoals: measurableGoals ?? this.measurableGoals,
      relatedInterventions: relatedInterventions ?? this.relatedInterventions,
      targetDate: targetDate ?? this.targetDate,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      abandonedAt: abandonedAt ?? this.abandonedAt,
      abandonedReason: abandonedReason ?? this.abandonedReason,
      notes: notes ?? this.notes,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    therapeuticPlanId,
    patientId,
    therapistId,
    description,
    specificAspect,
    measurableCriteria,
    achievableConditions,
    relevantJustification,
    timeBoundDeadline,
    deadlineType,
    priority,
    status,
    progressPercentage,
    progressIndicators,
    successMetric,
    measurableGoals,
    relatedInterventions,
    targetDate,
    startedAt,
    completedAt,
    abandonedAt,
    abandonedReason,
    notes,
    displayOrder,
    createdAt,
    updatedAt,
  ];
}
