enum AIAnalysisType {
  individualSessionAnalysis('individual_session_analysis'),
  patientOverview('patient_overview'),
  evolutionAnalysis('evolution_analysis'),
  specificSituation('specific_situation'),
  treatmentPlanGeneration('treatment_plan_generation');

  final String value;
  const AIAnalysisType(this.value);

  static AIAnalysisType fromString(String value) {
    return AIAnalysisType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid AI analysis type: $value'),
    );
  }
}

enum AIAnalysisStatus {
  pending('pending'),
  completed('completed'),
  failed('failed');

  final String value;
  const AIAnalysisStatus(this.value);

  static AIAnalysisStatus fromString(String value) {
    return AIAnalysisStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid AI analysis status: $value'),
    );
  }
}

class AIAnalysis {
  final int? id;
  final int therapistId;
  final int patientId;
  final AIAnalysisType type;
  final AIAnalysisStatus status;
  final String prompt;
  final String? result;
  final double cost;
  final String? errorMessage;
  final List<int> sessionIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool archived;

  AIAnalysis({
    this.id,
    required this.therapistId,
    required this.patientId,
    required this.type,
    required this.status,
    required this.prompt,
    this.result,
    this.cost = 0.0,
    this.errorMessage,
    this.sessionIds = const [],
    this.createdAt,
    this.updatedAt,
    this.archived = false,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      id: json['id'] as int?,
      therapistId: json['therapist_id'] as int,
      patientId: json['patient_id'] as int,
      type: AIAnalysisType.fromString(json['type'] as String),
      status: AIAnalysisStatus.fromString(json['status'] as String),
      prompt: json['prompt'] as String,
      result: json['result'] as String?,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      errorMessage: json['error_message'] as String?,
      sessionIds: json['session_ids'] != null ? List<int>.from(json['session_ids'] as List) : [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'therapist_id': therapistId,
      'patient_id': patientId,
      'type': type.value,
      'status': status.value,
      'prompt': prompt,
      'result': result,
      'cost': cost,
      'error_message': errorMessage,
      'session_ids': sessionIds,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'archived': archived,
    };
  }

  AIAnalysis copyWith({
    int? id,
    int? therapistId,
    int? patientId,
    AIAnalysisType? type,
    AIAnalysisStatus? status,
    String? prompt,
    String? result,
    double? cost,
    String? errorMessage,
    List<int>? sessionIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIAnalysis(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      status: status ?? this.status,
      prompt: prompt ?? this.prompt,
      result: result ?? this.result,
      cost: cost ?? this.cost,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionIds: sessionIds ?? this.sessionIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
