import 'package:equatable/equatable.dart';

// Events - Mesmos eventos do SignupBloc original
abstract class CompleteProfileEvent extends Equatable {
  const CompleteProfileEvent();

  @override
  List<Object?> get props => [];
}

class NextStepPressed extends CompleteProfileEvent {
  const NextStepPressed();
}

class PreviousStepPressed extends CompleteProfileEvent {
  const PreviousStepPressed();
}

class UpdatePersonalData extends CompleteProfileEvent {
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
  List<Object?> get props => [name, nickname, legalDocument, email, phone, birthday];
}

class UpdateProfessionalData extends CompleteProfileEvent {
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
  List<Object?> get props => [specialties, professionalRegistrations, presentation, address];
}

class SelectPlan extends CompleteProfileEvent {
  final int planId;

  const SelectPlan(this.planId);

  @override
  List<Object?> get props => [planId];
}

class SubmitCompleteProfile extends CompleteProfileEvent {
  const SubmitCompleteProfile();
}

class LoadCurrentUserEmail extends CompleteProfileEvent {
  const LoadCurrentUserEmail();
}

// States
abstract class CompleteProfileState extends Equatable {
  final int currentStep;
  final CompleteProfileData data;

  const CompleteProfileState({required this.currentStep, required this.data});

  @override
  List<Object?> get props => [currentStep, data];
}

class CompleteProfileInitial extends CompleteProfileState {
  CompleteProfileInitial({String? initialEmail})
    : super(currentStep: 0, data: CompleteProfileData(email: initialEmail));
}

class CompleteProfileInProgress extends CompleteProfileState {
  const CompleteProfileInProgress({required super.currentStep, required super.data});
}

class CompleteProfileLoading extends CompleteProfileState {
  const CompleteProfileLoading({required super.currentStep, required super.data});
}

class CompleteProfileSuccess extends CompleteProfileState {
  const CompleteProfileSuccess({required super.currentStep, required super.data});
}

class CompleteProfileFailure extends CompleteProfileState {
  final String error;

  const CompleteProfileFailure({required super.currentStep, required super.data, required this.error});

  @override
  List<Object?> get props => [currentStep, data, error];
}

// Data Model - Similar ao SignupData, mas sem password
class CompleteProfileData extends Equatable {
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

  // Step 3 - Plan
  final int? planId;

  const CompleteProfileData({
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
    this.planId,
  });

  CompleteProfileData copyWith({
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
    int? planId,
  }) {
    return CompleteProfileData(
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      legalDocument: legalDocument ?? this.legalDocument,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      specialties: specialties ?? this.specialties,
      professionalRegistrations: professionalRegistrations ?? this.professionalRegistrations,
      presentation: presentation ?? this.presentation,
      address: address ?? this.address,
      planId: planId ?? this.planId,
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
    planId,
  ];
}
