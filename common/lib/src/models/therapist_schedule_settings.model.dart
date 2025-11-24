class TherapistScheduleSettings {
  final int therapistId;
  final Map<String, dynamic> workingHours;
  final int sessionDurationMinutes;
  final int breakMinutes;
  final List<String>? locations;
  final List<DateTime>? daysOff;
  final List<DateTime>? holidays;
  final List<Map<String, dynamic>>? customBlocks;
  final bool reminderEnabled;
  final String reminderDefaultOffset;
  final String reminderDefaultChannel;
  final Map<String, dynamic>? cancellationPolicy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TherapistScheduleSettings({
    required this.therapistId,
    required this.workingHours,
    required this.sessionDurationMinutes,
    required this.breakMinutes,
    this.locations,
    this.daysOff,
    this.holidays,
    this.customBlocks,
    required this.reminderEnabled,
    required this.reminderDefaultOffset,
    required this.reminderDefaultChannel,
    this.cancellationPolicy,
    this.createdAt,
    this.updatedAt,
  });

  TherapistScheduleSettings copyWith({
    int? therapistId,
    Map<String, dynamic>? workingHours,
    int? sessionDurationMinutes,
    int? breakMinutes,
    List<String>? locations,
    List<DateTime>? daysOff,
    List<DateTime>? holidays,
    List<Map<String, dynamic>>? customBlocks,
    bool? reminderEnabled,
    String? reminderDefaultOffset,
    String? reminderDefaultChannel,
    Map<String, dynamic>? cancellationPolicy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TherapistScheduleSettings(
      therapistId: therapistId ?? this.therapistId,
      workingHours: workingHours ?? this.workingHours,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      locations: locations ?? this.locations,
      daysOff: daysOff ?? this.daysOff,
      holidays: holidays ?? this.holidays,
      customBlocks: customBlocks ?? this.customBlocks,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDefaultOffset:
          reminderDefaultOffset ?? this.reminderDefaultOffset,
      reminderDefaultChannel:
          reminderDefaultChannel ?? this.reminderDefaultChannel,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'therapistId': therapistId,
      'workingHours': workingHours,
      'sessionDurationMinutes': sessionDurationMinutes,
      'breakMinutes': breakMinutes,
      'locations': locations,
      'daysOff': daysOff?.map((e) => e.toIso8601String()).toList(),
      'holidays': holidays?.map((e) => e.toIso8601String()).toList(),
      'customBlocks': customBlocks,
      'reminderEnabled': reminderEnabled,
      'reminderDefaultOffset': reminderDefaultOffset,
      'reminderDefaultChannel': reminderDefaultChannel,
      'cancellationPolicy': cancellationPolicy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'therapist_id': therapistId,
      'working_hours': workingHours,
      'session_duration_minutes': sessionDurationMinutes,
      'break_minutes': breakMinutes,
      'locations': locations,
      'days_off': daysOff,
      'holidays': holidays,
      'custom_blocks': customBlocks,
      'reminder_enabled': reminderEnabled,
      'reminder_default_offset': reminderDefaultOffset,
      'reminder_default_channel': reminderDefaultChannel,
      'cancellation_policy': cancellationPolicy,
    };
  }

  factory TherapistScheduleSettings.fromMap(Map<String, dynamic> map) {
    return TherapistScheduleSettings(
      therapistId: map['therapist_id'] as int,
      workingHours:
          (map['working_hours'] as Map?)?.cast<String, dynamic>() ?? const {},
      sessionDurationMinutes:
          map['session_duration_minutes'] as int? ??
          map['session_duration'] as int? ??
          50,
      breakMinutes: map['break_minutes'] as int? ?? 10,
      locations: (map['locations'] as List?)
          ?.map((e) => e?.toString() ?? '')
          .toList(),
      daysOff: _parseDateList(map['days_off']),
      holidays: _parseDateList(map['holidays']),
      customBlocks: _parseMapList(map['custom_blocks']),
      reminderEnabled: map['reminder_enabled'] as bool? ?? true,
      reminderDefaultOffset:
          map['reminder_default_offset']?.toString() ?? '24h',
      reminderDefaultChannel:
          map['reminder_default_channel']?.toString() ?? 'email',
      cancellationPolicy: _mapCast(map['cancellation_policy']),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  factory TherapistScheduleSettings.fromJson(Map<String, dynamic> json) {
    return TherapistScheduleSettings(
      therapistId: json['therapistId'] as int,
      workingHours:
          (json['workingHours'] as Map?)?.cast<String, dynamic>() ?? const {},
      sessionDurationMinutes: json['sessionDurationMinutes'] as int? ?? 50,
      breakMinutes: json['breakMinutes'] as int? ?? 10,
      locations: (json['locations'] as List?)
          ?.map((e) => e?.toString() ?? '')
          .toList(),
      daysOff: _parseDateList(json['daysOff']),
      holidays: _parseDateList(json['holidays']),
      customBlocks: _parseMapList(json['customBlocks']),
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      reminderDefaultOffset: json['reminderDefaultOffset']?.toString() ?? '24h',
      reminderDefaultChannel:
          json['reminderDefaultChannel']?.toString() ?? 'email',
      cancellationPolicy: _mapCast(json['cancellationPolicy']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static List<DateTime>? _parseDateList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((e) => _parseDate(e))
          .where((e) => e != null)
          .cast<DateTime>()
          .toList();
    }
    return null;
  }

  static Map<String, dynamic>? _mapCast(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  static List<Map<String, dynamic>>? _parseMapList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => e.map((key, val) => MapEntry(key.toString(), val)))
          .toList();
    }
    return null;
  }
}
