import 'dart:convert';

class TherapeuticObjective {
  final int? id;
  final int therapeuticPlanId;
  final int patientId;
  final int therapistId;

  // Descrição SMART do objetivo
  final String description; // Descrição geral do objetivo
  final String specificAspect; // Específico: o que exatamente será alcançado
  final String measurableCriteria; // Mensurável: como será medido
  final String? achievableConditions; // Alcançável: condições necessárias
  final String? relevantJustification; // Relevante: por que é importante
  final String? timeBoundDeadline; // Temporal: prazo ou marco temporal

  // Classificação
  final String deadlineType; // objective_deadline_type enum
  final String priority; // objective_priority enum
  final String status; // objective_status enum

  // Progresso
  final int progressPercentage; // 0-100
  final Map<String, dynamic>? progressIndicators; // JSONB
  final String? successMetric; // Métrica de sucesso do objetivo

  // Metas mensuráveis
  final List<dynamic>? measurableGoals; // JSONB array

  // Intervenções relacionadas
  final List<dynamic>? relatedInterventions; // JSONB array

  // Datas
  final DateTime? targetDate; // Data alvo para conclusão
  final DateTime? startedAt; // Quando foi iniciado
  final DateTime? completedAt; // Quando foi completado
  final DateTime? abandonedAt; // Quando foi abandonado
  final String? abandonedReason; // Razão do abandono

  // Observações
  final String? notes; // Notas adicionais sobre o objetivo

  // Ordem de exibição
  final int displayOrder; // Ordem de exibição na lista

  // Metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TherapeuticObjective({
    this.id,
    required this.therapeuticPlanId,
    required this.patientId,
    required this.therapistId,
    required this.description,
    required this.specificAspect,
    required this.measurableCriteria,
    this.achievableConditions,
    this.relevantJustification,
    this.timeBoundDeadline,
    this.deadlineType = 'medium_term',
    this.priority = 'medium',
    this.status = 'pending',
    this.progressPercentage = 0,
    this.progressIndicators,
    this.successMetric,
    this.measurableGoals,
    this.relatedInterventions,
    this.targetDate,
    this.startedAt,
    this.completedAt,
    this.abandonedAt,
    this.abandonedReason,
    this.notes,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  // Getters úteis
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isPending => status == 'pending';
  bool get isAbandoned => status == 'abandoned';
  bool get isOnHold => status == 'on_hold';

  TherapeuticObjective copyWith({
    int? id,
    int? therapeuticPlanId,
    int? patientId,
    int? therapistId,
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
    List<dynamic>? measurableGoals,
    List<dynamic>? relatedInterventions,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'therapeuticPlanId': therapeuticPlanId,
      'patientId': patientId,
      'therapistId': therapistId,
      'description': description,
      'specificAspect': specificAspect,
      'measurableCriteria': measurableCriteria,
      'achievableConditions': achievableConditions,
      'relevantJustification': relevantJustification,
      'timeBoundDeadline': timeBoundDeadline,
      'deadlineType': deadlineType,
      'priority': priority,
      'status': status,
      'progressPercentage': progressPercentage,
      'progressIndicators': progressIndicators,
      'successMetric': successMetric,
      'measurableGoals': measurableGoals,
      'relatedInterventions': relatedInterventions,
      'targetDate': targetDate?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'abandonedAt': abandonedAt?.toIso8601String(),
      'abandonedReason': abandonedReason,
      'notes': notes,
      'displayOrder': displayOrder,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'therapeutic_plan_id': therapeuticPlanId,
      'patient_id': patientId,
      'therapist_id': therapistId,
      'description': description,
      'specific_aspect': specificAspect,
      'measurable_criteria': measurableCriteria,
      'achievable_conditions': achievableConditions,
      'relevant_justification': relevantJustification,
      'time_bound_deadline': timeBoundDeadline,
      'deadline_type': deadlineType,
      'priority': priority,
      'status': status,
      'progress_percentage': progressPercentage,
      'progress_indicators': progressIndicators != null ? jsonEncode(progressIndicators) : null,
      'success_metric': successMetric,
      'measurable_goals': measurableGoals != null ? jsonEncode(measurableGoals) : null,
      'related_interventions': relatedInterventions != null ? jsonEncode(relatedInterventions) : null,
      'target_date': targetDate,
      'started_at': startedAt,
      'completed_at': completedAt,
      'abandoned_at': abandonedAt,
      'abandoned_reason': abandonedReason,
      'notes': notes,
      'display_order': displayOrder,
    };
  }

