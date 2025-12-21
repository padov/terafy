class AiAnalysis {
  final String id;
  final int patientId;
  final int therapistId;
  final DateTime createdAt;
  final String analysisType; // 'session', 'overview', 'evolution', 'situation', 'therapeutic_plan'
  final String prompt;
  final String response;
  final String status; // 'completed', 'processing', 'error'
  final double? cost;
  final int? sessionId;
  final String? title; // Optional user-friendly title
  final String? errorMessage;
  final bool archived;

  const AiAnalysis({
    required this.id,
    required this.patientId,
    required this.therapistId,
    required this.createdAt,
    required this.analysisType,
    required this.prompt,
    required this.response,
    required this.status,
    this.cost,
    this.sessionId,
    this.title,
    this.errorMessage,
    this.archived = false,
  });

  factory AiAnalysis.fromJson(Map<String, dynamic> json) {
    return AiAnalysis(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id'] as int? ?? json['patientId'] as int? ?? 0,
      therapistId: json['therapist_id'] as int? ?? json['therapistId'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now()),
      analysisType:
          (json['analysis_type'] as String?) ??
          (json['analysisType'] as String?) ??
          (json['type'] as String?) ??
          'unknown',
      prompt: (json['prompt'] as String?) ?? '',
      response: (json['response'] as String?) ?? (json['result'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
      sessionId:
          json['session_id'] as int? ?? (json['sessionId'] != null ? int.tryParse(json['sessionId'].toString()) : null),
      title: json['title'] as String?,
      errorMessage: (json['error_message'] as String?) ?? (json['errorMessage'] as String?),
      archived: (json['archived'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'therapist_id': therapistId,
      'created_at': createdAt.toIso8601String(),
      'analysis_type': analysisType,
      'prompt': prompt,
      'response': response,
      'status': status,
      'cost': cost,
      'session_id': sessionId,
      'title': title,
      'error_message': errorMessage,
    };
  }

  String get typeLabel {
    switch (analysisType) {
      // Database enum values
      case 'individual_session_analysis':
        return 'Análise de Sessão';
      case 'patient_overview':
        return 'Visão Geral';
      case 'evolution_analysis':
        return 'Análise de Evolução';
      case 'specific_situation':
        return 'Situação Específica';
      case 'treatment_plan_generation':
        return 'Plano Terapêutico';
      // Legacy values for backward compatibility
      case 'session':
        return 'Análise de Sessão';
      case 'overview':
        return 'Visão Geral';
      case 'evolution':
        return 'Análise de Evolução';
      case 'situation':
        return 'Situação Específica';
      case 'therapeutic_plan':
        return 'Plano Terapêutico';
      default:
        return 'Análise';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Concluída';
      case 'processing':
        return 'Processando';
      case 'error':
        return 'Erro';
      default:
        return status;
    }
  }
}
