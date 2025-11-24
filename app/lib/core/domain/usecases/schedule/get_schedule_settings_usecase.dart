import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/schedule_repository.dart';

class GetScheduleSettingsUseCase {
  const GetScheduleSettingsUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<TherapistScheduleSettings> call({int? therapistId}) {
    return _repository.fetchSettings(therapistId: therapistId);
  }
}
