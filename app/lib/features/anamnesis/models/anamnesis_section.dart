import 'package:equatable/equatable.dart';
import 'anamnesis_field.dart';

class AnamnesisSection extends Equatable {
  final String id;
  final String title;
  final String? description;
  final int order;
  final bool collapsible;
  final bool collapsedByDefault;
  final Map<String, dynamic>? conditional;
  final List<AnamnesisField> fields;

  const AnamnesisSection({
    required this.id,
    required this.title,
    this.description,
    required this.order,
    this.collapsible = false,
    this.collapsedByDefault = false,
    this.conditional,
    required this.fields,
  });

  factory AnamnesisSection.fromJson(Map<String, dynamic> json) {
    List<AnamnesisField> _parseFields(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value
            .map((e) => AnamnesisField.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return AnamnesisSection(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      order: json['order'] as int? ?? 0,
      collapsible: json['collapsible'] == true,
      collapsedByDefault: json['collapsed_by_default'] == true || json['collapsedByDefault'] == true,
      conditional: json['conditional'] as Map<String, dynamic>?,
      fields: _parseFields(json['fields']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      'order': order,
      'collapsible': collapsible,
      'collapsed_by_default': collapsedByDefault,
      if (conditional != null) 'conditional': conditional,
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        order,
        collapsible,
        collapsedByDefault,
        conditional,
        fields,
      ];
}

