import 'package:flutter/material.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_section.dart';
import 'anamnesis_field_widget.dart';

class AnamnesisSectionWidget extends StatefulWidget {
  final AnamnesisSection section;
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onDataChanged;

  const AnamnesisSectionWidget({
    super.key,
    required this.section,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<AnamnesisSectionWidget> createState() => _AnamnesisSectionWidgetState();
}

class _AnamnesisSectionWidgetState extends State<AnamnesisSectionWidget> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.section.collapsedByDefault;
  }

  void _updateField(String fieldId, dynamic value) {
    final updatedData = Map<String, dynamic>.from(widget.data);
    if (value == null) {
      updatedData.remove(fieldId);
    } else {
      updatedData[fieldId] = value;
    }
    widget.onDataChanged(updatedData);
  }

  @override
  Widget build(BuildContext context) {
    final sortedFields = List.from(widget.section.fields)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          if (widget.section.collapsible)
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.section.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          if (widget.section.description != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                widget.section.description!,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.section.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (widget.section.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.section.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
          if (_isExpanded || !widget.section.collapsible)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: sortedFields.map((field) {
                  return AnamnesisFieldWidget(
                    field: field,
                    value: widget.data[field.id],
                    onChanged: (value) => _updateField(field.id, value),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

