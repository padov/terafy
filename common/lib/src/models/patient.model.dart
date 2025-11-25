import 'dart:convert';

class Patient {
  final int? id;
  final int therapistId;
  final int? userId;
  final String fullName;
  final DateTime? birthDate;
  final int? age;
  final String? cpf;
  final String? rg;
  final String? gender;
  final String? maritalStatus;
  final String? address;
  final String? email;
  final List<String>? phones;
  final String? profession;
  final String? education;
  final Map<String, dynamic>? emergencyContact;
  final Map<String, dynamic>? legalGuardian;
  final String? healthInsurance;
  final String? healthInsuranceCard;
  final String? preferredPaymentMethod;
  final double? sessionPrice;
  final DateTime? consentSignedAt;
  final DateTime? lgpdConsentAt;
  final String status;
  final String? inactivationReason;
  final DateTime? treatmentStartDate;
  final DateTime? lastSessionDate;
  final int totalSessions;
  final List<String>? tags;
  final String? notes;
  final String? photoUrl;
  final String? color;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Patient({
    this.id,
    required this.therapistId,
    this.userId,
    required this.fullName,
    this.birthDate,
    this.age,
    this.cpf,
    this.rg,
    this.gender,
    this.maritalStatus,
    this.address,
    this.email,
    this.phones,
    this.profession,
    this.education,
    this.emergencyContact,
    this.legalGuardian,
    this.healthInsurance,
    this.healthInsuranceCard,
    this.preferredPaymentMethod,
    this.sessionPrice,
    this.consentSignedAt,
    this.lgpdConsentAt,
    this.status = 'active',
    this.inactivationReason,
    this.treatmentStartDate,
    this.lastSessionDate,
    this.totalSessions = 0,
    this.tags,
    this.notes,
    this.photoUrl,
    this.color,
    this.createdAt,
    this.updatedAt,
  });

