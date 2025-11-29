import 'package:equatable/equatable.dart';

enum AnamnesisFieldType {
  text,
  textarea,
  number,
  slider,
  boolean,
  select,
  radio,
  checkboxGroup,
  date,
  time,
  datetime,
  file,
  rating,
  sectionBreak,
}

class AnamnesisField extends Equatable {
  final String id;
  final AnamnesisFieldType type;
  final String label;
  final String? description;
  final bool required;
  final int order;
  final String? placeholder;
  final dynamic defaultValue;
  final Map<String, dynamic>? validation;
  final Map<String, dynamic>? conditional;
  final List<String>? fillableBy;
  final bool sensitive;
  final bool canSkip;
  final String? helpText;

  // Campos específicos por tipo
  final int? min;
  final int? max;
  final int? step;
  final bool? showValue;
  final Map<String, String>? labels;
  final List<Map<String, String>>? options;
  final bool? multiple;
  final bool? searchable;
  final String? layout;
  final int? minSelections;
  final int? maxSelections;
  final String? format;
  final String? minDate;
  final String? maxDate;
  final List<String>? accept;
  final int? maxSize;
  final int? rows;
  final String? displayAs;

  const AnamnesisField({
    required this.id,
    required this.type,
    required this.label,
    this.description,
    this.required = false,
    this.order = 0,
    this.placeholder,
    this.defaultValue,
    this.validation,
    this.conditional,
    this.fillableBy,
    this.sensitive = false,
    this.canSkip = false,
    this.helpText,
    this.min,
    this.max,
    this.step,
    this.showValue,
    this.labels,
    this.options,
    this.multiple,
    this.searchable,
    this.layout,
    this.minSelections,
    this.maxSelections,
    this.format,
    this.minDate,
    this.maxDate,
    this.accept,
    this.maxSize,
    this.rows,
    this.displayAs,
  });

  factory AnamnesisField.fromJson(Map<String, dynamic> json) {
    AnamnesisFieldType _parseType(String? type) {
      switch (type) {
        case 'text':
          return AnamnesisFieldType.text;
        case 'textarea':
          return AnamnesisFieldType.textarea;
        case 'number':
          return AnamnesisFieldType.number;
        case 'slider':
          return AnamnesisFieldType.slider;
        case 'boolean':
          return AnamnesisFieldType.boolean;
        case 'select':
          return AnamnesisFieldType.select;
        case 'radio':
          return AnamnesisFieldType.radio;
        case 'checkbox_group':
          return AnamnesisFieldType.checkboxGroup;
        case 'date':
          return AnamnesisFieldType.date;
        case 'time':
          return AnamnesisFieldType.time;
        case 'datetime':
          return AnamnesisFieldType.datetime;
        case 'file':
          return AnamnesisFieldType.file;
        case 'rating':
          return AnamnesisFieldType.rating;
        case 'section_break':
          return AnamnesisFieldType.sectionBreak;
        default:
          return AnamnesisFieldType.text;
      }
    }

    List<Map<String, String>>? _parseOptions(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value
            .map((e) {
              if (e is Map<String, dynamic>) {
                return {
                  'value': e['value']?.toString() ?? '',
                  'label': e['label']?.toString() ?? e['value']?.toString() ?? '',
                };
              }
              return {'value': e.toString(), 'label': e.toString()};
            })
            .toList();
      }
      return null;
    }

