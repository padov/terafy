import 'package:flutter/material.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_field.dart';

class AnamnesisFieldWidget extends StatelessWidget {
  final AnamnesisField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const AnamnesisFieldWidget({
    super.key,
    required this.field,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (field.type == AnamnesisFieldType.sectionBreak) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(),
          if (field.description != null) _buildDescription(),
          const SizedBox(height: 8),
          _buildField(context),
          if (field.helpText != null) _buildHelpText(),
        ],
      ),
    );
  }

  Widget _buildLabel() {
    return Row(
      children: [
        Text(
          field.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.offBlack,
          ),
        ),
        if (field.required)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        field.description!,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildField(BuildContext context) {
    switch (field.type) {
      case AnamnesisFieldType.text:
        return _buildTextInput();
      case AnamnesisFieldType.textarea:
        return _buildTextArea();
      case AnamnesisFieldType.number:
        return _buildNumberInput();
      case AnamnesisFieldType.slider:
        return _buildSlider();
      case AnamnesisFieldType.boolean:
        return _buildBoolean();
      case AnamnesisFieldType.select:
        return _buildSelect();
      case AnamnesisFieldType.radio:
        return _buildRadio();
      case AnamnesisFieldType.checkboxGroup:
        return _buildCheckboxGroup();
      case AnamnesisFieldType.date:
        return _buildDatePicker(context);
      case AnamnesisFieldType.rating:
        return _buildRating();
      default:
        return _buildTextInput();
    }
  }

  Widget _buildTextInput() {
    return TextFormField(
      initialValue: value?.toString() ?? field.defaultValue?.toString() ?? '',
      decoration: _buildInputDecoration(
        hintText: field.placeholder ?? '',
      ),
      onChanged: (text) => onChanged(text.isEmpty ? null : text),
    );
  }

  Widget _buildTextArea() {
    return TextFormField(
      initialValue: value?.toString() ?? field.defaultValue?.toString() ?? '',
      decoration: _buildInputDecoration(
        hintText: field.placeholder ?? '',
      ),
      maxLines: field.rows ?? 4,
      onChanged: (text) => onChanged(text.isEmpty ? null : text),
    );
  }

  Widget _buildNumberInput() {
    return TextFormField(
      initialValue: value?.toString() ?? field.defaultValue?.toString() ?? '',
      decoration: _buildInputDecoration(
        hintText: field.placeholder ?? '',
      ),
      keyboardType: TextInputType.number,
      onChanged: (text) {
        if (text.isEmpty) {
          onChanged(null);
        } else {
          final num = int.tryParse(text) ?? double.tryParse(text);
          onChanged(num);
        }
      },
    );
  }

  Widget _buildSlider() {
    final currentValue = value ?? field.defaultValue ?? field.min ?? 0;
    final min = field.min ?? 0;
    final max = field.max ?? 10;
    final step = field.step ?? 1;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Slider(
                value: (currentValue is num ? currentValue.toDouble() : min.toDouble())
                    .clamp(min.toDouble(), max.toDouble()),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: step > 0 ? ((max - min) / step).round() : null,
                label: currentValue.toString(),
                activeColor: AppColors.primary,
                onChanged: (newValue) => onChanged(newValue.round()),
              ),
            ),
            if (field.showValue == true)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentValue.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        if (field.labels != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (field.labels!['min'] != null)
                Text(
                  field.labels!['min']!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              if (field.labels!['max'] != null)
                Text(
                  field.labels!['max']!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildBoolean() {
    final currentValue = value ?? field.defaultValue ?? false;

    return SwitchListTile(
      value: currentValue is bool ? currentValue : false,
      onChanged: (newValue) => onChanged(newValue),
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildSelect() {
    final options = field.options ?? [];
    final currentValue = value?.toString() ?? field.defaultValue?.toString();

    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: _buildInputDecoration(hintText: field.placeholder ?? 'Selecione...'),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option['value'],
          child: Text(option['label'] ?? option['value'] ?? ''),
        );
      }).toList(),
      onChanged: (newValue) => onChanged(newValue),
    );
  }

  Widget _buildRadio() {
    final options = field.options ?? [];
    final currentValue = value?.toString() ?? field.defaultValue?.toString();

    return Column(
      children: options.map((option) {
        final optionValue = option['value'] ?? '';
        return RadioListTile<String>(
          title: Text(option['label'] ?? optionValue),
          value: optionValue,
          groupValue: currentValue,
          onChanged: (newValue) => onChanged(newValue),
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Widget _buildCheckboxGroup() {
    final options = field.options ?? [];
    final currentValues = value is List
        ? (value as List).map((e) => e.toString()).toList()
        : <String>[];

    return Column(
      children: options.map((option) {
        final optionValue = option['value'] ?? '';
        final isSelected = currentValues.contains(optionValue);

        return CheckboxListTile(
          title: Text(option['label'] ?? optionValue),
          value: isSelected,
          onChanged: (checked) {
            final newValues = List<String>.from(currentValues);
            if (checked == true) {
              if (!newValues.contains(optionValue)) {
                newValues.add(optionValue);
              }
            } else {
              newValues.remove(optionValue);
            }
            onChanged(newValues);
          },
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    DateTime? date;
    if (value is DateTime) {
      date = value as DateTime;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: field.minDate != null
              ? (DateTime.tryParse(field.minDate!) ?? DateTime(1900))
              : DateTime(1900),
          lastDate: field.maxDate != null
              ? (DateTime.tryParse(field.maxDate!) ?? DateTime.now())
              : DateTime.now(),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String());
        }
      },
      child: InputDecorator(
        decoration: _buildInputDecoration(
          hintText: field.placeholder ?? 'Selecione uma data',
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : field.placeholder ?? 'Selecione uma data',
              style: TextStyle(
                color: date != null ? AppColors.offBlack : Colors.grey[600],
              ),
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRating() {
    final maxRating = field.max ?? 5;
    final currentRating = value is int ? value as int : (field.defaultValue ?? 0) as int;

    return Row(
      children: List.generate(maxRating, (index) {
        final rating = index + 1;
        return IconButton(
          icon: Icon(
            rating <= currentRating ? Icons.star : Icons.star_border,
            color: rating <= currentRating ? Colors.amber : Colors.grey,
            size: 32,
          ),
          onPressed: () => onChanged(rating),
        );
      }),
    );
  }

  Widget _buildHelpText() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        field.helpText!,
        style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

