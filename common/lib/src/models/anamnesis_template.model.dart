import 'dart:convert';

class AnamnesisTemplate {
  final int? id;
  final int? therapistId; // null = template do sistema
  final String name;
  final String? description;
  final String? category; // 'adult', 'child', 'couple', 'family', 'custom'
  final bool isDefault;
  final bool isSystem;
  final Map<String, dynamic> structure;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AnamnesisTemplate({
    this.id,
    this.therapistId,
    required this.name,
    this.description,
    this.category,
    this.isDefault = false,
    this.isSystem = false,
    required this.structure,
    required this.createdAt,
    required this.updatedAt,
  });

  AnamnesisTemplate copyWith({
    int? id,
    int? therapistId,
    String? name,
    String? description,
    String? category,
    bool? isDefault,
    bool? isSystem,
    Map<String, dynamic>? structure,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnamnesisTemplate(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isDefault: isDefault ?? this.isDefault,
      isSystem: isSystem ?? this.isSystem,
      structure: structure ?? this.structure,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'therapistId': therapistId,
      'name': name,
      'description': description,
      'category': category,
      'isDefault': isDefault,
      'isSystem': isSystem,
      'structure': structure,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'therapist_id': therapistId,
      'name': name,
      'description': description,
      'category': category,
      'is_default': isDefault,
      'is_system': isSystem,
      'structure': jsonEncode(structure),
    };
  }

  factory AnamnesisTemplate.fromMap(Map<String, dynamic> map) {
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

    return AnamnesisTemplate(
      id: map['id'] as int?,
      therapistId: map['therapist_id'] as int?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      category: map['category'] as String?,
      isDefault: (map['is_default'] as bool?) ?? false,
      isSystem: (map['is_system'] as bool?) ?? false,
      structure: _parseJsonField(map['structure']),
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']) ?? DateTime.now(),
    );
  }
}