  Patient copyWith({
    int? id,
    int? therapistId,
    int? userId,
    String? fullName,
    DateTime? birthDate,
    int? age,
    String? cpf,
    String? rg,
    String? gender,
    String? maritalStatus,
    String? address,
    String? email,
    List<String>? phones,
    String? profession,
    String? education,
    Map<String, dynamic>? emergencyContact,
    Map<String, dynamic>? legalGuardian,
    String? healthInsurance,
    String? healthInsuranceCard,
    String? preferredPaymentMethod,
    double? sessionPrice,
    DateTime? consentSignedAt,
    DateTime? lgpdConsentAt,
    String? status,
    String? inactivationReason,
    DateTime? treatmentStartDate,
    DateTime? lastSessionDate,
    int? totalSessions,
    List<String>? tags,
    String? notes,
    String? photoUrl,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      cpf: cpf ?? this.cpf,
      rg: rg ?? this.rg,
      gender: gender ?? this.gender,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      address: address ?? this.address,
      email: email ?? this.email,
      phones: phones ?? this.phones,
      profession: profession ?? this.profession,
      education: education ?? this.education,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      legalGuardian: legalGuardian ?? this.legalGuardian,
      healthInsurance: healthInsurance ?? this.healthInsurance,
      healthInsuranceCard: healthInsuranceCard ?? this.healthInsuranceCard,
      preferredPaymentMethod:
          preferredPaymentMethod ?? this.preferredPaymentMethod,
      sessionPrice: sessionPrice ?? this.sessionPrice,
      consentSignedAt: consentSignedAt ?? this.consentSignedAt,
      lgpdConsentAt: lgpdConsentAt ?? this.lgpdConsentAt,
      status: status ?? this.status,
      inactivationReason: inactivationReason ?? this.inactivationReason,
      treatmentStartDate: treatmentStartDate ?? this.treatmentStartDate,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      totalSessions: totalSessions ?? this.totalSessions,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'therapistId': therapistId,
      'userId': userId,
      'fullName': fullName,
      'birthDate': birthDate?.toIso8601String(),
      'age': age,
      'cpf': cpf,
      'rg': rg,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'address': address,
      'email': email,
      'phones': phones,
      'profession': profession,
      'education': education,
      'emergencyContact': emergencyContact,
      'legalGuardian': legalGuardian,
      'healthInsurance': healthInsurance,
      'healthInsuranceCard': healthInsuranceCard,
      'preferredPaymentMethod': preferredPaymentMethod,
      'sessionPrice': sessionPrice,
      'consentSignedAt': consentSignedAt?.toIso8601String(),
      'lgpdConsentAt': lgpdConsentAt?.toIso8601String(),
      'status': status,
      'inactivationReason': inactivationReason,
      'treatmentStartDate': treatmentStartDate?.toIso8601String(),
      'lastSessionDate': lastSessionDate?.toIso8601String(),
      'totalSessions': totalSessions,
      'tags': tags,
      'notes': notes,
      'photoUrl': photoUrl,
      'color': color,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'therapist_id': therapistId,
      'user_id': userId,
      'full_name': fullName,
      'birth_date': birthDate,
      'age': age,
      'cpf': cpf,
      'rg': rg,
      'gender': gender,
      'marital_status': maritalStatus,
      'address': address,
      'email': email,
      'phones': phones,
      'profession': profession,
      'education': education,
      'emergency_contact': emergencyContact != null
          ? jsonEncode(emergencyContact)
          : null,
      'legal_guardian': legalGuardian != null
          ? jsonEncode(legalGuardian)
          : null,
      'health_insurance': healthInsurance,
      'health_insurance_card': healthInsuranceCard,
      'preferred_payment_method': preferredPaymentMethod,
      'session_price': sessionPrice,
      'consent_signed_at': consentSignedAt,
      'lgpd_consent_at': lgpdConsentAt,
      'status': status,
      'inactivation_reason': inactivationReason,
      'treatment_start_date': treatmentStartDate,
      'last_session_date': lastSessionDate,
      'tags': tags,
      'notes': notes,
      'photo_url': photoUrl,
      'color': color,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return Patient(
      id: map['id'] as int?,
      therapistId: map['therapist_id'] as int,
      userId: map['user_id'] as int?,
      fullName: map['full_name'] as String? ?? '',
      birthDate: _parseDate(map['birth_date']),
      age: map['age'] as int?,
      cpf: map['cpf'] as String?,
      rg: map['rg'] as String?,
      gender: map['gender'] as String?,
      maritalStatus: map['marital_status'] as String?,
      address: map['address'] as String?,
      email: map['email'] as String?,
      phones: _parseStringList(map['phones']),
      profession: map['profession'] as String?,
      education: map['education'] as String?,
      emergencyContact: _parseJsonField(map['emergency_contact']),
      legalGuardian: _parseJsonField(map['legal_guardian']),
      healthInsurance: map['health_insurance'] as String?,
      healthInsuranceCard: map['health_insurance_card'] as String?,
      preferredPaymentMethod: map['preferred_payment_method'] as String?,
      sessionPrice: _parseDouble(map['session_price']),
      consentSignedAt: _parseDate(map['consent_signed_at']),
      lgpdConsentAt: _parseDate(map['lgpd_consent_at']),
      status: _parseEnumField(map['status'], defaultValue: 'active'),
      inactivationReason: map['inactivation_reason'] as String?,
      treatmentStartDate: _parseDate(map['treatment_start_date']),
      lastSessionDate: _parseDate(map['last_session_date']),
      totalSessions: (map['total_sessions'] as int?) ?? 0,
      tags: _parseStringList(map['tags']),
      notes: map['notes'] as String?,
      photoUrl: map['photo_url'] as String?,
      color: map['color'] as String?,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return null;
  }

  static Map<String, dynamic>? _parseJsonField(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _parseEnumField(
    dynamic value, {
    String defaultValue = 'active',
  }) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }
}
