import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/therapeutic_plan/bloc/therapeutic_plan_bloc.dart';
import 'package:terafy/features/therapeutic_plan/bloc/therapeutic_plan_bloc_models.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_objective.dart';
import 'package:terafy/features/therapeutic_plan/widgets/therapeutic_objective_card.dart';
import 'package:terafy/features/therapeutic_plan/widgets/therapeutic_objective_form_modal.dart';
import 'package:terafy/routes/app_routes.dart';

class TherapeuticPlanDetailsPage extends StatelessWidget {
  final String planId;

  const TherapeuticPlanDetailsPage({super.key, required this.planId});

  @override
  Widget build(BuildContext context) {
    final container = DependencyContainer();
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
      )..add(LoadPlanDetails(planId)),
      child: _TherapeuticPlanDetailsContent(planId: planId),
    );
  }
}

class _TherapeuticPlanDetailsContent extends StatefulWidget {
  final String planId;

  const _TherapeuticPlanDetailsContent({required this.planId});

  @override
  State<_TherapeuticPlanDetailsContent> createState() => _TherapeuticPlanDetailsContentState();
}

class _TherapeuticPlanDetailsContentState extends State<_TherapeuticPlanDetailsContent> {
  TherapeuticPlan? _currentPlan;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TherapeuticPlanBloc, TherapeuticPlanState>(
      listener: (context, state) {
        if (state is TherapeuticPlanError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        } else if (state is PlanDetailsLoaded) {
          setState(() {
            _currentPlan = state.plan;
          });
        } else if (state is PlanUpdated) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Plano atualizado com sucesso!'), backgroundColor: Colors.green));
          context.read<TherapeuticPlanBloc>().add(LoadPlanDetails(widget.planId));
        } else if (state is ObjectiveCreated) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Objetivo criado com sucesso!'), backgroundColor: Colors.green));
        } else if (state is ObjectiveUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Objetivo atualizado com sucesso!'), backgroundColor: Colors.green),
          );
        }
      },
      builder: (context, state) {
        // Se o plano ainda não foi carregado, mostra loading
        if (_currentPlan == null) {
          if (state is PlanDetailsLoaded) {
            _currentPlan = state.plan;
          } else if (state is TherapeuticPlanLoading || state is TherapeuticPlanInitial) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (state is TherapeuticPlanError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar detalhes do plano', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<TherapeuticPlanBloc>().add(LoadPlanDetails(widget.planId));
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        // Se temos o plano, mostra a página completa
        if (_currentPlan != null) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: _buildAppBar(context, _currentPlan!),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com informações principais
                  _buildHeader(_currentPlan!),

                  // Informações básicas do plano
                  _buildBasicInfoCard(_currentPlan!),

                  // Estratégias e técnicas
                  _buildStrategiesCard(_currentPlan!),

                  // Monitoramento
                  _buildMonitoringCard(_currentPlan!),

                  // Recursos e apoio
                  _buildResourcesCard(_currentPlan!),

                  // Objetivos
                  _buildObjectivesSection(context, _currentPlan!),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }

        // Fallback: se chegou aqui e não tem plano, mostra tela de erro
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Erro ao carregar detalhes do plano', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<TherapeuticPlanBloc>().add(LoadPlanDetails(widget.planId));
                  },
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, TherapeuticPlan plan) {
    return AppBar(
      backgroundColor: _getStatusColor(plan.status),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plano Terapêutico #${plan.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Text(_getStatusLabel(plan.status), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value, plan),
          itemBuilder: (context) => [
            if (plan.status != TherapeuticPlanStatus.completed && plan.status != TherapeuticPlanStatus.archived)
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 12), Text('Editar')]),
              ),
            if (plan.status == TherapeuticPlanStatus.active)
              const PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [Icon(Icons.rate_review, size: 20), SizedBox(width: 12), Text('Marcar para Revisão')],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(TherapeuticPlan plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.offBlack.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(plan.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.psychology, color: _getStatusColor(plan.status), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getApproachLabel(plan.approach),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.offBlack),
                    ),
                    if (plan.approachOther != null) ...[
                      const SizedBox(height: 4),
                      Text(plan.approachOther!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Criado em ${_formatDate(plan.createdAt)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.update, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Atualizado em ${_formatDate(plan.updatedAt)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(TherapeuticPlan plan) {
    final hasInfo =
        plan.recommendedFrequency != null ||
        plan.sessionDurationMinutes != null ||
        plan.estimatedDurationMonths != null;

    if (!hasInfo) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.info_outline,
      title: 'Informações Básicas',
      color: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.recommendedFrequency != null) _buildInfoRow('Frequência recomendada', plan.recommendedFrequency!),
          if (plan.sessionDurationMinutes != null)
            _buildInfoRow('Duração da sessão', '${plan.sessionDurationMinutes} minutos'),
          if (plan.estimatedDurationMonths != null)
            _buildInfoRow('Duração estimada', '${plan.estimatedDurationMonths} meses'),
        ],
      ),
    );
  }

  Widget _buildStrategiesCard(TherapeuticPlan plan) {
    final hasContent =
        plan.mainTechniques.isNotEmpty ||
        plan.interventionStrategies != null ||
        plan.resourcesToUse != null ||
        plan.therapeuticTasks != null;

    if (!hasContent) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.settings,
      title: 'Estratégias e Técnicas',
      color: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.mainTechniques.isNotEmpty) ...[
            const Text(
              'Técnicas Principais',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plan.mainTechniques.map((technique) {
                return Chip(
                  label: Text(technique),
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  labelStyle: const TextStyle(fontSize: 12),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (plan.interventionStrategies != null) ...[
            const Text(
              'Estratégias de Intervenção',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            Text(plan.interventionStrategies!, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
            const SizedBox(height: 16),
          ],
          if (plan.resourcesToUse != null) ...[
            const Text(
              'Recursos a Utilizar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            Text(plan.resourcesToUse!, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
            const SizedBox(height: 16),
          ],
          if (plan.therapeuticTasks != null) ...[
            const Text(
              'Tarefas Terapêuticas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            Text(plan.therapeuticTasks!, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildMonitoringCard(TherapeuticPlan plan) {
    final hasContent =
        plan.assessmentInstruments.isNotEmpty || plan.measurementFrequency != null || plan.monitoringIndicators != null;

    if (!hasContent) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.track_changes,
      title: 'Monitoramento',
      color: Colors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.measurementFrequency != null) ...[
            _buildInfoRow('Frequência de medição', plan.measurementFrequency!),
            const SizedBox(height: 12),
          ],
          if (plan.assessmentInstruments.isNotEmpty) ...[
            const Text(
              'Instrumentos de Avaliação',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plan.assessmentInstruments.map((instrument) {
                return Chip(
                  label: Text(instrument),
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  labelStyle: const TextStyle(fontSize: 12),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResourcesCard(TherapeuticPlan plan) {
    final hasContent = plan.availableResources != null || plan.supportNetwork != null || plan.observations != null;

    if (!hasContent) return const SizedBox.shrink();

    return _buildSectionCard(
      icon: Icons.support_agent,
      title: 'Recursos e Apoio',
      color: Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.availableResources != null) ...[
            const Text(
              'Recursos Disponíveis',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            Text(plan.availableResources!, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
            const SizedBox(height: 16),
          ],
          if (plan.supportNetwork != null) ...[
            const Text(
              'Rede de Apoio',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            Text(plan.supportNetwork!, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
            const SizedBox(height: 16),
          ],
          if (plan.observations != null) ...[
            const Text(
              'Observações',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            Text(plan.observations!, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.offBlack.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.offBlack),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildObjectivesSection(BuildContext context, TherapeuticPlan plan) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.offBlack.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Objetivos Terapêuticos'),
              TextButton.icon(
                onPressed: () => _showObjectiveFormModal(context, plan, null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<TherapeuticPlanBloc, TherapeuticPlanState>(
            builder: (context, state) {
              if (state is ObjectivesLoaded && state.planId == plan.id) {
                if (state.objectives.isEmpty) {
                  return _buildEmptyObjectives();
                }
                return Column(
                  children: state.objectives.map((objective) {
                    return TherapeuticObjectiveCard(
                      objective: objective,
                      onEdit: () => _showObjectiveFormModal(context, plan, objective),
                      onUpdateProgress: () => _showObjectiveFormModal(context, plan, objective),
                    );
                  }).toList(),
                );
              }
              // Carregar objetivos apenas uma vez quando o plano for carregado
              if (state is PlanDetailsLoaded && state.plan.id == plan.id) {
                // Usa WidgetsBinding para evitar disparar durante o build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<TherapeuticPlanBloc>().add(LoadObjectives(planId: plan.id));
                });
                return const Center(child: CircularProgressIndicator());
              }
              // Se ainda está carregando, mostra loading apenas na seção de objetivos
              if (state is TherapeuticPlanLoading || state is TherapeuticPlanInitial) {
                return const Center(
                  child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
                );
              }
              // Por padrão, mostra loading
              return const Center(
                child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyObjectives() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.flag_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('Nenhum objetivo cadastrado', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.offBlack),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TherapeuticPlanStatus status) {
    switch (status) {
      case TherapeuticPlanStatus.draft:
        return Colors.grey;
      case TherapeuticPlanStatus.active:
        return Colors.green;
      case TherapeuticPlanStatus.reviewing:
        return Colors.orange;
      case TherapeuticPlanStatus.completed:
        return Colors.blue;
      case TherapeuticPlanStatus.archived:
        return Colors.grey;
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _handleMenuAction(BuildContext context, String action, TherapeuticPlan plan) {
    switch (action) {
      case 'edit':
        _navigateToEditPlan(context, plan);
        break;
      case 'review':
        _updatePlanStatus(context, plan.copyWith(status: TherapeuticPlanStatus.reviewing));
        break;
      case 'delete':
        _showDeleteConfirmation(context, plan);
        break;
    }
  }

  void _updatePlanStatus(BuildContext context, TherapeuticPlan plan) {
    context.read<TherapeuticPlanBloc>().add(UpdatePlan(plan));
  }

  void _navigateToEditPlan(BuildContext context, TherapeuticPlan plan) async {
    final result = await Navigator.of(
      context,
    ).pushNamed(AppRouter.therapeuticPlanFormRoute, arguments: {'patientId': plan.patientId, 'plan': plan});

    if (result == true && context.mounted) {
      context.read<TherapeuticPlanBloc>().add(LoadPlanDetails(plan.id));
    }
  }

  void _showObjectiveFormModal(BuildContext context, TherapeuticPlan plan, TherapeuticObjective? objective) {
    final bloc = context.read<TherapeuticPlanBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider.value(
        value: bloc,
        child: TherapeuticObjectiveFormModal(
          therapeuticPlanId: plan.id,
          patientId: plan.patientId,
          therapistId: plan.therapistId,
          objective: objective,
        ),
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        // Recarrega os objetivos
        context.read<TherapeuticPlanBloc>().add(LoadObjectives(planId: plan.id));
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, TherapeuticPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este plano terapêutico? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TherapeuticPlanBloc>().add(DeletePlan(plan.id));
              Navigator.pop(context); // Volta para a lista
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
