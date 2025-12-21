part of 'ai_config_cubit.dart';

enum AiConfigStatus { initial, loading, loaded, saving, success, error }

class AiConfigState extends Equatable {
  final AiConfigStatus status;
  final TherapistProfileModel profile;
  final String? experienceTime;
  final String? errorMessage;

  const AiConfigState({
    this.status = AiConfigStatus.initial,
    this.profile = const TherapistProfileModel(),
    this.experienceTime,
    this.errorMessage,
  });

  AiConfigState copyWith({
    AiConfigStatus? status,
    TherapistProfileModel? profile,
    String? experienceTime,
    String? errorMessage,
  }) {
    return AiConfigState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      experienceTime: experienceTime ?? this.experienceTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, experienceTime, errorMessage];
}
