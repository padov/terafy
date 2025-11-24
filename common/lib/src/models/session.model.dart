class Session {
  final int? id;
  final int patientId;
  final int therapistId;
  final int? appointmentId; // Nullable - sessão pode existir sem agendamento
  final DateTime scheduledStartTime;
  final DateTime? scheduledEndTime;
  final int durationMinutes;
  final int sessionNumber; // Sequencial por paciente
  final String type; // session_type enum
  final String modality; // session_modality enum
  final String? location; // Se presencial
  final String? onlineRoomLink; // Se online
  final String status; // session_status enum
  final String? cancellationReason;
  final DateTime? cancellationTime;
  final double? chargedAmount;
  final String paymentStatus; // payment_status enum
  
  // Registro Clínico
  final String? patientMood;
  final List<String> topicsDiscussed;
  final String? sessionNotes;
  final String? observedBehavior;
  final List<String> interventionsUsed;
  final String? resourcesUsed;
  final String? homework;
  final String? patientReactions;
  final String? progressObserved;
  final String? difficultiesIdentified;
  final String? nextSteps;
  final String? nextSessionGoals;
  final bool needsReferral;
  final String currentRisk; // 'low', 'medium', 'high'
  final String? importantObservations;
  
  // Dados Administrativos
  final DateTime? presenceConfirmationTime;
  final bool reminderSent;
  final DateTime? reminderSentTime;
  final int? patientRating;
  final List<String> attachments;
  
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Session({
    this.id,
    required this.patientId,
    required this.therapistId,
    this.appointmentId,
    required this.scheduledStartTime,
    this.scheduledEndTime,
    required this.durationMinutes,
    required this.sessionNumber,
    required this.type,
    required this.modality,
    this.location,
    this.onlineRoomLink,
    required this.status,
    this.cancellationReason,
    this.cancellationTime,
    this.chargedAmount,
    required this.paymentStatus,
    this.patientMood,
    this.topicsDiscussed = const [],
    this.sessionNotes,
    this.observedBehavior,
    this.interventionsUsed = const [],
    this.resourcesUsed,
    this.homework,
    this.patientReactions,
    this.progressObserved,
    this.difficultiesIdentified,
    this.nextSteps,
    this.nextSessionGoals,
    this.needsReferral = false,
    this.currentRisk = 'low',
    this.importantObservations,
    this.presenceConfirmationTime,
    this.reminderSent = false,
    this.reminderSentTime,
    this.patientRating,
    this.attachments = const [],
    this.createdAt,
    this.updatedAt,
  });

  Session copyWith({
    int? id,
    int? patientId,
    int? therapistId,
    int? appointmentId,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    int? durationMinutes,
    int? sessionNumber,
    String? type,
    String? modality,
    String? location,
    String? onlineRoomLink,
    String? status,
    String? cancellationReason,
    DateTime? cancellationTime,
    double? chargedAmount,
    String? paymentStatus,
    String? patientMood,
    List<String>? topicsDiscussed,
    String? sessionNotes,
    String? observedBehavior,
    List<String>? interventionsUsed,
    String? resourcesUsed,
    String? homework,
    String? patientReactions,
    String? progressObserved,
    String? difficultiesIdentified,
    String? nextSteps,
    String? nextSessionGoals,
    bool? needsReferral,
    String? currentRisk,
    String? importantObservations,
    DateTime? presenceConfirmationTime,
    bool? reminderSent,
    DateTime? reminderSentTime,
    int? patientRating,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      therapistId: therapistId ?? this.therapistId,
      appointmentId: appointmentId ?? this.appointmentId,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      type: type ?? this.type,
      modality: modality ?? this.modality,
      location: location ?? this.location,
      onlineRoomLink: onlineRoomLink ?? this.onlineRoomLink,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationTime: cancellationTime ?? this.cancellationTime,
      chargedAmount: chargedAmount ?? this.chargedAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      patientMood: patientMood ?? this.patientMood,
      topicsDiscussed: topicsDiscussed ?? this.topicsDiscussed,
      sessionNotes: sessionNotes ?? this.sessionNotes,
      observedBehavior: observedBehavior ?? this.observedBehavior,
      interventionsUsed: interventionsUsed ?? this.interventionsUsed,
      resourcesUsed: resourcesUsed ?? this.resourcesUsed,
      homework: homework ?? this.homework,
      patientReactions: patientReactions ?? this.patientReactions,
      progressObserved: progressObserved ?? this.progressObserved,
      difficultiesIdentified: difficultiesIdentified ?? this.difficultiesIdentified,
      nextSteps: nextSteps ?? this.nextSteps,
      nextSessionGoals: nextSessionGoals ?? this.nextSessionGoals,
      needsReferral: needsReferral ?? this.needsReferral,
      currentRisk: currentRisk ?? this.currentRisk,
      importantObservations: importantObservations ?? this.importantObservations,
      presenceConfirmationTime: presenceConfirmationTime ?? this.presenceConfirmationTime,
      reminderSent: reminderSent ?? this.reminderSent,
      reminderSentTime: reminderSentTime ?? this.reminderSentTime,
      patientRating: patientRating ?? this.patientRating,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'therapistId': therapistId,
      'appointmentId': appointmentId,
      'scheduledStartTime': scheduledStartTime.toIso8601String(),
      'scheduledEndTime': scheduledEndTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'sessionNumber': sessionNumber,
      'type': type,
      'modality': modality,
      'location': location,
      'onlineRoomLink': onlineRoomLink,
      'status': status,
      'cancellationReason': cancellationReason,
      'cancellationTime': cancellationTime?.toIso8601String(),
      'chargedAmount': chargedAmount,
      'paymentStatus': paymentStatus,
      'patientMood': patientMood,
      'topicsDiscussed': topicsDiscussed,
      'sessionNotes': sessionNotes,
      'observedBehavior': observedBehavior,
      'interventionsUsed': interventionsUsed,
      'resourcesUsed': resourcesUsed,
      'homework': homework,
      'patientReactions': patientReactions,
      'progressObserved': progressObserved,
      'difficultiesIdentified': difficultiesIdentified,
      'nextSteps': nextSteps,
      'nextSessionGoals': nextSessionGoals,
      'needsReferral': needsReferral,
      'currentRisk': currentRisk,
      'importantObservations': importantObservations,
      'presenceConfirmationTime': presenceConfirmationTime?.toIso8601String(),
      'reminderSent': reminderSent,
      'reminderSentTime': reminderSentTime?.toIso8601String(),
      'patientRating': patientRating,
      'attachments': attachments,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'patient_id': patientId,
      'therapist_id': therapistId,
      'appointment_id': appointmentId,
      'scheduled_start_time': scheduledStartTime,
      'scheduled_end_time': scheduledEndTime,
      'duration_minutes': durationMinutes,
      'session_number': sessionNumber,
      'type': type,
      'modality': modality,
      'location': location,
      'online_room_link': onlineRoomLink,
      'status': status,
      'cancellation_reason': cancellationReason,
      'cancellation_time': cancellationTime,
      'charged_amount': chargedAmount,
      'payment_status': paymentStatus,
      'patient_mood': patientMood,
      'topics_discussed': topicsDiscussed,
      'session_notes': sessionNotes,
      'observed_behavior': observedBehavior,
      'interventions_used': interventionsUsed,
      'resources_used': resourcesUsed,
      'homework': homework,
      'patient_reactions': patientReactions,
      'progress_observed': progressObserved,
      'difficulties_identified': difficultiesIdentified,
      'next_steps': nextSteps,
      'next_session_goals': nextSessionGoals,
      'needs_referral': needsReferral,
      'current_risk': currentRisk,
      'important_observations': importantObservations,
      'presence_confirmation_time': presenceConfirmationTime,
      'reminder_sent': reminderSent,
      'reminder_sent_time': reminderSentTime,
      'patient_rating': patientRating,
      'attachments': attachments,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as int?,
      patientId: json['patientId'] as int,
      therapistId: json['therapistId'] as int,
      appointmentId: json['appointmentId'] as int?,
      scheduledStartTime: DateTime.parse(json['scheduledStartTime'] as String),
      scheduledEndTime: json['scheduledEndTime'] != null
          ? DateTime.parse(json['scheduledEndTime'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int,
      sessionNumber: json['sessionNumber'] as int,
      type: json['type'] as String,
      modality: json['modality'] as String,
      location: json['location'] as String?,
      onlineRoomLink: json['onlineRoomLink'] as String?,
      status: json['status'] as String,
      cancellationReason: json['cancellationReason'] as String?,
      cancellationTime: json['cancellationTime'] != null
          ? DateTime.parse(json['cancellationTime'] as String)
          : null,
      chargedAmount: json['chargedAmount'] != null
          ? (json['chargedAmount'] as num).toDouble()
          : null,
      paymentStatus: json['paymentStatus'] as String,
      patientMood: json['patientMood'] as String?,
      topicsDiscussed: json['topicsDiscussed'] != null
          ? List<String>.from(json['topicsDiscussed'] as List)
          : const [],
      sessionNotes: json['sessionNotes'] as String?,
      observedBehavior: json['observedBehavior'] as String?,
      interventionsUsed: json['interventionsUsed'] != null
          ? List<String>.from(json['interventionsUsed'] as List)
          : const [],
      resourcesUsed: json['resourcesUsed'] as String?,
      homework: json['homework'] as String?,
      patientReactions: json['patientReactions'] as String?,
      progressObserved: json['progressObserved'] as String?,
      difficultiesIdentified: json['difficultiesIdentified'] as String?,
      nextSteps: json['nextSteps'] as String?,
      nextSessionGoals: json['nextSessionGoals'] as String?,
      needsReferral: json['needsReferral'] as bool? ?? false,
      currentRisk: json['currentRisk'] as String? ?? 'low',
      importantObservations: json['importantObservations'] as String?,
      presenceConfirmationTime: json['presenceConfirmationTime'] != null
          ? DateTime.parse(json['presenceConfirmationTime'] as String)
          : null,
      reminderSent: json['reminderSent'] as bool? ?? false,
      reminderSentTime: json['reminderSentTime'] != null
          ? DateTime.parse(json['reminderSentTime'] as String)
          : null,
      patientRating: json['patientRating'] as int?,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : const [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: _parseInt(map['id']),
      patientId: _parseInt(map['patient_id']) ?? 0,
      therapistId: _parseInt(map['therapist_id']) ?? 0,
      appointmentId: _parseInt(map['appointment_id']),
      scheduledStartTime: _parseDate(map['scheduled_start_time'])!,
      scheduledEndTime: _parseDate(map['scheduled_end_time']),
      durationMinutes: _parseInt(map['duration_minutes']) ?? 0,
      sessionNumber: _parseInt(map['session_number']) ?? 0,
      type: map['type']?.toString() ?? 'presential',
      modality: map['modality']?.toString() ?? 'individual',
      location: map['location'] as String?,
      onlineRoomLink: map['online_room_link'] as String?,
      status: map['status']?.toString() ?? 'scheduled',
      cancellationReason: map['cancellation_reason'] as String?,
      cancellationTime: _parseDate(map['cancellation_time']),
      chargedAmount: _parseDouble(map['charged_amount']),
      paymentStatus: map['payment_status']?.toString() ?? 'pending',
      patientMood: map['patient_mood'] as String?,
      topicsDiscussed: _parseStringList(map['topics_discussed']),
      sessionNotes: map['session_notes'] as String?,
      observedBehavior: map['observed_behavior'] as String?,
      interventionsUsed: _parseStringList(map['interventions_used']),
      resourcesUsed: map['resources_used'] as String?,
      homework: map['homework'] as String?,
      patientReactions: map['patient_reactions'] as String?,
      progressObserved: map['progress_observed'] as String?,
      difficultiesIdentified: map['difficulties_identified'] as String?,
      nextSteps: map['next_steps'] as String?,
      nextSessionGoals: map['next_session_goals'] as String?,
      needsReferral: map['needs_referral'] as bool? ?? false,
      currentRisk: map['current_risk']?.toString() ?? 'low',
      importantObservations: map['important_observations'] as String?,
      presenceConfirmationTime: _parseDate(map['presence_confirmation_time']),
      reminderSent: map['reminder_sent'] as bool? ?? false,
      reminderSentTime: _parseDate(map['reminder_sent_time']),
      patientRating: _parseInt(map['patient_rating']),
      attachments: _parseStringList(map['attachments']),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    // PostgreSQL NUMERIC pode vir como String
    return double.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    // PostgreSQL INTEGER pode vir como String
    return int.tryParse(value.toString());
  }
}
