import 'dart:convert';

class Anamnesis {
  final int? id;
  final int patientId;
  final int therapistId;
  final int? templateId;
  final Map<String, dynamic> data;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Anamnesis({
    this.id,
    required this.patientId,
    required this.therapistId,
    this.templateId,
    required this.data,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Anamnesis copyWith({
    int? id,
    int? patientId,
    int? therapistId,
    int? templateId,
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

  Map<String, dynamic> toDatabaseMap() {
    return {
      'patient_id': patientId,
      'therapist_id': therapistId,
      'template_id': templateId,
      'data': jsonEncode(data),
      'completed_at': completedAt,
    };
  }

  factory Anamnesis.fromMap(Map<String, dynamic> map) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    Map<String, dynamic> _parseJsonField(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        } catch (_) {
          return {};
        }
      }
      return {};
    }

    return Anamnesis(
      id: map['id'] as int?,
      patientId: map['patient_id'] as int,
      therapistId: map['therapist_id'] as int,
      templateId: map['template_id'] as int?,
      data: _parseJsonField(map['data']),
      completedAt: _parseDate(map['completed_at']),
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }

  bool get isCompleted => completedAt != null;
}

