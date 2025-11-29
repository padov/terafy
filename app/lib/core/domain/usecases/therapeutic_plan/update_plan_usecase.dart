import 'package:terafy/core/domain/repositories/therapeutic_plan_repository.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan.dart';

class UpdatePlanUseCase {
  const UpdatePlanUseCase(this._repository);

  final TherapeuticPlanRepository _repository;

  Future<TherapeuticPlan> call({
    required String id,
    String? patientId,
    String? therapistId,
    String? approach,
    String? approachOther,
    String? recommendedFrequency,
    int? sessionDurationMinutes,
    int? estimatedDurationMonths,
    List<String>? mainTechniques,
    String? interventionStrategies,
    String? resourcesToUse,
    String? therapeuticTasks,
    Map<String, dynamic>? monitoringIndicators,
    List<String>? assessmentInstruments,
    String? measurementFrequency,
    String? observations,
    String? availableResources,
    String? supportNetwork,
    String? status,
    DateTime? reviewedAt,
  }) {
    return _repository.updatePlan(
      id: id,
      patientId: patientId,
      therapistId: therapistId,
      approach: approach,
      approachOther: approachOther,
      recommendedFrequency: recommendedFrequency,
      sessionDurationMinutes: sessionDurationMinutes,
      estimatedDurationMonths: estimatedDurationMonths,
      mainTechniques: mainTechniques,
      interventionStrategies: interventionStrategies,
      resourcesToUse: resourcesToUse,
      therapeuticTasks: therapeuticTasks,
      monitoringIndicators: monitoringIndicators,
      assessmentInstruments: assessmentInstruments,
      measurementFrequency: measurementFrequency,
      observations: observations,
      availableResources: availableResources,
      supportNetwork: supportNetwork,
      status: status,
      reviewedAt: reviewedAt,
    );
  }
}
