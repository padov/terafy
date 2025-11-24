import 'package:equatable/equatable.dart';

enum SessionType { presential, onlineVideo, onlineAudio, phone, group }

enum SessionModality { individual, couple, family, group }

enum SessionStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  draft, // Sessão sendo escrita/não finalizada
  cancelledByTherapist,
  cancelledByPatient,
  noShow,
}

enum PaymentStatus { pending, paid, exempt }

enum RiskLevel { low, medium, high }

class Session extends Equatable {
  // Identificação
  final String id;
  final String patientId;
  final String therapistId;

  // Agendamento
  final String? appointmentId; // Vinculado a um agendamento
  final DateTime scheduledStartTime;
  final DateTime? scheduledEndTime;
  final int durationMinutes;
  final int sessionNumber;

  // Tipo e Modalidade
  final SessionType type;
  final SessionModality modality;
  final String? location; // Se presencial
  final String? onlineRoomLink; // Se online

  // Status
  final SessionStatus status;
  final String? cancellationReason;
  final DateTime? cancellationTime;

  // Financeiro
  final double? chargedAmount;
  final PaymentStatus paymentStatus;

  // Registro Clínico
  final String? patientMood; // Humor/estado emocional
  final List<String> topicsDiscussed; // Temas abordados
  final String? sessionNotes; // Conteúdo da sessão (protegido)
  final String? observedBehavior;
  final List<String> interventionsUsed; // Técnicas utilizadas
  final String? resourcesUsed; // Exercícios, materiais
  final String? homework; // Tarefas/orientações
  final String? patientReactions;
  final String? progressObserved;
  final String? difficultiesIdentified;
  final String? nextSteps;
  final String? nextSessionGoals;
  final bool needsReferral;
  final RiskLevel currentRisk;
  final String? importantObservations;

  // Dados Administrativos
  final DateTime? presenceConfirmationTime;
  final bool reminderSent;
  final DateTime? reminderSentTime;
  final int? patientRating; // Avaliação da sessão (1-5)
  final List<String> attachments; // URLs de anexos

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const Session({
    required this.id,
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
    this.currentRisk = RiskLevel.low,
    this.importantObservations,
    this.presenceConfirmationTime,
    this.reminderSent = false,
    this.reminderSentTime,
    this.patientRating,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Session copyWith({
    String? id,
    String? patientId,
    String? therapistId,
    String? appointmentId,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    int? durationMinutes,
    int? sessionNumber,
    SessionType? type,
    SessionModality? modality,
    String? location,
    String? onlineRoomLink,
    SessionStatus? status,
    String? cancellationReason,
    DateTime? cancellationTime,
    double? chargedAmount,
    PaymentStatus? paymentStatus,
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
    RiskLevel? currentRisk,
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
      difficultiesIdentified:
          difficultiesIdentified ?? this.difficultiesIdentified,
      nextSteps: nextSteps ?? this.nextSteps,
      nextSessionGoals: nextSessionGoals ?? this.nextSessionGoals,
      needsReferral: needsReferral ?? this.needsReferral,
      currentRisk: currentRisk ?? this.currentRisk,
      importantObservations:
          importantObservations ?? this.importantObservations,
      presenceConfirmationTime:
          presenceConfirmationTime ?? this.presenceConfirmationTime,
      reminderSent: reminderSent ?? this.reminderSent,
      reminderSentTime: reminderSentTime ?? this.reminderSentTime,
      patientRating: patientRating ?? this.patientRating,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    therapistId,
    appointmentId,
    scheduledStartTime,
    scheduledEndTime,
    durationMinutes,
    sessionNumber,
    type,
    modality,
    location,
    onlineRoomLink,
    status,
    cancellationReason,
    cancellationTime,
    chargedAmount,
    paymentStatus,
    patientMood,
    topicsDiscussed,
    sessionNotes,
    observedBehavior,
    interventionsUsed,
    resourcesUsed,
    homework,
    patientReactions,
    progressObserved,
    difficultiesIdentified,
    nextSteps,
    nextSessionGoals,
    needsReferral,
    currentRisk,
    importantObservations,
    presenceConfirmationTime,
    reminderSent,
    reminderSentTime,
    patientRating,
    attachments,
    createdAt,
    updatedAt,
  ];
}
