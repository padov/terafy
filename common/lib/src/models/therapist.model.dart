import 'dart:convert';

class Therapist {
  final int? id;
  final String name;
  final String? nickname;
  final String? document;
  final String email;
  final String? phone;
  final DateTime? birthDate;
  final String? profilePictureUrl;
  final String? professionalRegistryType;
  final String? professionalRegistryNumber;
  final List<String>? specialties;
  final String? education;
  final String? professionalPresentation;
  final String? officeAddress;
  final Map<String, dynamic>? calendarSettings;
  final Map<String, dynamic>? notificationPreferences;
  final Map<String, dynamic>? bankDetails;
  final String status; // 'active', 'suspended', 'canceled'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Therapist({
    this.id,
    required this.name,
    this.nickname,
    this.document,
    required this.email,
    this.phone,
    this.birthDate,
    this.profilePictureUrl,
    this.professionalRegistryType,
    this.professionalRegistryNumber,
    this.specialties,
    this.education,
    this.professionalPresentation,
    this.officeAddress,
    this.calendarSettings,
    this.notificationPreferences,
    this.bankDetails,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nickname': nickname,
      'document': document,
      'email': email,
      'phone': phone,
      'birth_date': birthDate?.toIso8601String(),
      'profile_picture_url': profilePictureUrl,
      'professional_registry_type': professionalRegistryType,
      'professional_registry_number': professionalRegistryNumber,
      'specialties': specialties,
      'education': education,
      'professional_presentation': professionalPresentation,
      'office_address': officeAddress,
      'calendar_settings': calendarSettings,
      'notification_preferences': notificationPreferences,
      'bank_details': bankDetails,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper para parsear campos JSONB que podem vir como String ou Map
  static Map<String, dynamic>? _parseJsonField(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String) {
      try {
        return jsonDecode(value) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Helper para parsear campos ENUM que podem vir como UndecodedBytes
  static String _parseEnumField(dynamic value, {String defaultValue = 'active'}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    // Para UndecodedBytes ou outros tipos do PostgreSQL
    try {
      return value.toString().trim();
    } catch (e) {
      return defaultValue;
    }
  }

  factory Therapist.fromMap(Map<String, dynamic> map) {
    return Therapist(
      id: map['id'] as int?,
      name: map['name'] as String,
      nickname: map['nickname'] as String?,
      document: map['document'] as String?,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      birthDate: map['birth_date'] != null
          ? DateTime.parse(map['birth_date'].toString())
          : null,
      profilePictureUrl: map['profile_picture_url'] as String?,
      professionalRegistryType: map['professional_registry_type'] as String?,
      professionalRegistryNumber: map['professional_registry_number'] as String?,
      specialties: map['specialties'] != null
          ? List<String>.from(map['specialties'] as List)
          : null,
      education: map['education'] as String?,
      professionalPresentation: map['professional_presentation'] as String?,
      officeAddress: map['office_address'] as String?,
      calendarSettings: _parseJsonField(map['calendar_settings']),
      notificationPreferences: _parseJsonField(map['notification_preferences']),
      bankDetails: _parseJsonField(map['bank_details']),
      status: _parseEnumField(map['status'], defaultValue: 'active'),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : null,
    );
  }
}

