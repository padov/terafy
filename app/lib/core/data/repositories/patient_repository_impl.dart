import 'package:common/common.dart' as common;
import 'package:dio/dio.dart';
import 'package:terafy/core/domain/repositories/patient_repository.dart';
import 'package:terafy/features/patients/models/patient.dart' as domain;
import 'package:terafy/package/http.dart';

class PatientRepositoryImpl implements PatientRepository {
  PatientRepositoryImpl({required this.httpClient});

  final HttpClient httpClient;

  @override
  Future<List<domain.Patient>> fetchPatients() async {
    try {
      final response = await httpClient.get('/patients');

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao carregar pacientes');
      }

      final data = response.data;
      if (data is! List) {
        throw Exception('Resposta inesperada ao carregar pacientes');
      }

      return data
          .cast<Map<String, dynamic>>()
          .map(_mapToDomainPatient)
          .toList();
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao carregar pacientes';
      throw Exception(message);
    }
  }

  @override
  Future<domain.Patient> fetchPatientById(String id) async {
    try {
      final response = await httpClient.get('/patients/$id');

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao carregar paciente');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao carregar paciente');
      }

      return _mapToDomainPatient(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao carregar paciente';
      throw Exception(message);
    }
  }

  @override
  Future<domain.Patient> createPatient({
    required String fullName,
    required String phone,
    String? email,
    DateTime? birthDate,
  }) async {
    final payload = <String, dynamic>{
      'fullName': fullName,
      'phones': [phone],
      if (email != null && email.isNotEmpty) 'email': email,
      if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
    };

    try {
      final response = await httpClient.post('/patients', data: payload);

      final isSuccess =
          response.statusCode == 201 || response.statusCode == 200;
      if (!isSuccess || response.data == null) {
        throw Exception('Erro ao criar paciente');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao criar paciente');
      }

      return _mapToDomainPatient(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao criar paciente';
      throw Exception(message);
    }
  }

  domain.Patient _mapToDomainPatient(Map<String, dynamic> json) {
    final commonPatient = common.Patient(
      id: json['id'] as int?,
      therapistId: json['therapistId'] as int? ?? 0,
      userId: json['userId'] as int?,
      fullName: json['fullName'] as String? ?? '',
      birthDate: _parseDate(json['birthDate']),
      age: json['age'] as int?,
      cpf: json['cpf'] as String?,
      rg: json['rg'] as String?,
      gender: json['gender'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      address: json['address'] as String?,
      email: json['email'] as String?,
      phones: _parseStringList(json['phones']),
      profession: json['profession'] as String?,
      education: json['education'] as String?,
      emergencyContact: _parseJsonMap(json['emergencyContact']),
      legalGuardian: _parseJsonMap(json['legalGuardian']),
      healthInsurance: json['healthInsurance'] as String?,
      healthInsuranceCard: json['healthInsuranceCard'] as String?,
      preferredPaymentMethod: json['preferredPaymentMethod'] as String?,
      sessionPrice: _parseDouble(json['sessionPrice']),
      consentSignedAt: _parseDate(json['consentSignedAt']),
      lgpdConsentAt: _parseDate(json['lgpdConsentAt']),
      status: json['status'] as String? ?? 'active',
      inactivationReason: json['inactivationReason'] as String?,
      treatmentStartDate: _parseDate(json['treatmentStartDate']),
      lastSessionDate: _parseDate(json['lastSessionDate']),
      totalSessions: (json['totalSessions'] as int?) ?? 0,
      behavioralProfiles: _parseStringList(json['behavioralProfiles']),
      tags: _parseStringList(json['tags']),
      notes: json['notes'] as String?,
      photoUrl: json['photoUrl'] as String?,
      color: json['color'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );

    return _mapCommonToDomain(commonPatient);
  }

  domain.Patient _mapCommonToDomain(common.Patient patient) {
    final phones = patient.phones ?? const [];
    final emergency = patient.emergencyContact;
    final legalGuardian = patient.legalGuardian;

    return domain.Patient(
      id: patient.id?.toString() ?? '',
      therapistId: patient.therapistId.toString(),
      fullName: patient.fullName,
      phone: phones.isNotEmpty ? phones.first : '',
      email: patient.email,
      dateOfBirth: patient.birthDate,
      cpf: patient.cpf,
      rg: patient.rg,
      gender: _mapGender(patient.gender),
      maritalStatus: patient.maritalStatus,
      address: patient.address,
      profession: patient.profession,
      education: patient.education,
      emergencyContact: emergency == null
          ? null
          : domain.EmergencyContact(
              name: emergency['name']?.toString() ?? '',
              relationship: emergency['relationship']?.toString() ?? '',
              phone: emergency['phone']?.toString() ?? '',
            ),
      legalGuardian: legalGuardian == null
          ? null
          : domain.LegalGuardian(
              name: legalGuardian['name']?.toString() ?? '',
              cpf: legalGuardian['cpf']?.toString() ?? '',
              phone: legalGuardian['phone']?.toString() ?? '',
            ),
      healthInsurance: patient.healthInsurance,
      insuranceCardNumber: patient.healthInsuranceCard,
      preferredPaymentMethod: patient.preferredPaymentMethod,
      sessionValue: patient.sessionPrice,
      consentDate: patient.consentSignedAt,
      lgpdAcceptDate: patient.lgpdConsentAt,
      status: _mapStatus(patient.status),
      inactivationReason: patient.inactivationReason,
      treatmentStartDate: patient.treatmentStartDate,
      lastSessionDate: patient.lastSessionDate,
      totalSessions: patient.totalSessions,
      tags: patient.tags ?? const [],
      notes: patient.notes,
      photoUrl: patient.photoUrl,
      agendaColor: patient.color,
      completionPercentage: _calculateCompletion(
        email: patient.email,
        birthDate: patient.birthDate,
        phones: phones,
      ),
      createdAt: patient.createdAt ?? DateTime.now(),
      updatedAt: patient.updatedAt ?? DateTime.now(),
    );
  }

  double _calculateCompletion({
    String? email,
    DateTime? birthDate,
    List<String>? phones,
  }) {
    int filled = 0;
    const total = 4; // nome, telefone, email, data nascimento

    filled++; // nome
    if (phones != null && phones.isNotEmpty && phones.first.isNotEmpty) {
      filled++;
    }
    if (email != null && email.isNotEmpty) {
      filled++;
    }
    if (birthDate != null) {
      filled++;
    }

    return (filled / total) * 100;
  }

  List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return null;
  }

  Map<String, dynamic>? _parseJsonMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }

  domain.Gender? _mapGender(String? gender) {
    if (gender == null) return null;
    switch (gender.toLowerCase()) {
      case 'male':
      case 'masculino':
        return domain.Gender.male;
      case 'female':
      case 'feminino':
        return domain.Gender.female;
      case 'other':
        return domain.Gender.other;
      case 'prefer_not_to_say':
      case 'prefernottosay':
        return domain.Gender.preferNotToSay;
    }
    return null;
  }

  domain.PatientStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'evaluated':
        return domain.PatientStatus.evaluated;
      case 'inactive':
        return domain.PatientStatus.inactive;
      case 'discharged':
        return domain.PatientStatus.discharged;
      case 'completed':
        return domain.PatientStatus.dischargeCompleted;
      case 'active':
      default:
        return domain.PatientStatus.active;
    }
  }

  String? _extractErrorMessage(DioException exception) {
    if (exception.response?.data is Map<String, dynamic>) {
      final map = exception.response!.data as Map<String, dynamic>;
      final error = map['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    } else if (exception.message != null) {
      return exception.message;
    }
    return null;
  }
}