    List<String>? _parseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }

    Map<String, String>? _parseStringMap(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) {
        return value.map((k, v) => MapEntry(k, v.toString()));
      }
      return null;
    }

    return AnamnesisField(
      id: json['id']?.toString() ?? '',
      type: _parseType(json['type']?.toString()),
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString(),
      required: json['required'] == true,
      order: json['order'] as int? ?? 0,
      placeholder: json['placeholder']?.toString(),
      defaultValue: json['default_value'] ?? json['defaultValue'],
      validation: json['validation'] as Map<String, dynamic>?,
      conditional: json['conditional'] as Map<String, dynamic>?,
      fillableBy: _parseStringList(json['fillable_by'] ?? json['fillableBy']),
      sensitive: json['sensitive'] == true,
      canSkip: json['can_skip'] == true || json['canSkip'] == true,
      helpText: json['help_text']?.toString() ?? json['helpText']?.toString(),
      min: json['min'] as int?,
      max: json['max'] as int?,
      step: json['step'] as int?,
      showValue: json['show_value'] as bool? ?? json['showValue'] as bool?,
      labels: _parseStringMap(json['labels']),
      options: _parseOptions(json['options']),
      multiple: json['multiple'] as bool?,
      searchable: json['searchable'] as bool?,
      layout: json['layout']?.toString(),
      minSelections: json['min_selections'] as int? ?? json['minSelections'] as int?,
      maxSelections: json['max_selections'] as int? ?? json['maxSelections'] as int?,
      format: json['format']?.toString(),
      minDate: json['min_date']?.toString() ?? json['minDate']?.toString(),
      maxDate: json['max_date']?.toString() ?? json['maxDate']?.toString(),
      accept: _parseStringList(json['accept']),
      maxSize: json['max_size'] as int? ?? json['maxSize'] as int?,
      rows: json['rows'] as int?,
      displayAs: json['display_as']?.toString() ?? json['displayAs']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    String _typeToString(AnamnesisFieldType type) {
      switch (type) {
        case AnamnesisFieldType.text:
          return 'text';
        case AnamnesisFieldType.textarea:
          return 'textarea';
        case AnamnesisFieldType.number:
          return 'number';
        case AnamnesisFieldType.slider:
          return 'slider';
        case AnamnesisFieldType.boolean:
          return 'boolean';
        case AnamnesisFieldType.select:
          return 'select';
        case AnamnesisFieldType.radio:
          return 'radio';
        case AnamnesisFieldType.checkboxGroup:
          return 'checkbox_group';
        case AnamnesisFieldType.date:
          return 'date';
        case AnamnesisFieldType.time:
          return 'time';
        case AnamnesisFieldType.datetime:
          return 'datetime';
        case AnamnesisFieldType.file:
          return 'file';
        case AnamnesisFieldType.rating:
          return 'rating';
        case AnamnesisFieldType.sectionBreak:
          return 'section_break';
      }
    }

    return {
      'id': id,
      'type': _typeToString(type),
      'label': label,
      if (description != null) 'description': description,
      'required': required,
      'order': order,
      if (placeholder != null) 'placeholder': placeholder,
      if (defaultValue != null) 'default_value': defaultValue,
      if (validation != null) 'validation': validation,
      if (conditional != null) 'conditional': conditional,
      if (fillableBy != null) 'fillable_by': fillableBy,
      'sensitive': sensitive,
      'can_skip': canSkip,
      if (helpText != null) 'help_text': helpText,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (step != null) 'step': step,
      if (showValue != null) 'show_value': showValue,
      if (labels != null) 'labels': labels,
      if (options != null) 'options': options,
      if (multiple != null) 'multiple': multiple,
      if (searchable != null) 'searchable': searchable,
      if (layout != null) 'layout': layout,
      if (minSelections != null) 'min_selections': minSelections,
      if (maxSelections != null) 'max_selections': maxSelections,
      if (format != null) 'format': format,
      if (minDate != null) 'min_date': minDate,
      if (maxDate != null) 'max_date': maxDate,
      if (accept != null) 'accept': accept,
      if (maxSize != null) 'max_size': maxSize,
      if (rows != null) 'rows': rows,
      if (displayAs != null) 'display_as': displayAs,
    };
  }

  @override
  List<Object?> get props => [
        id,
        type,
        label,
        description,
        required,
        order,
        placeholder,
        defaultValue,
        validation,
        conditional,
        fillableBy,
        sensitive,
        canSkip,
        helpText,
        min,
        max,
        step,
        showValue,
        labels,
        options,
        multiple,
        searchable,
        layout,
        minSelections,
        maxSelections,
        format,
        minDate,
        maxDate,
        accept,
        maxSize,
        rows,
        displayAs,
      ];
}

