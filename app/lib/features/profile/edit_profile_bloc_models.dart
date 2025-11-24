import 'package:equatable/equatable.dart';

// Events
abstract class EditProfileEvent extends Equatable {
  const EditProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileData extends EditProfileEvent {
  const LoadProfileData();
}

class NextStepPressed extends EditProfileEvent {
  const NextStepPressed();
}

class PreviousStepPressed extends EditProfileEvent {
  const PreviousStepPressed();
}

class UpdatePersonalData extends EditProfileEvent {
  final String name;
  final String nickname;
  final String legalDocument;
  final String email;
  final String phone;
  final DateTime? birthday;

  const UpdatePersonalData({
    required this.name,
    required this.nickname,
    required this.legalDocument,
    required this.email,
    required this.phone,
    this.birthday,
  });

  @override
  List<Object?> get props => [
    name,
    nickname,
    legalDocument,
    email,
    phone,
    birthday,
  ];
}

class UpdateProfessionalData extends EditProfileEvent {
  final List<String> specialties;
  final List<String> professionalRegistrations;
  final String presentation;
  final String address;

  const UpdateProfessionalData({
    required this.specialties,
    required this.professionalRegistrations,
    required this.presentation,
    required this.address,
  });

  @override
  List<Object?> get props => [
    specialties,
    professionalRegistrations,
    presentation,
    address,
  ];
}

class SubmitEditProfile extends EditProfileEvent {
  const SubmitEditProfile();
}

// States
abstract class EditProfileState extends Equatable {
  final int currentStep;
  final EditProfileData data;

  const EditProfileState({required this.currentStep, required this.data});

  @override
  List<Object?> get props => [currentStep, data];
}

class EditProfileInitial extends EditProfileState {
  const EditProfileInitial()
    : super(currentStep: 0, data: const EditProfileData());
}

class EditProfileLoading extends EditProfileState {
  const EditProfileLoading({
    required super.currentStep,
    required super.data,
  });
}

class EditProfileLoaded extends EditProfileState {
  const EditProfileLoaded({
    required super.currentStep,
    required super.data,
  });
}

class EditProfileInProgress extends EditProfileState {
  const EditProfileInProgress({
    required super.currentStep,
    required super.data,
  });
}

class EditProfileSaving extends EditProfileState {
  const EditProfileSaving({
    required super.currentStep,
    required super.data,
  });
}

class EditProfileSuccess extends EditProfileState {
  const EditProfileSuccess({
    required super.currentStep,
    required super.data,
  });
}

class EditProfileFailure extends EditProfileState {
  final String error;

  const EditProfileFailure({
    required super.currentStep,
    required super.data,
    required this.error,
  });

  @override
  List<Object?> get props => [currentStep, data, error];
}

// Data Model
class EditProfileData extends Equatable {
  // Step 1 - Personal Data
  final String? name;
  final String? nickname;
  final String? legalDocument;
  final String? email;
  final String? phone;
  final DateTime? birthday;

  // Step 2 - Professional Data
  final List<String>? specialties;
  final List<String>? professionalRegistrations;
  final String? presentation;
  final String? address;

  const EditProfileData({
    this.name,
    this.nickname,
    this.legalDocument,
    this.email,
    this.phone,
    this.birthday,
    this.specialties,
    this.professionalRegistrations,
    this.presentation,
    this.address,
  });

  EditProfileData copyWith({
    String? name,
    String? nickname,
    String? legalDocument,
    String? email,
    String? phone,
    DateTime? birthday,
    List<String>? specialties,
    List<String>? professionalRegistrations,
    String? presentation,
    String? address,
  }) {
    return EditProfileData(
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      legalDocument: legalDocument ?? this.legalDocument,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      specialties: specialties ?? this.specialties,
      professionalRegistrations:
          professionalRegistrations ?? this.professionalRegistrations,
      presentation: presentation ?? this.presentation,
      address: address ?? this.address,
    );
  }

  @override
  List<Object?> get props => [
    name,
    nickname,
    legalDocument,
    email,
    phone,
    birthday,
    specialties,
    professionalRegistrations,
    presentation,
    address,
  ];
}
