import 'dart:convert';

class TherapeuticPlan {
  final int? id;
  final int patientId;
  final int therapistId;

  // Abordagem terapêutica
  final String approach; // therapeutic_approach enum
  final String? approachOther; // Para quando approach = 'other'

  // Informações do plano
  final String? recommendedFrequency;
  final int? sessionDurationMinutes;
  final int? estimatedDurationMonths;

  // Estratégias e técnicas
  final List<String>? mainTechniques; // TEXT[]
  final String? interventionStrategies;
  final String? resourcesToUse;
  final String? therapeuticTasks;

  // Monitoramento
  final Map<String, dynamic>? monitoringIndicators; // JSONB
  final List<String>? assessmentInstruments; // TEXT[]
  final String? measurementFrequency;

  // Reavaliações programadas
  final List<dynamic>? scheduledReassessments; // JSONB array

  // Observações e recursos
  final String? observations;
  final String? availableResources;
  final String? supportNetwork;

  // Status e controle
  final String status; // therapeutic_plan_status enum
  final DateTime? reviewedAt;

  // Metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TherapeuticPlan({
    this.id,
    required this.patientId,
    required this.therapistId,
    required this.approach,
    this.approachOther,
    this.recommendedFrequency,
    this.sessionDurationMinutes,
    this.estimatedDurationMonths,
    this.mainTechniques,
    this.interventionStrategies,
    this.resourcesToUse,
    this.therapeuticTasks,
    this.monitoringIndicators,
    this.assessmentInstruments,
    this.measurementFrequency,
    this.scheduledReassessments,
    this.observations,
    this.availableResources,
    this.supportNetwork,
    this.status = 'draft',
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  // Getters úteis
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isDraft => status == 'draft';
  bool get isReviewing => status == 'reviewing';
  bool get isArchived => status == 'archived';

  TherapeuticPlan copyWith({
    int? id,
    int? patientId,
    int? therapistId,
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
    List<dynamic>? scheduledReassessments,
    String? observations,
    String? availableResources,
    String? supportNetwork,
    String? status,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'therapistId': therapistId,
      'approach': approach,
      'approachOther': approachOther,
      'recommendedFrequency': recommendedFrequency,
      'sessionDurationMinutes': sessionDurationMinutes,
      'estimatedDurationMonths': estimatedDurationMonths,
      'mainTechniques': mainTechniques,
      'interventionStrategies': interventionStrategies,
      'resourcesToUse': resourcesToUse,
      'therapeuticTasks': therapeuticTasks,
      'monitoringIndicators': monitoringIndicators,
      'assessmentInstruments': assessmentInstruments,
      'measurementFrequency': measurementFrequency,
      'scheduledReassessments': scheduledReassessments,
      'observations': observations,
      'availableResources': availableResources,
      'supportNetwork': supportNetwork,
      'status': status,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'patient_id': patientId,
      'therapist_id': therapistId,
      'approach': approach,
      'approach_other': approachOther,
      'recommended_frequency': recommendedFrequency,
      'session_duration_minutes': sessionDurationMinutes,
      'estimated_duration_months': estimatedDurationMonths,
      'main_techniques': mainTechniques,
      'intervention_strategies': interventionStrategies,
      'resources_to_use': resourcesToUse,
      'therapeutic_tasks': therapeuticTasks,
      'monitoring_indicators': monitoringIndicators != null ? jsonEncode(monitoringIndicators) : null,
      'assessment_instruments': assessmentInstruments,
      'measurement_frequency': measurementFrequency,
      'scheduled_reassessments': scheduledReassessments != null ? jsonEncode(scheduledReassessments) : null,
      'observations': observations,
      'available_resources': availableResources,
      'support_network': supportNetwork,
      'status': status,
      'reviewed_at': reviewedAt,
    };
  }

  factory TherapeuticPlan.fromJson(Map<String, dynamic> json) {
    return TherapeuticPlan(
      id: json['id'] as int?,
      patientId: json['patientId'] as int,
      therapistId: json['therapistId'] as int,
      approach: json['approach'] as String,
      approachOther: json['approachOther'] as String?,
      recommendedFrequency: json['recommendedFrequency'] as String?,
      sessionDurationMinutes: json['sessionDurationMinutes'] as int?,
      estimatedDurationMonths: json['estimatedDurationMonths'] as int?,
      mainTechniques: json['mainTechniques'] != null ? List<String>.from(json['mainTechniques'] as List) : null,
      interventionStrategies: json['interventionStrategies'] as String?,
      resourcesToUse: json['resourcesToUse'] as String?,
      therapeuticTasks: json['therapeuticTasks'] as String?,
      monitoringIndicators: json['monitoringIndicators'] as Map<String, dynamic>?,
      assessmentInstruments: json['assessmentInstruments'] != null
          ? List<String>.from(json['assessmentInstruments'] as List)
          : null,
      measurementFrequency: json['measurementFrequency'] as String?,
      scheduledReassessments: json['scheduledReassessments'] != null
          ? List<dynamic>.from(json['scheduledReassessments'] as List)
          : null,
      observations: json['observations'] as String?,
      availableResources: json['availableResources'] as String?,
      supportNetwork: json['supportNetwork'] as String?,
      status: json['status'] as String? ?? 'draft',
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  factory TherapeuticPlan.fromMap(Map<String, dynamic> map) {
    return TherapeuticPlan(
      id: _parseInt(map['id']),
      patientId: _parseInt(map['patient_id']) ?? 0,
      therapistId: _parseInt(map['therapist_id']) ?? 0,
      approach: map['approach']?.toString() ?? 'cognitive_behavioral',
      approachOther: map['approach_other'] as String?,
      recommendedFrequency: map['recommended_frequency'] as String?,
      sessionDurationMinutes: _parseInt(map['session_duration_minutes']),
      estimatedDurationMonths: _parseInt(map['estimated_duration_months']),
      mainTechniques: _parseStringList(map['main_techniques']),
      interventionStrategies: map['intervention_strategies'] as String?,
      resourcesToUse: map['resources_to_use'] as String?,
      therapeuticTasks: map['therapeutic_tasks'] as String?,
      monitoringIndicators: _parseJsonField(map['monitoring_indicators']),
      assessmentInstruments: _parseStringList(map['assessment_instruments']),
      measurementFrequency: map['measurement_frequency'] as String?,
      scheduledReassessments: _parseJsonArray(map['scheduled_reassessments']),
      observations: map['observations'] as String?,
      availableResources: map['available_resources'] as String?,
      supportNetwork: map['support_network'] as String?,
      status: _parseEnumField(map['status'], defaultValue: 'draft'),
      reviewedAt: _parseDate(map['reviewed_at']),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  // Helper methods
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
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

  static String _parseEnumField(dynamic value, {String defaultValue = 'draft'}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    try {
      return value.toString().trim();
    } catch (_) {
      return defaultValue;
    }
  }
}
