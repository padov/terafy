import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/therapeutic_plan/bloc/therapeutic_plan_bloc.dart';
import 'package:terafy/features/therapeutic_plan/bloc/therapeutic_plan_bloc_models.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan.dart';
import 'package:terafy/routes/app_routes.dart';

class TherapeuticPlansListPage extends StatelessWidget {
  final String? patientId;
  final String? patientName;

  const TherapeuticPlansListPage({super.key, this.patientId, this.patientName});

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
      )..add(LoadPlans(patientId: patientId)),
      child: _TherapeuticPlansListPageContent(patientId: patientId, patientName: patientName),
    );
  }
}

class _TherapeuticPlansListPageContent extends StatefulWidget {
  final String? patientId;
  final String? patientName;

  const _TherapeuticPlansListPageContent({this.patientId, this.patientName});

  @override
  State<_TherapeuticPlansListPageContent> createState() => _TherapeuticPlansListPageContentState();
}

class _TherapeuticPlansListPageContentState extends State<_TherapeuticPlansListPageContent> {
  String? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.patientName != null ? 'Planos Terapêuticos - ${widget.patientName}' : 'Planos Terapêuticos',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.offBlack,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.filter_list), onPressed: () => _showFilterOptions(context))],
      ),
      body: BlocConsumer<TherapeuticPlanBloc, TherapeuticPlanState>(
        listener: (context, state) {
          if (state is PlanCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plano terapêutico criado com sucesso!'), backgroundColor: Colors.green),
            );
            context.read<TherapeuticPlanBloc>().add(LoadPlans(patientId: widget.patientId));
          } else if (state is PlanDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plano terapêutico removido com sucesso!'), backgroundColor: Colors.green),
            );
            context.read<TherapeuticPlanBloc>().add(LoadPlans(patientId: widget.patientId));
          } else if (state is TherapeuticPlanError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is TherapeuticPlanLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TherapeuticPlanError && state is! PlansLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TherapeuticPlanBloc>().add(LoadPlans(patientId: widget.patientId));
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (state is PlansLoaded) {
            if (state.plans.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<TherapeuticPlanBloc>().add(LoadPlans(patientId: widget.patientId));
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.plans.length,
                itemBuilder: (context, index) {
                  final plan = state.plans[index];
                  return _buildPlanCard(context, plan);
                },
              ),
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.patientId != null ? () => _navigateToCreatePlan(context) : null,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Novo Plano', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, TherapeuticPlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToPlanDetails(context, plan.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Plano Terapêutico #${plan.id}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.offBlack),
                    ),
                  ),
                  _buildStatusChip(plan.status),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(_getApproachLabel(plan.approach), style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ),
              if (plan.estimatedDurationMonths != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Duração estimada: ${plan.estimatedDurationMonths} meses',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              Text(
                'Criado em: ${_formatDate(plan.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TherapeuticPlanStatus status) {
    Color color;
    String label;

    switch (status) {
      case TherapeuticPlanStatus.draft:
        color = Colors.grey;
        label = 'Rascunho';
        break;
      case TherapeuticPlanStatus.active:
        color = Colors.green;
        label = 'Ativo';
        break;
      case TherapeuticPlanStatus.reviewing:
        color = Colors.orange;
        label = 'Revisão';
        break;
      case TherapeuticPlanStatus.completed:
        color = Colors.blue;
        label = 'Concluído';
        break;
      case TherapeuticPlanStatus.archived:
        color = Colors.grey;
        label = 'Arquivado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhum plano terapêutico encontrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            widget.patientId != null
                ? 'Comece criando o primeiro plano para este paciente'
                : 'Comece criando um plano terapêutico',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Filtrar por Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFilterOption(context, 'Todos', null),
            _buildFilterOption(context, 'Rascunho', 'draft'),
            _buildFilterOption(context, 'Ativo', 'active'),
            _buildFilterOption(context, 'Revisão', 'reviewing'),
            _buildFilterOption(context, 'Concluído', 'completed'),
            _buildFilterOption(context, 'Arquivado', 'archived'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(BuildContext context, String label, String? status) {
    return ListTile(
      title: Text(label),
      trailing: _selectedStatusFilter == status ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        setState(() {
          _selectedStatusFilter = status;
        });
        context.read<TherapeuticPlanBloc>().add(FilterPlansByStatus(status));
        Navigator.pop(context);
      },
    );
  }

  void _navigateToPlanDetails(BuildContext context, String planId) {
    Navigator.of(context).pushNamed(AppRouter.therapeuticPlanDetailsRoute, arguments: {'planId': planId});
  }

  void _navigateToCreatePlan(BuildContext context) async {
    if (widget.patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É necessário selecionar um paciente para criar um plano'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).pushNamed(
      AppRouter.therapeuticPlanFormRoute,
      arguments: {'patientId': widget.patientId!, 'patientName': widget.patientName},
    );

    if (result == true && context.mounted) {
      context.read<TherapeuticPlanBloc>().add(LoadPlans(patientId: widget.patientId));
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
    return '${date.day}/${date.month}/${date.year}';
  }
}
