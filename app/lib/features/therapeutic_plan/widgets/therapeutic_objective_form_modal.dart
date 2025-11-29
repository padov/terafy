import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/therapeutic_plan/bloc/therapeutic_plan_bloc.dart';
import 'package:terafy/features/therapeutic_plan/bloc/therapeutic_plan_bloc_models.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_objective.dart';

class TherapeuticObjectiveFormModal extends StatefulWidget {
  final String therapeuticPlanId;
  final String patientId;
  final String therapistId;
  final TherapeuticObjective? objective; // Se fornecido, é modo edição

  const TherapeuticObjectiveFormModal({
    super.key,
    required this.therapeuticPlanId,
    required this.patientId,
    required this.therapistId,
    this.objective,
  });

  @override
  State<TherapeuticObjectiveFormModal> createState() =>
      _TherapeuticObjectiveFormModalState();
}

class _TherapeuticObjectiveFormModalState
    extends State<TherapeuticObjectiveFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Campos SMART obrigatórios
  final _descriptionController = TextEditingController();
  final _specificAspectController = TextEditingController();
  final _measurableCriteriaController = TextEditingController();

  // Campos SMART opcionais
  final _achievableConditionsController = TextEditingController();
  final _relevantJustificationController = TextEditingController();
  final _timeBoundDeadlineController = TextEditingController();

  // Classificação
  ObjectiveDeadlineType _deadlineType = ObjectiveDeadlineType.mediumTerm;
  ObjectivePriority _priority = ObjectivePriority.medium;
  ObjectiveStatus _status = ObjectiveStatus.pending;

  // Progresso
  int _progressPercentage = 0;
  final _successMetricController = TextEditingController();

  // Datas
  DateTime? _targetDate;

  // Observações
  final _notesController = TextEditingController();

  // Ordem
  int _displayOrder = 0;

  @override
  void initState() {
    super.initState();
    if (widget.objective != null) {
      _loadObjectiveData(widget.objective!);
    }
  }

  void _loadObjectiveData(TherapeuticObjective objective) {
    _descriptionController.text = objective.description;
    _specificAspectController.text = objective.specificAspect;
    _measurableCriteriaController.text = objective.measurableCriteria;
    _achievableConditionsController.text = objective.achievableConditions ?? '';
    _relevantJustificationController.text = objective.relevantJustification ?? '';
    _timeBoundDeadlineController.text = objective.timeBoundDeadline ?? '';
    _deadlineType = objective.deadlineType;
    _priority = objective.priority;
    _status = objective.status;
    _progressPercentage = objective.progressPercentage;
    _successMetricController.text = objective.successMetric ?? '';
    _targetDate = objective.targetDate;
    _notesController.text = objective.notes ?? '';
    _displayOrder = objective.displayOrder;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _descriptionController.dispose();
    _specificAspectController.dispose();
    _measurableCriteriaController.dispose();
    _achievableConditionsController.dispose();
    _relevantJustificationController.dispose();
    _timeBoundDeadlineController.dispose();
    _successMetricController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TherapeuticPlanBloc, TherapeuticPlanState>(
      listener: (context, state) {
        if (state is ObjectiveCreated || state is ObjectiveUpdated) {
          Navigator.of(context).pop(true);
        } else if (state is TherapeuticPlanError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.objective != null
                              ? 'Editar Objetivo'
                              : 'Novo Objetivo Terapêutico',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.offBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Preencha os campos SMART do objetivo',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campos SMART Obrigatórios
                      _buildSectionTitle('Campos SMART (Obrigatórios)'),
                      const SizedBox(height: 12),

                      // Descrição
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Descrição do Objetivo',
                        hint: 'Descreva o objetivo de forma clara e objetiva',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'A descrição é obrigatória';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Específico
                      _buildTextField(
                        controller: _specificAspectController,
                        label: 'Específico (S)',
                        hint: 'O que exatamente será alcançado?',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O aspecto específico é obrigatório';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Mensurável
                      _buildTextField(
                        controller: _measurableCriteriaController,
                        label: 'Mensurável (M)',
                        hint: 'Como será medido o progresso?',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'O critério mensurável é obrigatório';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Campos SMART Opcionais
                      _buildSectionTitle('Campos SMART (Opcionais)'),
                      const SizedBox(height: 12),

                      // Atingível
                      _buildTextField(
                        controller: _achievableConditionsController,
                        label: 'Atingível (A)',
                        hint: 'Condições para alcançar o objetivo',
                        maxLines: 2,
                      ),

                      const SizedBox(height: 12),

                      // Relevante
                      _buildTextField(
                        controller: _relevantJustificationController,
                        label: 'Relevante (R)',
                        hint: 'Por que este objetivo é importante?',
                        maxLines: 2,
                      ),

                      const SizedBox(height: 12),

                      // Temporal
                      _buildTextField(
                        controller: _timeBoundDeadlineController,
                        label: 'Temporal (T)',
                        hint: 'Prazo para alcançar o objetivo',
                      ),

                      const SizedBox(height: 24),

                      // Classificação
                      _buildSectionTitle('Classificação'),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown<ObjectiveDeadlineType>(
                              label: 'Prazo',
                              value: _deadlineType,
                              items: ObjectiveDeadlineType.values,
                              itemBuilder: (type) => _getDeadlineTypeLabel(type),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _deadlineType = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown<ObjectivePriority>(
                              label: 'Prioridade',
                              value: _priority,
                              items: ObjectivePriority.values,
                              itemBuilder: (priority) => _getPriorityLabel(priority),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _priority = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      if (widget.objective != null) ...[
                        const SizedBox(height: 12),
                        _buildDropdown<ObjectiveStatus>(
                          label: 'Status',
                          value: _status,
                          items: ObjectiveStatus.values,
                          itemBuilder: (status) => _getStatusLabel(status),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _status = value);
                            }
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Progresso
                      if (widget.objective != null) ...[
                        _buildSectionTitle('Progresso'),
                        const SizedBox(height: 12),
                        Text(
                          'Progresso: $_progressPercentage%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.offBlack,
                          ),
                        ),
                        Slider(
                          value: _progressPercentage.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: '$_progressPercentage%',
                          onChanged: (value) {
                            setState(() {
                              _progressPercentage = value.toInt();
                              if (_progressPercentage == 100) {
                                _status = ObjectiveStatus.completed;
                              } else if (_progressPercentage > 0) {
                                _status = ObjectiveStatus.inProgress;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Data Meta
                      _buildSectionTitle('Data Meta'),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _selectTargetDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Text(
                                _targetDate == null
                                    ? 'Selecione uma data meta'
                                    : DateFormat('dd/MM/yyyy').format(_targetDate!),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _targetDate == null
                                      ? Colors.grey[600]
                                      : AppColors.offBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Observações
                      _buildSectionTitle('Observações'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _notesController,
                        label: 'Notas',
                        hint: 'Observações adicionais sobre o objetivo',
                        maxLines: 3,
                      ),

                      const SizedBox(height: 32),

                      // Botões
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(color: AppColors.primary),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _saveObjective,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                widget.objective != null ? 'Atualizar' : 'Criar',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.offBlack,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.offBlack,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemBuilder,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.offBlack,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(itemBuilder(item)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.offBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  void _saveObjective() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final objective = TherapeuticObjective(
      id: widget.objective?.id ?? '',
      therapeuticPlanId: widget.therapeuticPlanId,
      patientId: widget.patientId,
      therapistId: widget.therapistId,
      description: _descriptionController.text.trim(),
      specificAspect: _specificAspectController.text.trim(),
      measurableCriteria: _measurableCriteriaController.text.trim(),
      achievableConditions: _achievableConditionsController.text.trim().isEmpty
          ? null
          : _achievableConditionsController.text.trim(),
      relevantJustification: _relevantJustificationController.text.trim().isEmpty
          ? null
          : _relevantJustificationController.text.trim(),
      timeBoundDeadline: _timeBoundDeadlineController.text.trim().isEmpty
          ? null
          : _timeBoundDeadlineController.text.trim(),
      deadlineType: _deadlineType,
      priority: _priority,
      status: widget.objective != null ? _status : ObjectiveStatus.pending,
      progressPercentage: widget.objective != null ? _progressPercentage : 0,
      successMetric: _successMetricController.text.trim().isEmpty
          ? null
          : _successMetricController.text.trim(),
      targetDate: _targetDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      displayOrder: _displayOrder,
      createdAt: widget.objective?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.objective != null) {
      context.read<TherapeuticPlanBloc>().add(UpdateObjective(objective));
    } else {
      context.read<TherapeuticPlanBloc>().add(CreateObjective(objective));
    }
  }

  String _getDeadlineTypeLabel(ObjectiveDeadlineType type) {
    switch (type) {
      case ObjectiveDeadlineType.shortTerm:
        return 'Curto Prazo';
      case ObjectiveDeadlineType.mediumTerm:
        return 'Médio Prazo';
      case ObjectiveDeadlineType.longTerm:
        return 'Longo Prazo';
    }
  }

  String _getPriorityLabel(ObjectivePriority priority) {
    switch (priority) {
      case ObjectivePriority.low:
        return 'Baixa';
      case ObjectivePriority.medium:
        return 'Média';
      case ObjectivePriority.high:
        return 'Alta';
      case ObjectivePriority.urgent:
        return 'Urgente';
    }
  }

  String _getStatusLabel(ObjectiveStatus status) {
    switch (status) {
      case ObjectiveStatus.pending:
        return 'Pendente';
      case ObjectiveStatus.inProgress:
        return 'Em Andamento';
      case ObjectiveStatus.completed:
        return 'Concluído';
      case ObjectiveStatus.abandoned:
        return 'Abandonado';
      case ObjectiveStatus.onHold:
        return 'Em Pausa';
    }
  }
}

