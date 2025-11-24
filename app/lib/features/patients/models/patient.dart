import 'package:equatable/equatable.dart';

enum PatientStatus {
  active,
  evaluated,
  inactive,
  discharged,
  dischargeCompleted,
}

enum Gender { male, female, other, preferNotToSay }

class Patient extends Equatable {
  // Essenciais (Cadastro Rápido)
  final String id;
  final String therapistId;
  final String fullName;
  final String phone;
  final String? email;
  final DateTime? dateOfBirth;

  // Complementares
  final String? cpf;
  final String? rg;
  final Gender? gender;
  final String? maritalStatus;
  final String? address;
  final String? profession;
  final String? education;

  // Emergência
  final EmergencyContact? emergencyContact;
  final LegalGuardian? legalGuardian;

  // Administrativo
  final String? healthInsurance;
  final String? insuranceCardNumber;
  final String? preferredPaymentMethod;
  final double? sessionValue;

  // Termos
  final DateTime? consentDate;
  final DateTime? lgpdAcceptDate;

  // Clínico
  final PatientStatus status;
  final String? inactivationReason;
  final DateTime? treatmentStartDate;
  final DateTime? lastSessionDate;
  final int totalSessions;
  final List<String> tags;
  final String? notes;
  final String? photoUrl;
  final String? agendaColor;

  // Percentual de completude do cadastro
  final double completionPercentage;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const Patient({
    required this.id,
    required this.therapistId,
    required this.fullName,
    required this.phone,
    this.email,
    this.dateOfBirth,
    this.cpf,
    this.rg,
    this.gender,
    this.maritalStatus,
    this.address,
    this.profession,
    this.education,
    this.emergencyContact,
    this.legalGuardian,
    this.healthInsurance,
    this.insuranceCardNumber,
    this.preferredPaymentMethod,
    this.sessionValue,
    this.consentDate,
    this.lgpdAcceptDate,
    this.status = PatientStatus.active,
    this.inactivationReason,
    this.treatmentStartDate,
    this.lastSessionDate,
    this.totalSessions = 0,
    this.tags = const [],
    this.notes,
    this.photoUrl,
    this.agendaColor,
    this.completionPercentage = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Idade calculada
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // Iniciais para avatar
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  // Verifica se é menor de idade
  bool get isMinor {
    final calculatedAge = age;
    return calculatedAge != null && calculatedAge < 18;
  }

  Patient copyWith({
    String? id,
    String? therapistId,
    String? fullName,
    String? phone,
    String? email,
    DateTime? dateOfBirth,
    String? cpf,
    String? rg,
    Gender? gender,
    String? maritalStatus,
    String? address,
    String? profession,
    String? education,
    EmergencyContact? emergencyContact,
    LegalGuardian? legalGuardian,
    String? healthInsurance,
    String? insuranceCardNumber,
    String? preferredPaymentMethod,
    double? sessionValue,
    DateTime? consentDate,
    DateTime? lgpdAcceptDate,
    PatientStatus? status,
    String? inactivationReason,
    DateTime? treatmentStartDate,
    DateTime? lastSessionDate,
    int? totalSessions,
    List<String>? tags,
    String? notes,
    String? photoUrl,
    String? agendaColor,
    double? completionPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      cpf: cpf ?? this.cpf,
      rg: rg ?? this.rg,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      address: address ?? this.address,
      profession: profession ?? this.profession,
      education: education ?? this.education,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      legalGuardian: legalGuardian ?? this.legalGuardian,
      healthInsurance: healthInsurance ?? this.healthInsurance,
      insuranceCardNumber: insuranceCardNumber ?? this.insuranceCardNumber,
      preferredPaymentMethod:
          preferredPaymentMethod ?? this.preferredPaymentMethod,
      sessionValue: sessionValue ?? this.sessionValue,
      consentDate: consentDate ?? this.consentDate,
      lgpdAcceptDate: lgpdAcceptDate ?? this.lgpdAcceptDate,
      status: status ?? this.status,
      inactivationReason: inactivationReason ?? this.inactivationReason,
      treatmentStartDate: treatmentStartDate ?? this.treatmentStartDate,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      totalSessions: totalSessions ?? this.totalSessions,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      agendaColor: agendaColor ?? this.agendaColor,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    therapistId,
    fullName,
    phone,
    email,
    dateOfBirth,
    cpf,
    rg,
    gender,
    maritalStatus,
    address,
    profession,
    education,
    emergencyContact,
    legalGuardian,
    healthInsurance,
    insuranceCardNumber,
    preferredPaymentMethod,
    sessionValue,
    consentDate,
    lgpdAcceptDate,
    status,
    inactivationReason,
    treatmentStartDate,
    lastSessionDate,
    totalSessions,
    tags,
    notes,
    photoUrl,
    agendaColor,
    completionPercentage,
    createdAt,
    updatedAt,
  ];
}

class EmergencyContact extends Equatable {
  final String name;
  final String relationship;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  @override
  List<Object?> get props => [name, relationship, phone];
}

class LegalGuardian extends Equatable {
  final String name;
  final String cpf;
  final String phone;

  const LegalGuardian({
    required this.name,
    required this.cpf,
    required this.phone,
  });

  @override
  List<Object?> get props => [name, cpf, phone];
}
