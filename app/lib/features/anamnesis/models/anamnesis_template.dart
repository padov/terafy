import 'package:equatable/equatable.dart';
import 'anamnesis_section.dart';

class AnamnesisTemplate extends Equatable {
  final String id;
  final String? therapistId;
  final String name;
  final String? description;
  final String? category; // 'adult', 'child', 'couple', 'family', 'custom'
  final bool isDefault;
  final bool isSystem;
  final List<AnamnesisSection> sections;
  final Map<String, dynamic> settings;

  const AnamnesisTemplate({
    required this.id,
    this.therapistId,
    required this.name,
    this.description,
    this.category,
    this.isDefault = false,
    this.isSystem = false,
    required this.sections,
    this.settings = const {},
  });

  bool get isSystemTemplate => isSystem;
  bool get isPersonalTemplate => therapistId != null && !isSystem;

  factory AnamnesisTemplate.fromJson(Map<String, dynamic> json) {
    List<AnamnesisSection> _parseSections(dynamic structure) {
      if (structure == null) return [];
      if (structure is Map<String, dynamic>) {
        final sectionsData = structure['sections'];
        if (sectionsData is List) {
          return sectionsData
              .map((e) => AnamnesisSection.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));
        }
      }
      return [];
    }

    Map<String, dynamic> _parseSettings(dynamic structure) {
      if (structure == null) return {};
      if (structure is Map<String, dynamic>) {
        return structure['settings'] as Map<String, dynamic>? ?? {};
      }
      return {};
    }

    final structure = json['structure'] as Map<String, dynamic>? ?? {};

    return AnamnesisTemplate(
      id: json['id']?.toString() ?? '',
      therapistId: json['therapistId']?.toString() ?? json['therapist_id']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      isDefault: json['isDefault'] == true || json['is_default'] == true,
      isSystem: json['isSystem'] == true || json['is_system'] == true,
      sections: _parseSections(structure),
      settings: _parseSettings(structure),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'therapistId': therapistId,
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'isDefault': isDefault,
      'isSystem': isSystem,
      'structure': {
        'sections': sections.map((s) => s.toJson()).toList(),
        'settings': settings,
      },
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      if (therapistId != null) 'therapistId': therapistId,
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'isDefault': isDefault,
      'isSystem': isSystem,
      'structure': {
        'sections': sections.map((s) => s.toJson()).toList(),
        'settings': settings,
      },
    };
  }

  @override
  List<Object?> get props => [
        id,
        therapistId,
        name,
        description,
        category,
        isDefault,
        isSystem,
        sections,
        settings,
      ];
}

