class Appointment {
  final int? id;
  final int therapistId;
  final int? patientId;
  final String? patientName;
  final String type;
  final String status;
  final String? title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic>? recurrenceRule;
  final DateTime? recurrenceEnd;
  final List<DateTime>? recurrenceExceptions;
  final String? location;
  final String? onlineLink;
  final String? color;
  final List<Map<String, dynamic>>? reminders;
  final DateTime? reminderSentAt;
  final DateTime? patientConfirmedAt;
  final DateTime? patientArrivalAt;
  final String? waitingRoomStatus;
  final String? cancellationReason;
  final String? notes;
  final int? parentAppointmentId;
  final int? sessionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Appointment({
    this.id,
    required this.therapistId,
    this.patientId,
    this.patientName,
    required this.type,
    required this.status,
    this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.recurrenceRule,
    this.recurrenceEnd,
    this.recurrenceExceptions,
    this.location,
    this.onlineLink,
    this.color,
    this.reminders,
    this.reminderSentAt,
    this.patientConfirmedAt,
    this.patientArrivalAt,
    this.waitingRoomStatus,
    this.cancellationReason,
    this.notes,
    this.parentAppointmentId,
    this.sessionId,
    this.createdAt,
    this.updatedAt,
  });

  Appointment copyWith({
    int? id,
    int? therapistId,
    int? patientId,
    String? patientName,
    String? type,
    String? status,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, dynamic>? recurrenceRule,
    DateTime? recurrenceEnd,
    List<DateTime>? recurrenceExceptions,
    String? location,
    String? onlineLink,
    String? color,
    List<Map<String, dynamic>>? reminders,
    DateTime? reminderSentAt,
    DateTime? patientConfirmedAt,
    DateTime? patientArrivalAt,
    String? waitingRoomStatus,
    String? cancellationReason,
    String? notes,
    int? parentAppointmentId,
    int? sessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceEnd: recurrenceEnd ?? this.recurrenceEnd,
      recurrenceExceptions: recurrenceExceptions ?? this.recurrenceExceptions,
      location: location ?? this.location,
      onlineLink: onlineLink ?? this.onlineLink,
      color: color ?? this.color,
      reminders: reminders ?? this.reminders,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      patientConfirmedAt: patientConfirmedAt ?? this.patientConfirmedAt,
      patientArrivalAt: patientArrivalAt ?? this.patientArrivalAt,
      waitingRoomStatus: waitingRoomStatus ?? this.waitingRoomStatus,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      notes: notes ?? this.notes,
      parentAppointmentId: parentAppointmentId ?? this.parentAppointmentId,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'therapistId': therapistId,
      'patientId': patientId,
      'patientName': patientName,
      'type': type,
      'status': status,
      'title': title,
      'description': description,
      'startTime': _toUtcIso8601String(startTime),
      'endTime': _toUtcIso8601String(endTime),
      'recurrenceRule': recurrenceRule,
      'recurrenceEnd': recurrenceEnd != null ? _toUtcIso8601String(recurrenceEnd!) : null,
      'recurrenceExceptions': recurrenceExceptions?.map((e) => _toUtcIso8601String(e)).toList(),
      'location': location,
      'onlineLink': onlineLink,
      'color': color,
      'reminders': reminders,
      'reminderSentAt': reminderSentAt != null ? _toUtcIso8601String(reminderSentAt!) : null,
      'patientConfirmedAt': patientConfirmedAt != null ? _toUtcIso8601String(patientConfirmedAt!) : null,
      'patientArrivalAt': patientArrivalAt != null ? _toUtcIso8601String(patientArrivalAt!) : null,
      'waitingRoomStatus': waitingRoomStatus,
      'cancellationReason': cancellationReason,
      'notes': notes,
      'parentAppointmentId': parentAppointmentId,
      'sessionId': sessionId,
      'createdAt': createdAt != null ? _toUtcIso8601String(createdAt!) : null,
      'updatedAt': updatedAt != null ? _toUtcIso8601String(updatedAt!) : null,
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'therapist_id': therapistId,
      'patient_id': patientId,
      'type': type,
      'status': status,
      'title': title,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
      'recurrence_rule': recurrenceRule,
      'recurrence_end': recurrenceEnd,
      'recurrence_exceptions': recurrenceExceptions,
      'location': location,
      'online_link': onlineLink,
      'color': color,
      'reminders': reminders,
      'reminder_sent_at': reminderSentAt,
      'patient_confirmed_at': patientConfirmedAt,
      'patient_arrival_at': patientArrivalAt,
      'waiting_room_status': waitingRoomStatus,
      'cancellation_reason': cancellationReason,
      'notes': notes,
      'parent_appointment_id': parentAppointmentId,
      'session_id': sessionId,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as int?,
      therapistId: map['therapist_id'] as int? ?? map['therapistId'] as int,
      patientId: map['patient_id'] as int? ?? map['patientId'] as int?,
      patientName: (map['patient_name'] ?? map['patientName'] ?? map['patient_full_name']) as String?,
      type: map['type']?.toString() ?? 'session',
      status: map['status']?.toString() ?? 'reserved',
      title: map['title'] as String?,
      description: map['description'] as String?,
      startTime: _parseDate(map['start_time'])!,
      endTime: _parseDate(map['end_time'])!,
      recurrenceRule: (map['recurrence_rule'] as Map?)?.cast<String, dynamic>(),
      recurrenceEnd: _parseDate(map['recurrence_end']),
      recurrenceExceptions: _parseDateList(map['recurrence_exceptions']),
      location: map['location'] as String?,
      onlineLink: map['online_link'] as String?,
      color: map['color'] as String?,
      reminders: _parseReminderList(map['reminders']),
      reminderSentAt: _parseDate(map['reminder_sent_at']),
      patientConfirmedAt: _parseDate(map['patient_confirmed_at']),
      patientArrivalAt: _parseDate(map['patient_arrival_at']),
      waitingRoomStatus: map['waiting_room_status'] as String?,
      cancellationReason: map['cancellation_reason'] as String?,
      notes: map['notes'] as String?,
      parentAppointmentId: map['parent_appointment_id'] as int?,
      sessionId: map['session_id'] as int?,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int?,
      therapistId: json['therapistId'] as int,
      patientId: json['patientId'] as int?,
      patientName: (json['patientName'] ?? json['patient_name']) as String?,
      type: json['type']?.toString() ?? 'session',
      status: json['status']?.toString() ?? 'reserved',
      title: json['title'] as String?,
      description: json['description'] as String?,
      startTime: _parseDate(json['startTime'])!,
      endTime: _parseDate(json['endTime'])!,
      recurrenceRule: (json['recurrenceRule'] as Map?)?.cast<String, dynamic>(),
      recurrenceEnd: _parseDate(json['recurrenceEnd']),
      recurrenceExceptions: _parseDateList(json['recurrenceExceptions']),
      location: json['location'] as String?,
      onlineLink: json['onlineLink'] as String?,
      color: json['color'] as String?,
      reminders: _parseReminderList(json['reminders']),
      reminderSentAt: _parseDate(json['reminderSentAt']),
      patientConfirmedAt: _parseDate(json['patientConfirmedAt']),
      patientArrivalAt: _parseDate(json['patientArrivalAt']),
      waitingRoomStatus: json['waitingRoomStatus'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      notes: json['notes'] as String?,
      parentAppointmentId: () {
        final value = json['parentAppointmentId'];
        if (value == null) return null;
        if (value is int) return value;
        return int.tryParse(value.toString());
      }(),
      sessionId: () {
        final value = json['sessionId'] ?? json['session_id'];
        if (value == null) return null;
        if (value is int) return value;
        return int.tryParse(value.toString());
      }(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    // Se já é DateTime, garante que seja UTC
    if (value is DateTime) {
      return value.isUtc ? value : value.toUtc();
    }

    // Parse da string
    final str = value.toString();
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return null;

    // Se a string não tem timezone explícito (Z ou offset), assume UTC
    // Caso contrário, converte para UTC
    final hasTimezone = str.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(str);

    if (!hasTimezone) {
      // Se não tem timezone, assume que já está em UTC mas precisa marcar como UTC
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );
    }

    // Se tem timezone, converte para UTC
    return parsed.isUtc ? parsed : parsed.toUtc();
  }

  /// Garante que a data seja serializada como ISO8601 com timezone UTC (termina com Z)
  static String _toUtcIso8601String(DateTime dateTime) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    // Garante que sempre termine com Z para indicar UTC
    final iso = utc.toIso8601String();
    return iso.endsWith('Z') ? iso : '${iso}Z';
  }

  static List<DateTime>? _parseDateList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => _parseDate(e)).where((e) => e != null).cast<DateTime>().toList();
    }
    return null;
  }

  static Map<String, dynamic> _mapCast(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {};
  }

  static List<Map<String, dynamic>>? _parseReminderList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => _mapCast(e)).toList();
    }
    if (value is Map) {
      return [_mapCast(value)];
    }
    return null;
  }
}
