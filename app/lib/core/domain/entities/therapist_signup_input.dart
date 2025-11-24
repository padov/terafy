class TherapistSignupInput {
  final String name;
  final String? nickname;
  final String email;
  final String? document;
  final String? phone;
  final DateTime? birthDate;
  final String? professionalRegistryType;
  final String? professionalRegistryNumber;
  final List<String>? specialties;
  final String? professionalPresentation;
  final String? officeAddress;
  final int? planId;

  const TherapistSignupInput({
    required this.name,
    this.nickname,
    required this.email,
    this.document,
    this.phone,
    this.birthDate,
    this.professionalRegistryType,
    this.professionalRegistryNumber,
    this.specialties,
    this.professionalPresentation,
    this.officeAddress,
    this.planId,
  });

  Map<String, dynamic> toJson() {
    final birthDateString = birthDate != null
        ? birthDate!.toIso8601String().split('T').first
        : null;

    final data = <String, dynamic>{
      'name': name,
      'nickname': nickname,
      'document': document,
      'email': email,
      'phone': phone,
      'birth_date': birthDateString,
      'professional_registry_type': professionalRegistryType,
      'professional_registry_number': professionalRegistryNumber,
      'specialties': specialties,
      'professional_presentation': professionalPresentation,
      'office_address': officeAddress,
      if (planId != null) 'calendar_settings': {'selected_plan_id': planId},
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }
}
