import 'package:terafy/core/domain/repositories/therapeutic_plan_repository.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan.dart';

class GetPlansUseCase {
  const GetPlansUseCase(this._repository);

  final TherapeuticPlanRepository _repository;

  Future<List<TherapeuticPlan>> call({String? patientId, String? status}) {
    return _repository.fetchPlans(patientId: patientId, status: status);
  }
}
