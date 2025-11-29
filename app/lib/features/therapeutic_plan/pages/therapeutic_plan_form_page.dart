import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/therapeutic_plan/bloc/therapeutic_plan_bloc.dart';
import 'package:terafy/features/therapeutic_plan/bloc/therapeutic_plan_bloc_models.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan.dart';

class TherapeuticPlanFormPage extends StatelessWidget {
  final String patientId;
  final String? patientName;
  final TherapeuticPlan? plan; // Se fornecido, é modo edição

  const TherapeuticPlanFormPage({
    super.key,
    required this.patientId,
    this.patientName,
    this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final container = DependencyContainer();
    final isEditing = plan != null;

    return BlocProvider(
      create: (context) => TherapeuticPlanBloc(
        getPlansUseCase: container.getPlansUseCase,
        getPlanUseCase: container.getPlanUseCase,
        createPlanUseCase: container.createPlanUseCase,
        updatePlanUseCase: container.updatePlanUseCase,
        deletePlanUseCase: container.deletePlanUseCase,
        getObjectivesUseCase: container.getObjectivesUseCase,
        getObjectiveUseCase: container.getObjectiveUseCase,
        createObjectiveUseCase: container.createObjectiveUseCase,
        updateObjectiveUseCase: container.updateObjectiveUseCase,
        deleteObjectiveUseCase: container.deleteObjectiveUseCase,
      ),
      child: _TherapeuticPlanFormContent(
        patientId: patientId,
        patientName: patientName,
        plan: plan,
        isEditing: isEditing,
      ),
    );
  }
}

class _TherapeuticPlanFormContent extends StatefulWidget {
  final String patientId;
  final String? patientName;
  final TherapeuticPlan? plan;
  final bool isEditing;

  const _TherapeuticPlanFormContent({
    required this.patientId,
    this.patientName,
    this.plan,
    required this.isEditing,
  });

  @override
  State<_TherapeuticPlanFormContent> createState() =>
      _TherapeuticPlanFormContentState();
}

class _TherapeuticPlanFormContentState
    extends State<_TherapeuticPlanFormContent> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _therapistId;

  // Abordagem terapêutica
  TherapeuticApproach _approach = TherapeuticApproach.cognitiveBehavioral;
  final _approachOtherController = TextEditingController();

  // Informações do plano
  final _recommendedFrequencyController = TextEditingController();
  final _sessionDurationController = TextEditingController();
  final _estimatedDurationController = TextEditingController();

  // Estratégias e técnicas
  final _mainTechniquesController = TextEditingController();
  List<String> _mainTechniques = [];
  final _interventionStrategiesController = TextEditingController();
  final _resourcesToUseController = TextEditingController();
  final _therapeuticTasksController = TextEditingController();

  // Monitoramento
  final _measurementFrequencyController = TextEditingController();
  final _assessmentInstrumentsController = TextEditingController();
  List<String> _assessmentInstruments = [];

  // Observações
  final _observationsController = TextEditingController();
  final _availableResourcesController = TextEditingController();
  final _supportNetworkController = TextEditingController();

  // Status
  TherapeuticPlanStatus _status = TherapeuticPlanStatus.draft;

  @override
  void initState() {
    super.initState();
    _loadTherapistId();
    if (widget.plan != null) {
      _loadPlanData(widget.plan!);
    }
  }

