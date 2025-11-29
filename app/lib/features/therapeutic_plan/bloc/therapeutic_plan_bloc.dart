import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/domain/usecases/therapeutic_plan/create_objective_usecase.dart';
import 'package:terafy/core/domain/usecases/therapeutic_plan/create_plan_usecase.dart';
import 'package:terafy/core/domain/usecases/therapeutic_plan/delete_objective_usecase.dart';
import 'package:terafy/core/domain/usecases/therapeutic_plan/delete_plan_usecase.dart';
import 'package:terafy/core/domain/usecases/therapeutic_plan/get_objective_usecase.dart';
import 'package:terafy/core/domain/usecases/therapeutic_plan/get_objectives_usecase.dart';
import 'package:terafy/core/domain/usecases/therapeutic_plan/get_plan_usecase.dart';
import 'package:terafy/core/domain/usecases/therapeutic_plan/get_plans_usecase.dart';
import 'package:terafy/core/domain/usecases/therapeutic_plan/update_objective_usecase.dart';
import 'package:terafy/core/domain/usecases/therapeutic_plan/update_plan_usecase.dart';
import 'package:terafy/features/therapeutic_plan/bloc/therapeutic_plan_bloc_models.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_objective.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan.dart';

class TherapeuticPlanBloc extends Bloc<TherapeuticPlanEvent, TherapeuticPlanState> {
  TherapeuticPlanBloc({
    required GetPlansUseCase getPlansUseCase,
    required GetPlanUseCase getPlanUseCase,
    required CreatePlanUseCase createPlanUseCase,
    required UpdatePlanUseCase updatePlanUseCase,
    required DeletePlanUseCase deletePlanUseCase,
    required GetObjectivesUseCase getObjectivesUseCase,
    required GetObjectiveUseCase getObjectiveUseCase,
    required CreateObjectiveUseCase createObjectiveUseCase,
    required UpdateObjectiveUseCase updateObjectiveUseCase,
    required DeleteObjectiveUseCase deleteObjectiveUseCase,
  }) : _getPlansUseCase = getPlansUseCase,
       _getPlanUseCase = getPlanUseCase,
       _createPlanUseCase = createPlanUseCase,
       _updatePlanUseCase = updatePlanUseCase,
       _deletePlanUseCase = deletePlanUseCase,
       _getObjectivesUseCase = getObjectivesUseCase,
       _getObjectiveUseCase = getObjectiveUseCase,
       _createObjectiveUseCase = createObjectiveUseCase,
       _updateObjectiveUseCase = updateObjectiveUseCase,
       _deleteObjectiveUseCase = deleteObjectiveUseCase,
       super(TherapeuticPlanInitial()) {
    // Plan handlers
    on<LoadPlans>(_onLoadPlans);
    on<LoadPlanDetails>(_onLoadPlanDetails);
    on<CreatePlan>(_onCreatePlan);
    on<UpdatePlan>(_onUpdatePlan);
    on<DeletePlan>(_onDeletePlan);
    on<FilterPlansByStatus>(_onFilterPlansByStatus);

    // Objective handlers
    on<LoadObjectives>(_onLoadObjectives);
    on<LoadObjectiveDetails>(_onLoadObjectiveDetails);
    on<CreateObjective>(_onCreateObjective);
    on<UpdateObjective>(_onUpdateObjective);
    on<DeleteObjective>(_onDeleteObjective);
    on<UpdateObjectiveProgress>(_onUpdateObjectiveProgress);
  }

  final GetPlansUseCase _getPlansUseCase;
  final GetPlanUseCase _getPlanUseCase;
  final CreatePlanUseCase _createPlanUseCase;
  final UpdatePlanUseCase _updatePlanUseCase;
  final DeletePlanUseCase _deletePlanUseCase;
  final GetObjectivesUseCase _getObjectivesUseCase;
  final GetObjectiveUseCase _getObjectiveUseCase;
  final CreateObjectiveUseCase _createObjectiveUseCase;
  final UpdateObjectiveUseCase _updateObjectiveUseCase;
  final DeleteObjectiveUseCase _deleteObjectiveUseCase;

