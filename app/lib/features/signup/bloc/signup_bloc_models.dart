import 'package:equatable/equatable.dart';

// Events
abstract class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object?> get props => [];
}

class NextStepPressed extends SignupEvent {
  const NextStepPressed();
}

class PreviousStepPressed extends SignupEvent {
  const PreviousStepPressed();
}

class UpdatePersonalData extends SignupEvent {
  final String name;
  final String nickname;
  final String legalDocument;
  final String email;
  final String phone;
  final DateTime? birthday;
  final String? password; // Opcional para manter compatibilidade

  const UpdatePersonalData({
    required this.name,
    required this.nickname,
    required this.legalDocument,
    required this.email,
    required this.phone,
    this.birthday,
    this.password,
  });

  @override
  List<Object?> get props => [
    name,
    nickname,
    legalDocument,
    email,
    phone,
    birthday,
    password,
  ];
}

class UpdateProfessionalData extends SignupEvent {
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

class SelectPlan extends SignupEvent {
  final int planId;

  const SelectPlan(this.planId);

  @override
  List<Object?> get props => [planId];
}

class SubmitSignup extends SignupEvent {
  const SubmitSignup();
}

// States
abstract class SignupState extends Equatable {
  final int currentStep;
  final SignupData data;

  const SignupState({required this.currentStep, required this.data});

  @override
  List<Object?> get props => [currentStep, data];
}

class SignupInitial extends SignupState {
  const SignupInitial() : super(currentStep: 0, data: const SignupData());
}

class SignupInProgress extends SignupState {
  const SignupInProgress({required super.currentStep, required super.data});
}

class SignupLoading extends SignupState {
  const SignupLoading({required super.currentStep, required super.data});
}

class SignupSuccess extends SignupState {
  const SignupSuccess({required super.currentStep, required super.data});
}

class SignupFailure extends SignupState {
  final String error;

  const SignupFailure({
    required super.currentStep,
    required super.data,
    required this.error,
  });

  @override
  List<Object?> get props => [currentStep, data, error];
}

// Data Model
class SignupData extends Equatable {
  // Step 1 - Personal Data
  final String? name;
  final String? nickname;
  final String? legalDocument;
  final String? email;
  final String? phone;
  final DateTime? birthday;
  final String? password;

  // Step 2 - Professional Data
  final List<String>? specialties;
  final List<String>? professionalRegistrations;
  final String? presentation;
  final String? address;

  // Step 3 - Plan
  final int? planId;

  const SignupData({
    this.name,
    this.nickname,
    this.legalDocument,
    this.email,
    this.phone,
    this.birthday,
    this.password,
    this.specialties,
    this.professionalRegistrations,
    this.presentation,
    this.address,
    this.planId,
  });

  SignupData copyWith({
    String? name,
    String? nickname,
    String? legalDocument,
    String? email,
    String? phone,
    DateTime? birthday,
    String? password,
    List<String>? specialties,
    List<String>? professionalRegistrations,
    String? presentation,
    String? address,
    int? planId,
  }) {
    return SignupData(
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      legalDocument: legalDocument ?? this.legalDocument,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      password: password ?? this.password,
      specialties: specialties ?? this.specialties,
      professionalRegistrations:
          professionalRegistrations ?? this.professionalRegistrations,
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
    password,
    specialties,
    professionalRegistrations,
    presentation,
    address,
    planId,
  ];
}