  Future<void> _loadTherapistId() async {
    try {
      final container = DependencyContainer();
      final therapistData = await container.getCurrentTherapistUseCase();
      if (mounted) {
        setState(() {
          _therapistId = therapistData['id']?.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados do terapeuta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadPlanData(TherapeuticPlan plan) {
    _approach = plan.approach;
    _approachOtherController.text = plan.approachOther ?? '';
    _recommendedFrequencyController.text = plan.recommendedFrequency ?? '';
    _sessionDurationController.text = plan.sessionDurationMinutes?.toString() ?? '';
    _estimatedDurationController.text = plan.estimatedDurationMonths?.toString() ?? '';
    _mainTechniques = List.from(plan.mainTechniques);
    _mainTechniquesController.text = plan.mainTechniques.join(', ');
    _interventionStrategiesController.text = plan.interventionStrategies ?? '';
    _resourcesToUseController.text = plan.resourcesToUse ?? '';
    _therapeuticTasksController.text = plan.therapeuticTasks ?? '';
    _measurementFrequencyController.text = plan.measurementFrequency ?? '';
    _assessmentInstruments = List.from(plan.assessmentInstruments);
    _assessmentInstrumentsController.text = plan.assessmentInstruments.join(', ');
    _observationsController.text = plan.observations ?? '';
    _availableResourcesController.text = plan.availableResources ?? '';
    _supportNetworkController.text = plan.supportNetwork ?? '';
    _status = plan.status;
  }

  @override
  void dispose() {
    _approachOtherController.dispose();
    _recommendedFrequencyController.dispose();
    _sessionDurationController.dispose();
    _estimatedDurationController.dispose();
    _mainTechniquesController.dispose();
    _interventionStrategiesController.dispose();
    _resourcesToUseController.dispose();
    _therapeuticTasksController.dispose();
    _measurementFrequencyController.dispose();
    _assessmentInstrumentsController.dispose();
    _observationsController.dispose();
    _availableResourcesController.dispose();
    _supportNetworkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TherapeuticPlanBloc, TherapeuticPlanState>(
      listener: (context, state) {
        if (state is PlanCreated || state is PlanUpdated) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isEditing
                    ? 'Plano atualizado com sucesso!'
                    : 'Plano criado com sucesso!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is TherapeuticPlanError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = _isLoading || state is TherapeuticPlanLoading;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              widget.isEditing ? 'Editar Plano Terapêutico' : 'Novo Plano Terapêutico',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            actions: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          body: _therapistId == null
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Abordagem Terapêutica
                        _buildSectionTitle('Abordagem Terapêutica'),
                        const SizedBox(height: 12),
                        _buildApproachSelector(),
                        if (_approach == TherapeuticApproach.other) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _approachOtherController,
                            decoration: const InputDecoration(
                              labelText: 'Especificar abordagem',
                              hintText: 'Descreva a abordagem terapêutica',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_approach == TherapeuticApproach.other &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Especifique a abordagem terapêutica';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Informações do Plano
                        _buildSectionTitle('Informações do Plano'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _recommendedFrequencyController,
                          decoration: const InputDecoration(
                            labelText: 'Frequência Recomendada',
                            hintText: 'Ex: Semanal, Quinzenal, Mensal',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _sessionDurationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Duração da Sessão (min)',
                                  hintText: '50',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _estimatedDurationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Duração Estimada (meses)',
                                  hintText: '6',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Estratégias e Técnicas
                        _buildSectionTitle('Estratégias e Técnicas'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mainTechniquesController,
                          decoration: InputDecoration(
                            labelText: 'Técnicas Principais',
                            hintText: 'Separadas por vírgula',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addTechnique,
                            ),
                          ),
                          onFieldSubmitted: (_) => _addTechnique(),
                        ),
                        if (_mainTechniques.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _mainTechniques.map((technique) {
                              return Chip(
                                label: Text(technique),
                                onDeleted: () {
                                  setState(() {
                                    _mainTechniques.remove(technique);
                                    _mainTechniquesController.text =
                                        _mainTechniques.join(', ');
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _interventionStrategiesController,
                          decoration: const InputDecoration(
                            labelText: 'Estratégias de Intervenção',
                            hintText: 'Descreva as principais estratégias...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _resourcesToUseController,
                          decoration: const InputDecoration(
                            labelText: 'Recursos a Utilizar',
                            hintText: 'Descreva os recursos necessários...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _therapeuticTasksController,
                          decoration: const InputDecoration(
                            labelText: 'Tarefas Terapêuticas',
                            hintText: 'Descreva as tarefas propostas...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 24),

                        // Monitoramento
                        _buildSectionTitle('Monitoramento'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _measurementFrequencyController,
                          decoration: const InputDecoration(
                            labelText: 'Frequência de Medição',
                            hintText: 'Ex: Mensal, A cada 3 sessões',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _assessmentInstrumentsController,
                          decoration: InputDecoration(
                            labelText: 'Instrumentos de Avaliação',
                            hintText: 'Separados por vírgula',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addAssessmentInstrument,
                            ),
                          ),
                          onFieldSubmitted: (_) => _addAssessmentInstrument(),
                        ),
                        if (_assessmentInstruments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _assessmentInstruments.map((instrument) {
                              return Chip(
                                label: Text(instrument),
                                onDeleted: () {
                                  setState(() {
                                    _assessmentInstruments.remove(instrument);
                                    _assessmentInstrumentsController.text =
                                        _assessmentInstruments.join(', ');
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Observações e Recursos
                        _buildSectionTitle('Observações e Recursos'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _observationsController,
                          decoration: const InputDecoration(
                            labelText: 'Observações',
                            hintText: 'Observações gerais sobre o plano...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _availableResourcesController,
                          decoration: const InputDecoration(
                            labelText: 'Recursos Disponíveis',
                            hintText: 'Recursos disponíveis para o tratamento...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _supportNetworkController,
                          decoration: const InputDecoration(
                            labelText: 'Rede de Apoio',
                            hintText: 'Rede de apoio do paciente...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),

                        const SizedBox(height: 24),

                        // Status (apenas se estiver editando)
                        if (widget.isEditing) ...[
                          _buildSectionTitle('Status'),
                          const SizedBox(height: 12),
                          _buildStatusSelector(),
                          const SizedBox(height: 24),
                        ],

                        // Botão Salvar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _savePlan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.isEditing ? 'Atualizar Plano' : 'Criar Plano',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.offBlack,
      ),
    );
  }

  Widget _buildApproachSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<TherapeuticApproach>(
        value: _approach,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        items: TherapeuticApproach.values.map((approach) {
          return DropdownMenuItem(
            value: approach,
            child: Text(_getApproachLabel(approach)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _approach = value);
          }
        },
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<TherapeuticPlanStatus>(
        value: _status,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        items: TherapeuticPlanStatus.values.map((status) {
          return DropdownMenuItem(
            value: status,
            child: Text(_getStatusLabel(status)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _status = value);
          }
        },
      ),
    );
  }

  void _addTechnique() {
    final text = _mainTechniquesController.text.trim();
    if (text.isNotEmpty) {
      final techniques = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      setState(() {
        _mainTechniques.addAll(techniques);
        _mainTechniques = _mainTechniques.toSet().toList(); // Remove duplicatas
        _mainTechniquesController.clear();
      });
    }
  }

  void _addAssessmentInstrument() {
    final text = _assessmentInstrumentsController.text.trim();
    if (text.isNotEmpty) {
      final instruments = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      setState(() {
        _assessmentInstruments.addAll(instruments);
        _assessmentInstruments = _assessmentInstruments.toSet().toList();
        _assessmentInstrumentsController.clear();
      });
    }
  }

  void _savePlan() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_therapistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: ID do terapeuta não encontrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final plan = TherapeuticPlan(
      id: widget.plan?.id ?? '',
      patientId: widget.patientId,
      therapistId: _therapistId!,
      approach: _approach,
      approachOther: _approachOtherController.text.trim().isEmpty
          ? null
          : _approachOtherController.text.trim(),
      recommendedFrequency: _recommendedFrequencyController.text.trim().isEmpty
          ? null
          : _recommendedFrequencyController.text.trim(),
      sessionDurationMinutes: _sessionDurationController.text.trim().isEmpty
          ? null
          : int.tryParse(_sessionDurationController.text.trim()),
      estimatedDurationMonths: _estimatedDurationController.text.trim().isEmpty
          ? null
          : int.tryParse(_estimatedDurationController.text.trim()),
      mainTechniques: _mainTechniques,
      interventionStrategies: _interventionStrategiesController.text.trim().isEmpty
          ? null
          : _interventionStrategiesController.text.trim(),
      resourcesToUse: _resourcesToUseController.text.trim().isEmpty
          ? null
          : _resourcesToUseController.text.trim(),
      therapeuticTasks: _therapeuticTasksController.text.trim().isEmpty
          ? null
          : _therapeuticTasksController.text.trim(),
      assessmentInstruments: _assessmentInstruments,
      measurementFrequency: _measurementFrequencyController.text.trim().isEmpty
          ? null
          : _measurementFrequencyController.text.trim(),
      observations: _observationsController.text.trim().isEmpty
          ? null
          : _observationsController.text.trim(),
      availableResources: _availableResourcesController.text.trim().isEmpty
          ? null
          : _availableResourcesController.text.trim(),
      supportNetwork: _supportNetworkController.text.trim().isEmpty
          ? null
          : _supportNetworkController.text.trim(),
      status: widget.isEditing ? _status : TherapeuticPlanStatus.draft,
      createdAt: widget.plan?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.isEditing) {
      context.read<TherapeuticPlanBloc>().add(UpdatePlan(plan));
    } else {
      context.read<TherapeuticPlanBloc>().add(CreatePlan(plan));
    }
  }

  String _getApproachLabel(TherapeuticApproach approach) {
    switch (approach) {
      case TherapeuticApproach.cognitiveBehavioral:
        return 'Terapia Cognitivo-Comportamental';
      case TherapeuticApproach.psychodynamic:
        return 'Terapia Psicodinâmica';
      case TherapeuticApproach.humanistic:
        return 'Terapia Humanística';
      case TherapeuticApproach.systemic:
        return 'Terapia Sistêmica';
      case TherapeuticApproach.existential:
        return 'Terapia Existencial';
      case TherapeuticApproach.gestalt:
        return 'Terapia Gestalt';
      case TherapeuticApproach.integrative:
        return 'Terapia Integrativa';
      case TherapeuticApproach.other:
        return 'Outra abordagem';
    }
  }

  String _getStatusLabel(TherapeuticPlanStatus status) {
    switch (status) {
      case TherapeuticPlanStatus.draft:
        return 'Rascunho';
      case TherapeuticPlanStatus.active:
        return 'Ativo';
      case TherapeuticPlanStatus.reviewing:
        return 'Em Revisão';
      case TherapeuticPlanStatus.completed:
        return 'Concluído';
      case TherapeuticPlanStatus.archived:
        return 'Arquivado';
    }
  }
}