  // ============ PLAN HANDLERS ============

  Future<void> _onLoadPlans(LoadPlans event, Emitter<TherapeuticPlanState> emit) async {
    emit(TherapeuticPlanLoading());

    try {
      final plans = await _getPlansUseCase(patientId: event.patientId, status: event.status);

      emit(PlansLoaded(plans: plans));
    } catch (e) {
      emit(TherapeuticPlanError('Erro ao carregar planos terapêuticos: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPlanDetails(LoadPlanDetails event, Emitter<TherapeuticPlanState> emit) async {
    emit(TherapeuticPlanLoading());

    try {
      final plan = await _getPlanUseCase(event.planId);

      emit(PlanDetailsLoaded(plan));
    } catch (e) {
      emit(TherapeuticPlanError('Erro ao carregar plano terapêutico: ${e.toString()}'));
    }
  }

  Future<void> _onCreatePlan(CreatePlan event, Emitter<TherapeuticPlanState> emit) async {
    emit(TherapeuticPlanLoading());

    try {
      final created = await _createPlanUseCase(
        patientId: event.plan.patientId,
        therapistId: event.plan.therapistId,
        approach: _mapApproachToString(event.plan.approach),
        approachOther: event.plan.approachOther,
        recommendedFrequency: event.plan.recommendedFrequency,
        sessionDurationMinutes: event.plan.sessionDurationMinutes,
        estimatedDurationMonths: event.plan.estimatedDurationMonths,
        mainTechniques: event.plan.mainTechniques.isNotEmpty ? event.plan.mainTechniques : null,
        interventionStrategies: event.plan.interventionStrategies,
        resourcesToUse: event.plan.resourcesToUse,
        therapeuticTasks: event.plan.therapeuticTasks,
        monitoringIndicators: event.plan.monitoringIndicators,
        assessmentInstruments: event.plan.assessmentInstruments.isNotEmpty ? event.plan.assessmentInstruments : null,
        measurementFrequency: event.plan.measurementFrequency,
        observations: event.plan.observations,
        availableResources: event.plan.availableResources,
        supportNetwork: event.plan.supportNetwork,
        status: _mapStatusToString(event.plan.status),
      );

      emit(PlanCreated(created));
    } catch (e) {
      emit(TherapeuticPlanError('Erro ao criar plano terapêutico: ${e.toString()}'));
    }
  }

  Future<void> _onUpdatePlan(UpdatePlan event, Emitter<TherapeuticPlanState> emit) async {
    emit(TherapeuticPlanLoading());

    try {
      final updated = await _updatePlanUseCase(
        id: event.plan.id,
        patientId: event.plan.patientId,
        therapistId: event.plan.therapistId,
        approach: _mapApproachToString(event.plan.approach),
        approachOther: event.plan.approachOther,
        recommendedFrequency: event.plan.recommendedFrequency,
        sessionDurationMinutes: event.plan.sessionDurationMinutes,
        estimatedDurationMonths: event.plan.estimatedDurationMonths,
        mainTechniques: event.plan.mainTechniques.isNotEmpty ? event.plan.mainTechniques : null,
        interventionStrategies: event.plan.interventionStrategies,
        resourcesToUse: event.plan.resourcesToUse,
        therapeuticTasks: event.plan.therapeuticTasks,
        monitoringIndicators: event.plan.monitoringIndicators,
        assessmentInstruments: event.plan.assessmentInstruments.isNotEmpty ? event.plan.assessmentInstruments : null,
        measurementFrequency: event.plan.measurementFrequency,
        observations: event.plan.observations,
        availableResources: event.plan.availableResources,
        supportNetwork: event.plan.supportNetwork,
        status: _mapStatusToString(event.plan.status),
        reviewedAt: event.plan.reviewedAt,
      );

      emit(PlanUpdated(updated));
    } catch (e) {
      emit(TherapeuticPlanError('Erro ao atualizar plano terapêutico: ${e.toString()}'));
    }
  }

  Future<void> _onDeletePlan(DeletePlan event, Emitter<TherapeuticPlanState> emit) async {
    emit(TherapeuticPlanLoading());

    try {
      await _deletePlanUseCase(event.planId);

      emit(const PlanDeleted());
    } catch (e) {
      emit(TherapeuticPlanError('Erro ao remover plano terapêutico: ${e.toString()}'));
    }
  }

  Future<void> _onFilterPlansByStatus(FilterPlansByStatus event, Emitter<TherapeuticPlanState> emit) async {
    if (state is PlansLoaded) {
      emit(TherapeuticPlanLoading());

      try {
        final plans = await _getPlansUseCase(status: event.status);

        emit(PlansLoaded(plans: plans));
      } catch (e) {
        emit(TherapeuticPlanError('Erro ao filtrar planos: ${e.toString()}'));
      }
    }
  }

  // ============ OBJECTIVE HANDLERS ============

  Future<void> _onLoadObjectives(LoadObjectives event, Emitter<TherapeuticPlanState> emit) async {
    // Não emite loading para não esconder os detalhes do plano que já está carregado
    try {
      final objectives = await _getObjectivesUseCase(
        planId: event.planId,
        patientId: event.patientId,
        status: event.status,
        priority: event.priority,
        deadlineType: event.deadlineType,
      );

      emit(ObjectivesLoaded(objectives: objectives, planId: event.planId));
    } catch (e) {
      emit(TherapeuticPlanError('Erro ao carregar objetivos terapêuticos: ${e.toString()}'));
    }
  }

  Future<void> _onLoadObjectiveDetails(LoadObjectiveDetails event, Emitter<TherapeuticPlanState> emit) async {
    emit(TherapeuticPlanLoading());

    try {
      final objective = await _getObjectiveUseCase(event.objectiveId);

      emit(ObjectiveDetailsLoaded(objective));
    } catch (e) {
      emit(TherapeuticPlanError('Erro ao carregar objetivo terapêutico: ${e.toString()}'));
    }
  }

  Future<void> _onCreateObjective(CreateObjective event, Emitter<TherapeuticPlanState> emit) async {
    emit(TherapeuticPlanLoading());

    try {
      final created = await _createObjectiveUseCase(
        therapeuticPlanId: event.objective.therapeuticPlanId,
        patientId: event.objective.patientId,
        therapistId: event.objective.therapistId,
        description: event.objective.description,
        specificAspect: event.objective.specificAspect,
        measurableCriteria: event.objective.measurableCriteria,
        achievableConditions: event.objective.achievableConditions,
        relevantJustification: event.objective.relevantJustification,
        timeBoundDeadline: event.objective.timeBoundDeadline,
        deadlineType: _mapDeadlineTypeToString(event.objective.deadlineType),
        priority: _mapPriorityToString(event.objective.priority),
        status: _mapObjectiveStatusToString(event.objective.status),
        progressPercentage: event.objective.progressPercentage,
        progressIndicators: event.objective.progressIndicators,
        successMetric: event.objective.successMetric,
        targetDate: event.objective.targetDate,
        notes: event.objective.notes,
        displayOrder: event.objective.displayOrder,
      );

      emit(ObjectiveCreated(created));
    } catch (e) {
      emit(TherapeuticPlanError('Erro ao criar objetivo terapêutico: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateObjective(UpdateObjective event, Emitter<TherapeuticPlanState> emit) async {
    emit(TherapeuticPlanLoading());

    try {
      final updated = await _updateObjectiveUseCase(
        id: event.objective.id,
        description: event.objective.description,
        specificAspect: event.objective.specificAspect,
        measurableCriteria: event.objective.measurableCriteria,
        achievableConditions: event.objective.achievableConditions,
        relevantJustification: event.objective.relevantJustification,
        timeBoundDeadline: event.objective.timeBoundDeadline,
        deadlineType: _mapDeadlineTypeToString(event.objective.deadlineType),
        priority: _mapPriorityToString(event.objective.priority),
        status: _mapObjectiveStatusToString(event.objective.status),
        progressPercentage: event.objective.progressPercentage,
        progressIndicators: event.objective.progressIndicators,
        successMetric: event.objective.successMetric,
        targetDate: event.objective.targetDate,
        abandonedReason: event.objective.abandonedReason,
        notes: event.objective.notes,
        displayOrder: event.objective.displayOrder,
      );

      emit(ObjectiveUpdated(updated));
    } catch (e) {
      emit(TherapeuticPlanError('Erro ao atualizar objetivo terapêutico: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteObjective(DeleteObjective event, Emitter<TherapeuticPlanState> emit) async {
    emit(TherapeuticPlanLoading());

    try {
      await _deleteObjectiveUseCase(event.objectiveId);

      emit(const ObjectiveDeleted());
    } catch (e) {
      emit(TherapeuticPlanError('Erro ao remover objetivo terapêutico: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateObjectiveProgress(UpdateObjectiveProgress event, Emitter<TherapeuticPlanState> emit) async {
    emit(TherapeuticPlanLoading());

    try {
      // Buscar objetivo atual
      final objective = await _getObjectiveUseCase(event.objectiveId);

      // Atualizar progresso
      final updatedObjective = objective.copyWith(
        progressPercentage: event.progressPercentage,
        status: event.progressPercentage == 100
            ? ObjectiveStatus.completed
            : event.progressPercentage > 0
            ? ObjectiveStatus.inProgress
            : ObjectiveStatus.pending,
      );

      // Salvar no backend
      final saved = await _updateObjectiveUseCase(
        id: updatedObjective.id,
        description: updatedObjective.description,
        specificAspect: updatedObjective.specificAspect,
        measurableCriteria: updatedObjective.measurableCriteria,
        deadlineType: _mapDeadlineTypeToString(updatedObjective.deadlineType),
        priority: _mapPriorityToString(updatedObjective.priority),
        status: _mapObjectiveStatusToString(updatedObjective.status),
        progressPercentage: updatedObjective.progressPercentage,
      );

      emit(ObjectiveUpdated(saved));
    } catch (e) {
      emit(TherapeuticPlanError('Erro ao atualizar progresso: ${e.toString()}'));
    }
  }

  // ============ HELPER METHODS ============

  String _mapApproachToString(TherapeuticApproach approach) {
    return switch (approach) {
      TherapeuticApproach.cognitiveBehavioral => 'cognitive_behavioral',
      TherapeuticApproach.psychodynamic => 'psychodynamic',
      TherapeuticApproach.humanistic => 'humanistic',
      TherapeuticApproach.systemic => 'systemic',
      TherapeuticApproach.existential => 'existential',
      TherapeuticApproach.gestalt => 'gestalt',
      TherapeuticApproach.integrative => 'integrative',
      TherapeuticApproach.other => 'other',
    };
  }

  String _mapStatusToString(TherapeuticPlanStatus status) {
    return switch (status) {
      TherapeuticPlanStatus.draft => 'draft',
      TherapeuticPlanStatus.active => 'active',
      TherapeuticPlanStatus.reviewing => 'reviewing',
      TherapeuticPlanStatus.completed => 'completed',
      TherapeuticPlanStatus.archived => 'archived',
    };
  }

  String _mapDeadlineTypeToString(ObjectiveDeadlineType type) {
    return switch (type) {
      ObjectiveDeadlineType.shortTerm => 'short_term',
      ObjectiveDeadlineType.mediumTerm => 'medium_term',
      ObjectiveDeadlineType.longTerm => 'long_term',
    };
  }

  String _mapPriorityToString(ObjectivePriority priority) {
    return switch (priority) {
      ObjectivePriority.low => 'low',
      ObjectivePriority.medium => 'medium',
      ObjectivePriority.high => 'high',
      ObjectivePriority.urgent => 'urgent',
    };
  }

  String _mapObjectiveStatusToString(ObjectiveStatus status) {
    return switch (status) {
      ObjectiveStatus.pending => 'pending',
      ObjectiveStatus.inProgress => 'in_progress',
      ObjectiveStatus.completed => 'completed',
      ObjectiveStatus.abandoned => 'abandoned',
      ObjectiveStatus.onHold => 'on_hold',
    };
  }
}
