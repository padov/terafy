import 'package:equatable/equatable.dart';

enum TherapeuticApproach {
  cognitiveBehavioral,
  psychodynamic,
  humanistic,
  systemic,
  existential,
  gestalt,
  integrative,
  other,
}

enum TherapeuticPlanStatus { draft, active, reviewing, completed, archived }

class TherapeuticPlan extends Equatable {
  final String id;
  final String patientId;
  final String therapistId;

  // Abordagem terapêutica
  final TherapeuticApproach approach;
  final String? approachOther;

  // Informações do plano
  final String? recommendedFrequency;
  final int? sessionDurationMinutes;
  final int? estimatedDurationMonths;

  // Estratégias e técnicas
  final List<String> mainTechniques;
  final String? interventionStrategies;
  final String? resourcesToUse;
  final String? therapeuticTasks;

  // Monitoramento
  final Map<String, dynamic>? monitoringIndicators;
  final List<String> assessmentInstruments;
  final String? measurementFrequency;

  // Reavaliações programadas
  final List<Map<String, dynamic>> scheduledReassessments;

  // Observações e recursos
  final String? observations;
  final String? availableResources;
  final String? supportNetwork;

  // Status e controle
  final TherapeuticPlanStatus status;
  final DateTime? reviewedAt;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const TherapeuticPlan({
    required this.id,
    required this.patientId,
    required this.therapistId,
    required this.approach,
    this.approachOther,
    this.recommendedFrequency,
    this.sessionDurationMinutes,
    this.estimatedDurationMonths,
    this.mainTechniques = const [],
    this.interventionStrategies,
    this.resourcesToUse,
    this.therapeuticTasks,
    this.monitoringIndicators,
    this.assessmentInstruments = const [],
    this.measurementFrequency,
    this.scheduledReassessments = const [],
    this.observations,
    this.availableResources,
    this.supportNetwork,
    this.status = TherapeuticPlanStatus.draft,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == TherapeuticPlanStatus.active;
  bool get isCompleted => status == TherapeuticPlanStatus.completed;
  bool get isDraft => status == TherapeuticPlanStatus.draft;
  bool get isReviewing => status == TherapeuticPlanStatus.reviewing;
  bool get isArchived => status == TherapeuticPlanStatus.archived;

  TherapeuticPlan copyWith({
    String? id,
    String? patientId,
    String? therapistId,
    TherapeuticApproach? approach,
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
    List<Map<String, dynamic>>? scheduledReassessments,
    String? observations,
    String? availableResources,
    String? supportNetwork,
    TherapeuticPlanStatus? status,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TherapeuticPlan(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      therapistId: therapistId ?? this.therapistId,
      approach: approach ?? this.approach,
      approachOther: approachOther ?? this.approachOther,
      recommendedFrequency: recommendedFrequency ?? this.recommendedFrequency,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      estimatedDurationMonths: estimatedDurationMonths ?? this.estimatedDurationMonths,
      mainTechniques: mainTechniques ?? this.mainTechniques,
      interventionStrategies: interventionStrategies ?? this.interventionStrategies,
      resourcesToUse: resourcesToUse ?? this.resourcesToUse,
      therapeuticTasks: therapeuticTasks ?? this.therapeuticTasks,
      monitoringIndicators: monitoringIndicators ?? this.monitoringIndicators,
      assessmentInstruments: assessmentInstruments ?? this.assessmentInstruments,
      measurementFrequency: measurementFrequency ?? this.measurementFrequency,
      scheduledReassessments: scheduledReassessments ?? this.scheduledReassessments,
      observations: observations ?? this.observations,
      availableResources: availableResources ?? this.availableResources,
      supportNetwork: supportNetwork ?? this.supportNetwork,
      status: status ?? this.status,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    therapistId,
    approach,
    approachOther,
    recommendedFrequency,
    sessionDurationMinutes,
    estimatedDurationMonths,
    mainTechniques,
    interventionStrategies,
    resourcesToUse,
    therapeuticTasks,
    monitoringIndicators,
    assessmentInstruments,
    measurementFrequency,
    scheduledReassessments,
    observations,
    availableResources,
    supportNetwork,
    status,
    reviewedAt,
    createdAt,
    updatedAt,
  ];
}
