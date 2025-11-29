import 'package:terafy/features/patients/models/patient.dart';

/// Dados de identificação (Step 1)
class IdentificationData {
  final String fullName;
  final String? cpf;
  final String? rg;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? maritalStatus;
  final String? photoUrl;

  IdentificationData({
    required this.fullName,
    this.cpf,
    this.rg,
    this.dateOfBirth,
    this.gender,
    this.maritalStatus,
    this.photoUrl,
  });

  IdentificationData copyWith({
    String? fullName,
    String? cpf,
    String? rg,
    DateTime? dateOfBirth,
    Gender? gender,
    String? maritalStatus,
    String? photoUrl,
  }) {
    return IdentificationData(
      fullName: fullName ?? this.fullName,
      cpf: cpf ?? this.cpf,
      rg: rg ?? this.rg,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

/// Dados de contato (Step 2)
class ContactData {
  final String phone;
  final String? email;
  final String? address;
  final EmergencyContact? emergencyContact;
  final LegalGuardian? legalGuardian;

  ContactData({
    required this.phone,
    this.email,
    this.address,
    this.emergencyContact,
    this.legalGuardian,
  });

  ContactData copyWith({
    String? phone,
    String? email,
    String? address,
    EmergencyContact? emergencyContact,
    LegalGuardian? legalGuardian,
  }) {
    return ContactData(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      legalGuardian: legalGuardian ?? this.legalGuardian,
    );
  }
}

/// Dados profissionais e sociais (Step 3)
class ProfessionalSocialData {
  final String? profession;
  final String? education;
  final String? socialLife;
  final String? hobbies;

  ProfessionalSocialData({
    this.profession,
    this.education,
    this.socialLife,
    this.hobbies,
  });

  ProfessionalSocialData copyWith({
    String? profession,
    String? education,
    String? socialLife,
    String? hobbies,
  }) {
    return ProfessionalSocialData(
      profession: profession ?? this.profession,
      education: education ?? this.education,
      socialLife: socialLife ?? this.socialLife,
      hobbies: hobbies ?? this.hobbies,
    );
  }
}

/// Dados de saúde (Step 4)
class HealthData {
  final String? healthInsurance;
  final String? insuranceNumber;

  HealthData({
    this.healthInsurance,
    this.insuranceNumber,
  });

  HealthData copyWith({
    String? healthInsurance,
    String? insuranceNumber,
  }) {
    return HealthData(
      healthInsurance: healthInsurance ?? this.healthInsurance,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
    );
  }
}

/// Dados de anamnese (Step 5)
class AnamnesisData {
  final String? chiefComplaint;
  final String? complaintHistory;
  final int? complaintIntensity; // 0-10
  final String? expectations;
  final String? familyHistory;
  final String? developmentHistory;
  final String? sleepPattern;
  final String? diet;
  final String? physicalActivity;

  AnamnesisData({
    this.chiefComplaint,
    this.complaintHistory,
    this.complaintIntensity,
    this.expectations,
    this.familyHistory,
    this.developmentHistory,
    this.sleepPattern,
    this.diet,
    this.physicalActivity,
  });

  AnamnesisData copyWith({
    String? chiefComplaint,
    String? complaintHistory,
    int? complaintIntensity,
    String? expectations,
    String? familyHistory,
    String? developmentHistory,
    String? sleepPattern,
    String? diet,
    String? physicalActivity,
  }) {
    return AnamnesisData(
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      complaintHistory: complaintHistory ?? this.complaintHistory,
      complaintIntensity: complaintIntensity ?? this.complaintIntensity,
      expectations: expectations ?? this.expectations,
      familyHistory: familyHistory ?? this.familyHistory,
      developmentHistory: developmentHistory ?? this.developmentHistory,
      sleepPattern: sleepPattern ?? this.sleepPattern,
      diet: diet ?? this.diet,
      physicalActivity: physicalActivity ?? this.physicalActivity,
    );
  }
}

/// Dados administrativos (Step 6)
class AdministrativeData {
  final double? sessionValue;
  final String? paymentMethod;
  final DateTime? consentDate;
  final DateTime? lgpdAcceptanceDate;
  final List<String> tags;
  final String? generalObservations;
  final String? agendaColor;

  AdministrativeData({
    this.sessionValue,
    this.paymentMethod,
    this.consentDate,
    this.lgpdAcceptanceDate,
    this.tags = const [],
    this.generalObservations,
    this.agendaColor,
  });

  AdministrativeData copyWith({
    double? sessionValue,
    String? paymentMethod,
    DateTime? consentDate,
    DateTime? lgpdAcceptanceDate,
    List<String>? tags,
    String? generalObservations,
    String? agendaColor,
  }) {
    return AdministrativeData(
      sessionValue: sessionValue ?? this.sessionValue,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      consentDate: consentDate ?? this.consentDate,
      lgpdAcceptanceDate: lgpdAcceptanceDate ?? this.lgpdAcceptanceDate,
      tags: tags ?? this.tags,
      generalObservations: generalObservations ?? this.generalObservations,
      agendaColor: agendaColor ?? this.agendaColor,
    );
  }
}

/// Dados completos do registro
class PatientRegistrationData {
  final IdentificationData? identification;
  final ContactData? contact;
  final ProfessionalSocialData? professionalSocial;
  final HealthData? health;
  final AnamnesisData? anamnesis;
  final AdministrativeData? administrative;

  PatientRegistrationData({
    this.identification,
    this.contact,
    this.professionalSocial,
    this.health,
    this.anamnesis,
    this.administrative,
  });

  PatientRegistrationData copyWith({
    IdentificationData? identification,
    ContactData? contact,
    ProfessionalSocialData? professionalSocial,
    HealthData? health,
    AnamnesisData? anamnesis,
    AdministrativeData? administrative,
  }) {
    return PatientRegistrationData(
      identification: identification ?? this.identification,
      contact: contact ?? this.contact,
      professionalSocial: professionalSocial ?? this.professionalSocial,
      health: health ?? this.health,
      anamnesis: anamnesis ?? this.anamnesis,
      administrative: administrative ?? this.administrative,
    );
  }

  bool get isComplete {
    return identification != null && contact != null;
  }

  /// Converte para Patient
  Patient toPatient({Patient? patientToEdit}) {
    final now = DateTime.now();
    
    return Patient(
      id: patientToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      therapistId: patientToEdit?.therapistId ?? 'therapist_1', // TODO: Obter do usuário logado
      fullName: identification?.fullName ?? '',
      phone: contact?.phone ?? '',
      email: contact?.email,
      dateOfBirth: identification?.dateOfBirth,
      cpf: identification?.cpf,
      rg: identification?.rg,
      gender: identification?.gender,
      maritalStatus: identification?.maritalStatus,
      address: contact?.address,
      profession: professionalSocial?.profession,
      education: professionalSocial?.education,
      emergencyContact: contact?.emergencyContact,
      legalGuardian: contact?.legalGuardian,
      healthInsurance: health?.healthInsurance,
      insuranceCardNumber: health?.insuranceNumber,
      preferredPaymentMethod: administrative?.paymentMethod,
      sessionValue: administrative?.sessionValue,
      consentDate: administrative?.consentDate,
      lgpdAcceptDate: administrative?.lgpdAcceptanceDate,
      status: patientToEdit?.status ?? PatientStatus.active,
      inactivationReason: patientToEdit?.inactivationReason,
      treatmentStartDate: patientToEdit?.treatmentStartDate ?? now,
      lastSessionDate: patientToEdit?.lastSessionDate,
      totalSessions: patientToEdit?.totalSessions ?? 0,
      tags: administrative?.tags ?? [],
      notes: administrative?.generalObservations,
      photoUrl: identification?.photoUrl,
      agendaColor: administrative?.agendaColor ?? patientToEdit?.agendaColor ?? '#7C3AED',
      completionPercentage: patientToEdit?.completionPercentage ?? 0.0,
      createdAt: patientToEdit?.createdAt ?? now,
      updatedAt: now,
    );
  }
}

/// Events
abstract class PatientRegistrationEvent {}

class UpdateIdentificationData extends PatientRegistrationEvent {
  final IdentificationData data;
  UpdateIdentificationData(this.data);
}

class UpdateContactData extends PatientRegistrationEvent {
  final ContactData data;
  UpdateContactData(this.data);
}

class UpdateProfessionalSocialData extends PatientRegistrationEvent {
  final ProfessionalSocialData data;
  UpdateProfessionalSocialData(this.data);
}

class UpdateHealthData extends PatientRegistrationEvent {
  final HealthData data;
  UpdateHealthData(this.data);
}

class UpdateAnamnesisData extends PatientRegistrationEvent {
  final AnamnesisData data;
  UpdateAnamnesisData(this.data);
}

class UpdateAdministrativeData extends PatientRegistrationEvent {
  final AdministrativeData data;
  UpdateAdministrativeData(this.data);
}

class NextStepPressed extends PatientRegistrationEvent {}

class PreviousStepPressed extends PatientRegistrationEvent {}

class SavePatientPressed extends PatientRegistrationEvent {}

/// States
abstract class PatientRegistrationState {
  final int currentStep;
  final PatientRegistrationData data;

  PatientRegistrationState({required this.currentStep, required this.data});
}

class PatientRegistrationInitial extends PatientRegistrationState {
  PatientRegistrationInitial()
    : super(currentStep: 0, data: PatientRegistrationData());
}

class PatientRegistrationInProgress extends PatientRegistrationState {
  PatientRegistrationInProgress({
    required super.currentStep,
    required super.data,
  });
}

class PatientRegistrationLoading extends PatientRegistrationState {
  PatientRegistrationLoading({required super.currentStep, required super.data});
}

class PatientRegistrationSuccess extends PatientRegistrationState {
  final Patient patient;

  PatientRegistrationSuccess({
    required this.patient,
    required super.currentStep,
    required super.data,
  });
}

class PatientRegistrationError extends PatientRegistrationState {
  final String message;

  PatientRegistrationError({
    required this.message,
    required super.currentStep,
    required super.data,
  });
}
