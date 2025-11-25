import 'package:equatable/equatable.dart';

class Anamnesis extends Equatable {
  final String id;
  final String patientId;
  final String therapistId;
  final String? templateId;
  final Map<String, dynamic> data;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Anamnesis({
    required this.id,
    required this.patientId,
    required this.therapistId,
    this.templateId,
    required this.data,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => completedAt != null;

  double get completionPercentage {
    if (data.isEmpty) return 0.0;
    // Calcula porcentagem baseado em campos preenchidos
    // Por enquanto retorna 0, pode ser melhorado depois
    return 0.0;
  }

  Anamnesis copyWith({
    String? id,
    String? patientId,
    String? therapistId,
    String? templateId,
    Map<String, dynamic>? data,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Anamnesis(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      therapistId: therapistId ?? this.therapistId,
      templateId: templateId ?? this.templateId,
      data: data ?? this.data,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Anamnesis.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    Map<String, dynamic> _parseData(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      return {};
    }

    return Anamnesis(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? json['patient_id']?.toString() ?? '',
      therapistId: json['therapistId']?.toString() ?? json['therapist_id']?.toString() ?? '',
      templateId: json['templateId']?.toString() ?? json['template_id']?.toString(),
      data: _parseData(json['data']),
      completedAt: _parseDate(json['completedAt'] ?? json['completed_at']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'therapistId': therapistId,
      'templateId': templateId,
      'data': data,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'patientId': patientId,
      'therapistId': therapistId,
      if (templateId != null) 'templateId': templateId,
      'data': data,
      if (completedAt != null) 'completedAt': completedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        therapistId,
        templateId,
        data,
        completedAt,
        createdAt,
        updatedAt,
      ];
}

