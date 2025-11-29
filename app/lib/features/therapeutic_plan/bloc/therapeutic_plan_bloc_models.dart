import 'package:terafy/features/therapeutic_plan/models/therapeutic_objective.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan.dart';

// ========== EVENTS ==========

abstract class TherapeuticPlanEvent {
  const TherapeuticPlanEvent();
}

// Plan Events
class LoadPlans extends TherapeuticPlanEvent {
  final String? patientId;
  final String? status;

  const LoadPlans({this.patientId, this.status});
}

class LoadPlanDetails extends TherapeuticPlanEvent {
  final String planId;

  const LoadPlanDetails(this.planId);
}

class CreatePlan extends TherapeuticPlanEvent {
  final TherapeuticPlan plan;

  const CreatePlan(this.plan);
}

class UpdatePlan extends TherapeuticPlanEvent {
  final TherapeuticPlan plan;

  const UpdatePlan(this.plan);
}

class DeletePlan extends TherapeuticPlanEvent {
  final String planId;

  const DeletePlan(this.planId);
}

class FilterPlansByStatus extends TherapeuticPlanEvent {
  final String? status;

  const FilterPlansByStatus(this.status);
}

// Objective Events
class LoadObjectives extends TherapeuticPlanEvent {
  final String? planId;
  final String? patientId;
  final String? status;
  final String? priority;
  final String? deadlineType;

  const LoadObjectives({this.planId, this.patientId, this.status, this.priority, this.deadlineType});
}

class LoadObjectiveDetails extends TherapeuticPlanEvent {
  final String objectiveId;

  const LoadObjectiveDetails(this.objectiveId);
}

class CreateObjective extends TherapeuticPlanEvent {
  final TherapeuticObjective objective;

  const CreateObjective(this.objective);
}

class UpdateObjective extends TherapeuticPlanEvent {
  final TherapeuticObjective objective;

  const UpdateObjective(this.objective);
}

class DeleteObjective extends TherapeuticPlanEvent {
  final String objectiveId;

  const DeleteObjective(this.objectiveId);
}

class UpdateObjectiveProgress extends TherapeuticPlanEvent {
  final String objectiveId;
  final int progressPercentage;

  const UpdateObjectiveProgress({required this.objectiveId, required this.progressPercentage});
}

// ========== STATES ==========

abstract class TherapeuticPlanState {
  const TherapeuticPlanState();
}

class TherapeuticPlanInitial extends TherapeuticPlanState {}

class TherapeuticPlanLoading extends TherapeuticPlanState {}

class PlansLoaded extends TherapeuticPlanState {
  final List<TherapeuticPlan> plans;

  const PlansLoaded({required this.plans});
}

class PlanDetailsLoaded extends TherapeuticPlanState {
  final TherapeuticPlan plan;

  const PlanDetailsLoaded(this.plan);
}

class PlanCreated extends TherapeuticPlanState {
  final TherapeuticPlan plan;

  const PlanCreated(this.plan);
}

class PlanUpdated extends TherapeuticPlanState {
  final TherapeuticPlan plan;

  const PlanUpdated(this.plan);
}

class PlanDeleted extends TherapeuticPlanState {
  const PlanDeleted();
}

class ObjectivesLoaded extends TherapeuticPlanState {
  final List<TherapeuticObjective> objectives;
  final String? planId;

  const ObjectivesLoaded({required this.objectives, this.planId});
}

class ObjectiveDetailsLoaded extends TherapeuticPlanState {
  final TherapeuticObjective objective;

  const ObjectiveDetailsLoaded(this.objective);
}

class ObjectiveCreated extends TherapeuticPlanState {
  final TherapeuticObjective objective;

  const ObjectiveCreated(this.objective);
}

class ObjectiveUpdated extends TherapeuticPlanState {
  final TherapeuticObjective objective;

  const ObjectiveUpdated(this.objective);
}

class ObjectiveDeleted extends TherapeuticPlanState {
  const ObjectiveDeleted();
}

class TherapeuticPlanError extends TherapeuticPlanState {
  final String message;

  const TherapeuticPlanError(this.message);
}
