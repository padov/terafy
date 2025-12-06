import 'package:equatable/equatable.dart';

/// Tipo de agendamento
enum AppointmentType {
  session, // Sessão com paciente
  personal, // Compromisso pessoal
  block, // Bloqueio de horário
}

/// Status do agendamento
enum AppointmentStatus {
  reserved, // Agendado
  confirmed, // Confirmado pelo paciente
  completed, // Realizado
  cancelled, // Cancelado
  noShow, // Paciente não compareceu
}

/// Tipo de recorrência
enum RecurrenceType {
  none, // Único
  daily, // Diário
  weekly, // Semanal
}

/// Canal de lembrete
enum ReminderChannel { email, sms, whatsapp, push }

/// Configuração de lembrete
class ReminderConfig extends Equatable {
  final bool enabled;
  final Duration antecedence;
  final ReminderChannel channel;
  final String? customMessage;

  const ReminderConfig({
    required this.enabled,
    required this.antecedence,
    required this.channel,
    this.customMessage,
  });

  @override
  List<Object?> get props => [enabled, antecedence, channel, customMessage];

  ReminderConfig copyWith({
    bool? enabled,
    Duration? antecedence,
    ReminderChannel? channel,
    String? customMessage,
  }) {
    return ReminderConfig(
      enabled: enabled ?? this.enabled,
      antecedence: antecedence ?? this.antecedence,
      channel: channel ?? this.channel,
      customMessage: customMessage ?? this.customMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'antecedence': antecedence.inMinutes,
      'channel': channel.name,
      'customMessage': customMessage,
    };
  }

  factory ReminderConfig.fromJson(Map<String, dynamic> json) {
    return ReminderConfig(
      enabled: json['enabled'] as bool,
      antecedence: Duration(minutes: json['antecedence'] as int),
      channel: ReminderChannel.values.firstWhere(
        (e) => e.name == json['channel'],
      ),
      customMessage: json['customMessage'] as String?,
    );
  }
}

/// Modelo de Agendamento
class Appointment extends Equatable {
  final String id;
  final String therapistId;
  final String? patientId;
  final String? patientName;
  final DateTime dateTime;
  final Duration duration;
  final AppointmentType type;
  final AppointmentStatus status;
  final RecurrenceType recurrence;
  final DateTime? recurrenceEndDate;
  final List<DateTime>? recurrenceExceptions;
  final Map<String, dynamic>? recurrenceRule;
  final String? color;
  final List<ReminderConfig> reminders;
  final DateTime? reminderSentAt;
  final DateTime? confirmedAt;
  final String? notes;
  final String? room;
  final String? onlineLink;
  final DateTime? arrivedAt;
  final String? sessionId; // Link para sessão criada
  final String? parentAppointmentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Appointment({
    required this.id,
    required this.therapistId,
    this.patientId,
    this.patientName,
    required this.dateTime,
    required this.duration,
    required this.type,
    required this.status,
    this.recurrence = RecurrenceType.none,
    this.recurrenceEndDate,
    this.recurrenceExceptions,
    this.recurrenceRule,
    this.color,
    this.reminders = const [],
    this.reminderSentAt,
    this.confirmedAt,
    this.notes,
    this.room,
    this.onlineLink,
    this.arrivedAt,
    this.sessionId,
    this.parentAppointmentId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    therapistId,
    patientId,
    patientName,
    dateTime,
    duration,
    type,
    status,
    recurrence,
    recurrenceEndDate,
    recurrenceExceptions,
    recurrenceRule,
    color,
    reminders,
    reminderSentAt,
    confirmedAt,
    notes,
    room,
    onlineLink,
    arrivedAt,
    sessionId,
    parentAppointmentId,
    createdAt,
    updatedAt,
  ];

  /// Horário de término
  DateTime get endTime => dateTime.add(duration);

  /// Verifica se está atrasado
  bool get isLate {
    if (status != AppointmentStatus.reserved &&
        status != AppointmentStatus.confirmed) {
      return false;
    }
    return DateTime.now().isAfter(dateTime);
  }

  /// Verifica se é hoje
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Verifica se pode ser cancelado
  bool get canBeCancelled {
    return status == AppointmentStatus.reserved ||
        status == AppointmentStatus.confirmed;
  }

  /// Verifica se pode ser confirmado
  bool get canBeConfirmed {
    return status == AppointmentStatus.reserved;
  }

  Appointment copyWith({
    String? id,
    String? therapistId,
    String? patientId,
    String? patientName,
    DateTime? dateTime,
    Duration? duration,
    AppointmentType? type,
    AppointmentStatus? status,
    RecurrenceType? recurrence,
    DateTime? recurrenceEndDate,
    List<DateTime>? recurrenceExceptions,
    Map<String, dynamic>? recurrenceRule,
    String? color,
    List<ReminderConfig>? reminders,
    DateTime? reminderSentAt,
    DateTime? confirmedAt,
    String? notes,
    String? room,
    String? onlineLink,
    DateTime? arrivedAt,
    String? sessionId,
    String? parentAppointmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      status: status ?? this.status,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceExceptions: recurrenceExceptions ?? this.recurrenceExceptions,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      color: color ?? this.color,
      reminders: reminders ?? this.reminders,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      notes: notes ?? this.notes,
      room: room ?? this.room,
      onlineLink: onlineLink ?? this.onlineLink,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      sessionId: sessionId ?? this.sessionId,
      parentAppointmentId: parentAppointmentId ?? this.parentAppointmentId,
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
      'dateTime': dateTime.toIso8601String(),
      'duration': duration.inMinutes,
      'type': type.name,
      'status': status.name,
      'recurrence': recurrence.name,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'recurrenceExceptions': recurrenceExceptions
          ?.map((date) => date.toIso8601String())
          .toList(),
      'recurrenceRule': recurrenceRule,
      'color': color,
      'reminders': reminders.map((e) => e.toJson()).toList(),
      'reminderSentAt': reminderSentAt?.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'notes': notes,
      'room': room,
      'onlineLink': onlineLink,
      'arrivedAt': arrivedAt?.toIso8601String(),
      'sessionId': sessionId,
      'parentAppointmentId': parentAppointmentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      therapistId: json['therapistId'] as String,
      patientId: json['patientId'] as String?,
      patientName: json['patientName'] as String?,
      dateTime: DateTime.parse(json['dateTime'] as String),
      duration: Duration(minutes: json['duration'] as int),
      type: AppointmentType.values.firstWhere((e) => e.name == json['type']),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.name == json['recurrence'],
      ),
      recurrenceEndDate: json['recurrenceEndDate'] != null
          ? DateTime.parse(json['recurrenceEndDate'] as String)
          : null,
      recurrenceExceptions: json['recurrenceExceptions'] != null
          ? (json['recurrenceExceptions'] as List)
                .map((e) => DateTime.parse(e as String))
                .toList()
          : null,
      recurrenceRule: json['recurrenceRule'] != null
          ? Map<String, dynamic>.from(json['recurrenceRule'] as Map)
          : null,
      color: json['color'] as String?,
      reminders: json['reminders'] != null
          ? (json['reminders'] as List)
                .map((e) => ReminderConfig.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      reminderSentAt: json['reminderSentAt'] != null
          ? DateTime.parse(json['reminderSentAt'] as String)
          : null,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      notes: json['notes'] as String?,
      room: json['room'] as String?,
      onlineLink: json['onlineLink'] as String?,
      arrivedAt: json['arrivedAt'] != null
          ? DateTime.parse(json['arrivedAt'] as String)
          : null,
      sessionId: json['sessionId'] as String?,
      parentAppointmentId: json['parentAppointmentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
