class HomeSummary {
  const HomeSummary({
    required this.referenceDate,
    required this.therapistId,
    required this.todayPendingSessions,
    required this.todayConfirmedSessions,
    required this.monthlyCompletionRate,
    required this.monthlySessions,
    required this.listOfTodaySessions,
    this.pendingSessions = const [],
  });

  final DateTime referenceDate;
  final int therapistId;
  final int todayPendingSessions;
  final int todayConfirmedSessions;
  final double monthlyCompletionRate;
  final int monthlySessions;
  final List<HomeAgendaItem> listOfTodaySessions;
  final List<PendingSession> pendingSessions;

  HomeSummary copyWith({
    DateTime? referenceDate,
    int? therapistId,
    int? todayPendingSessions,
    int? todayConfirmedSessions,
    double? monthlyCompletionRate,
    int? monthlySessions,
    List<HomeAgendaItem>? listOfTodaySessions,
    List<PendingSession>? pendingSessions,
  }) {
    return HomeSummary(
      referenceDate: referenceDate ?? this.referenceDate,
      therapistId: therapistId ?? this.therapistId,
      todayPendingSessions: todayPendingSessions ?? this.todayPendingSessions,
      todayConfirmedSessions: todayConfirmedSessions ?? this.todayConfirmedSessions,
      monthlyCompletionRate: monthlyCompletionRate ?? this.monthlyCompletionRate,
      monthlySessions: monthlySessions ?? this.monthlySessions,
      listOfTodaySessions: listOfTodaySessions ?? this.listOfTodaySessions,
      pendingSessions: pendingSessions ?? this.pendingSessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referenceDate': referenceDate.toIso8601String(),
      'therapistId': therapistId,
      'todayPendingSessions': todayPendingSessions,
      'todayConfirmedSessions': todayConfirmedSessions,
      'monthlyCompletionRate': monthlyCompletionRate,
      'monthlySessions': monthlySessions,
      'listOfTodaySessions': listOfTodaySessions.map((item) => item.toJson()).toList(),
      'pendingSessions': pendingSessions.map((item) => item.toJson()).toList(),
    };
  }

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    return HomeSummary(
      referenceDate: DateTime.parse(json['referenceDate'] as String),
      therapistId: json['therapistId'] as int,
      todayPendingSessions: json['todayPendingSessions'] as int,
      todayConfirmedSessions: json['todayConfirmedSessions'] as int,
      monthlyCompletionRate: json['monthlyCompletionRate'] as double,
      monthlySessions: json['monthlySessions'] as int,
      listOfTodaySessions:
          (json['listOfTodaySessions'] as List<dynamic>?)
              ?.map((item) => HomeAgendaItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      pendingSessions:
          (json['pendingSessions'] as List<dynamic>?)
              ?.map((item) => PendingSession.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class HomeAgendaItem {
  const HomeAgendaItem({
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.status,
    this.appointmentId,
    this.title,
    this.description,
    this.patientId,
    this.patientName,
    this.sessionId,
  });

  final int? appointmentId;
  final DateTime startTime;
  final DateTime endTime;
  final String type;
  final String status;
  final String? title;
  final String? description;
  final int? patientId;
  final String? patientName;
  final int? sessionId;

  HomeAgendaItem copyWith({
    int? appointmentId,
    DateTime? startTime,
    DateTime? endTime,
    String? type,
    String? status,
    String? title,
    String? description,
    int? patientId,
    String? patientName,
    int? sessionId,
  }) {
    return HomeAgendaItem(
      appointmentId: appointmentId ?? this.appointmentId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type,
      'status': status,
      'title': title,
      'description': description,
      'patientId': patientId,
      'patientName': patientName,
      'sessionId': sessionId,
    };
  }

  factory HomeAgendaItem.fromJson(Map<String, dynamic> json) {
    return HomeAgendaItem(
      appointmentId: json['appointmentId'] as int?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      type: json['type'] as String? ?? 'session',
      status: json['status'] as String? ?? 'reserved',
      title: json['title'] as String?,
      description: json['description'] as String?,
      patientId: json['patientId'] as int?,
      patientName: json['patientName'] as String?,
      sessionId: json['sessionId'] as int?,
    );
  }
}

class PendingSession {
  const PendingSession({
    required this.id,
    required this.sessionNumber,
    required this.patientId,
    required this.patientName,
    required this.scheduledStartTime,
    required this.status,
  });

  final int id;
  final int sessionNumber;
  final int patientId;
  final String patientName;
  final DateTime scheduledStartTime;
  final String status; // 'draft' or 'completed'

  PendingSession copyWith({
    int? id,
    int? sessionNumber,
    int? patientId,
    String? patientName,
    DateTime? scheduledStartTime,
    String? status,
  }) {
    return PendingSession(
      id: id ?? this.id,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionNumber': sessionNumber,
      'patientId': patientId,
      'patientName': patientName,
      'scheduledStartTime': scheduledStartTime.toIso8601String(),
      'status': status,
    };
  }

  factory PendingSession.fromJson(Map<String, dynamic> json) {
    return PendingSession(
      id: json['id'] as int,
      sessionNumber: json['sessionNumber'] as int,
      patientId: json['patientId'] as int,
      patientName: json['patientName'] as String,
      scheduledStartTime: DateTime.parse(json['scheduledStartTime'] as String),
      status: json['status'] as String,
    );
  }
}