  factory TherapeuticObjective.fromJson(Map<String, dynamic> json) {
    return TherapeuticObjective(
      id: json['id'] as int?,
      therapeuticPlanId: json['therapeuticPlanId'] as int,
      patientId: json['patientId'] as int,
      therapistId: json['therapistId'] as int,
      description: json['description'] as String,
      specificAspect: json['specificAspect'] as String,
      measurableCriteria: json['measurableCriteria'] as String,
      achievableConditions: json['achievableConditions'] as String?,
      relevantJustification: json['relevantJustification'] as String?,
      timeBoundDeadline: json['timeBoundDeadline'] as String?,
      deadlineType: json['deadlineType'] as String? ?? 'medium_term',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      progressPercentage: json['progressPercentage'] as int? ?? 0,
      progressIndicators: json['progressIndicators'] as Map<String, dynamic>?,
      successMetric: json['successMetric'] as String?,
      measurableGoals: json['measurableGoals'] != null ? List<dynamic>.from(json['measurableGoals'] as List) : null,
      relatedInterventions: json['relatedInterventions'] != null
          ? List<dynamic>.from(json['relatedInterventions'] as List)
          : null,
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate'] as String) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      abandonedAt: json['abandonedAt'] != null ? DateTime.parse(json['abandonedAt'] as String) : null,
      abandonedReason: json['abandonedReason'] as String?,
      notes: json['notes'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  factory TherapeuticObjective.fromMap(Map<String, dynamic> map) {
    return TherapeuticObjective(
      id: _parseInt(map['id']),
      therapeuticPlanId: _parseInt(map['therapeutic_plan_id']) ?? 0,
      patientId: _parseInt(map['patient_id']) ?? 0,
      therapistId: _parseInt(map['therapist_id']) ?? 0,
      description: map['description'] as String? ?? '',
      specificAspect: map['specific_aspect'] as String? ?? '',
      measurableCriteria: map['measurable_criteria'] as String? ?? '',
      achievableConditions: map['achievable_conditions'] as String?,
      relevantJustification: map['relevant_justification'] as String?,
      timeBoundDeadline: map['time_bound_deadline'] as String?,
      deadlineType: _parseEnumField(map['deadline_type'], defaultValue: 'medium_term'),
      priority: _parseEnumField(map['priority'], defaultValue: 'medium'),
      status: _parseEnumField(map['status'], defaultValue: 'pending'),
      progressPercentage: _parseInt(map['progress_percentage']) ?? 0,
      progressIndicators: _parseJsonField(map['progress_indicators']),
      successMetric: map['success_metric'] as String?,
      measurableGoals: _parseJsonArray(map['measurable_goals']),
      relatedInterventions: _parseJsonArray(map['related_interventions']),
      targetDate: _parseDate(map['target_date']),
      startedAt: _parseDate(map['started_at']),
      completedAt: _parseDate(map['completed_at']),
      abandonedAt: _parseDate(map['abandoned_at']),
      abandonedReason: map['abandoned_reason'] as String?,
      notes: map['notes'] as String?,
      displayOrder: _parseInt(map['display_order']) ?? 0,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  // Helper methods
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    // Para campos DATE do PostgreSQL
    if (value is String) {
      // Tenta parsear como ISO8601 primeiro
      final dateTime = DateTime.tryParse(value);
      if (dateTime != null) return dateTime;
      // Se não funcionar, tenta como DATE (YYYY-MM-DD)
      final parts = value.split(' ');
      if (parts.isNotEmpty) {
        return DateTime.tryParse(parts[0]);
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static Map<String, dynamic>? _parseJsonField(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<dynamic>? _parseJsonArray(dynamic value) {
    if (value == null) return null;
    if (value is List) return value;
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _parseEnumField(dynamic value, {String defaultValue = 'pending'}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    try {
      return value.toString().trim();
    } catch (_) {
      return defaultValue;
    }
  }
}
