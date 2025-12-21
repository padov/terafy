import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:terafy/core/domain/repositories/therapist_repository.dart';
import 'package:common/common.dart';
import 'package:terafy/features/ai_config/models/therapist_profile_model.dart';

part 'ai_config_state.dart';

class AiConfigCubit extends Cubit<AiConfigState> {
  final TherapistRepository _therapistRepository;

  AiConfigCubit({required TherapistRepository therapistRepository})
    : _therapistRepository = therapistRepository,
      super(const AiConfigState());

  Future<void> loadProfile() async {
    emit(state.copyWith(status: AiConfigStatus.loading));
    try {
      final therapistMap = await _therapistRepository.getCurrentTherapist();
      // Ensure we have a valid Therapist object
      // Note: TherapistRepository returns Map<String, dynamic>, we convert to Therapist
      final therapist = Therapist.fromMap(therapistMap);

      TherapistProfileModel profile = const TherapistProfileModel();
      if (therapist.aiConfig != null) {
        profile = TherapistProfileModel.fromJson(therapist.aiConfig!);
      }

      emit(state.copyWith(status: AiConfigStatus.loaded, profile: profile, experienceTime: therapist.experienceTime));
    } catch (e) {
      emit(state.copyWith(status: AiConfigStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> saveProfile({required TherapistProfileModel profile, required String? experienceTime}) async {
    emit(state.copyWith(status: AiConfigStatus.saving));
    try {
      // 1. Get current therapist data to ensure we have all fields
      final therapistMap = await _therapistRepository.getCurrentTherapist();
      var therapist = Therapist.fromMap(therapistMap);

      // 2. Update with new AI config and experience time
      therapist = therapist.copyWith(aiConfig: profile.toJson(), experienceTime: experienceTime);

      // 3. Save
      await _therapistRepository.updateTherapist(therapist: therapist);

      emit(state.copyWith(status: AiConfigStatus.success, profile: profile, experienceTime: experienceTime));
    } catch (e) {
      emit(state.copyWith(status: AiConfigStatus.error, errorMessage: e.toString()));
    }
  }

  void updateProfileLocal(TherapistProfileModel profile) {
    emit(state.copyWith(profile: profile));
  }
}
