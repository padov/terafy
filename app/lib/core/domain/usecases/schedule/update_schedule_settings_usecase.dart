import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/schedule_repository.dart';

class UpdateScheduleSettingsUseCase {
  const UpdateScheduleSettingsUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<TherapistScheduleSettings> call(TherapistScheduleSettings settings) {
    return _repository.updateSettings(settings);
  }
}
