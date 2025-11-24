import 'package:common/common.dart' as common;
import 'package:terafy/features/sessions/models/session.dart' as ui;

ui.Session mapToUiSession(common.Session session) {
  return ui.Session(
    id: session.id?.toString() ?? '',
    patientId: session.patientId.toString(),
    therapistId: session.therapistId.toString(),
    appointmentId: session.appointmentId?.toString(),
    scheduledStartTime: session.scheduledStartTime.toLocal(),
    scheduledEndTime: session.scheduledEndTime?.toLocal(),
    durationMinutes: session.durationMinutes,
    sessionNumber: session.sessionNumber,
    type: _mapTypeFromString(session.type),
    modality: _mapModalityFromString(session.modality),
    location: session.location,
    onlineRoomLink: session.onlineRoomLink,
    status: _mapStatusFromString(session.status),
    cancellationReason: session.cancellationReason,
    cancellationTime: session.cancellationTime?.toLocal(),
    chargedAmount: session.chargedAmount,
    paymentStatus: _mapPaymentStatusFromString(session.paymentStatus),
    // Campos de registro clínico
    patientMood: session.patientMood,
    topicsDiscussed: session.topicsDiscussed,
    sessionNotes: session.sessionNotes,
    observedBehavior: session.observedBehavior,
    interventionsUsed: session.interventionsUsed,
    resourcesUsed: session.resourcesUsed,
    homework: session.homework,
    patientReactions: session.patientReactions,
    progressObserved: session.progressObserved,
    difficultiesIdentified: session.difficultiesIdentified,
    nextSteps: session.nextSteps,
    nextSessionGoals: session.nextSessionGoals,
    needsReferral: session.needsReferral,
    currentRisk: _mapRiskLevelFromString(session.currentRisk),
    importantObservations: session.importantObservations,
    // Dados administrativos
    presenceConfirmationTime: session.presenceConfirmationTime?.toLocal(),
    reminderSent: session.reminderSent,
    reminderSentTime: session.reminderSentTime?.toLocal(),
    patientRating: session.patientRating,
    attachments: session.attachments,
    createdAt: session.createdAt?.toLocal() ?? DateTime.now(),
    updatedAt: session.updatedAt?.toLocal() ?? DateTime.now(),
  );
}

common.Session mapToDomainSession(ui.Session session) {
  return common.Session(
    id: int.tryParse(session.id),
    patientId: int.tryParse(session.patientId) ?? 0,
    therapistId: int.tryParse(session.therapistId) ?? 0,
    appointmentId: session.appointmentId != null
        ? int.tryParse(session.appointmentId!)
        : null,
    scheduledStartTime: session.scheduledStartTime.toUtc(),
    scheduledEndTime: session.scheduledEndTime?.toUtc(),
    durationMinutes: session.durationMinutes,
    sessionNumber: session.sessionNumber,
    type: _mapTypeToString(session.type),
    modality: _mapModalityToString(session.modality),
    location: session.location,
    onlineRoomLink: session.onlineRoomLink,
    status: _mapStatusToString(session.status),
    cancellationReason: session.cancellationReason,
    cancellationTime: session.cancellationTime?.toUtc(),
    chargedAmount: session.chargedAmount,
    paymentStatus: _mapPaymentStatusToString(session.paymentStatus),
    // Campos de registro clínico
    patientMood: session.patientMood,
    topicsDiscussed: session.topicsDiscussed,
    sessionNotes: session.sessionNotes,
    observedBehavior: session.observedBehavior,
    interventionsUsed: session.interventionsUsed,
    resourcesUsed: session.resourcesUsed,
    homework: session.homework,
    patientReactions: session.patientReactions,
    progressObserved: session.progressObserved,
    difficultiesIdentified: session.difficultiesIdentified,
    nextSteps: session.nextSteps,
    nextSessionGoals: session.nextSessionGoals,
    needsReferral: session.needsReferral,
    currentRisk: _mapRiskLevelToString(session.currentRisk),
    importantObservations: session.importantObservations,
    // Dados administrativos
    presenceConfirmationTime: session.presenceConfirmationTime?.toUtc(),
    reminderSent: session.reminderSent,
    reminderSentTime: session.reminderSentTime?.toUtc(),
    patientRating: session.patientRating,
    attachments: session.attachments,
    createdAt: session.createdAt.toUtc(),
    updatedAt: session.updatedAt.toUtc(),
  );
}

ui.SessionType _mapTypeFromString(String type) {
  switch (type) {
    case 'presential':
      return ui.SessionType.presential;
    case 'onlineVideo':
      return ui.SessionType.onlineVideo;
    case 'onlineAudio':
      return ui.SessionType.onlineAudio;
    case 'phone':
      return ui.SessionType.phone;
    case 'group':
      return ui.SessionType.group;
    default:
      return ui.SessionType.presential;
  }
}

String _mapTypeToString(ui.SessionType type) {
  switch (type) {
    case ui.SessionType.presential:
      return 'presential';
    case ui.SessionType.onlineVideo:
      return 'onlineVideo';
    case ui.SessionType.onlineAudio:
      return 'onlineAudio';
    case ui.SessionType.phone:
      return 'phone';
    case ui.SessionType.group:
      return 'group';
  }
}

ui.SessionModality _mapModalityFromString(String modality) {
  switch (modality) {
    case 'individual':
      return ui.SessionModality.individual;
    case 'couple':
      return ui.SessionModality.couple;
    case 'family':
      return ui.SessionModality.family;
    case 'group':
      return ui.SessionModality.group;
    default:
      return ui.SessionModality.individual;
  }
}

String _mapModalityToString(ui.SessionModality modality) {
  switch (modality) {
    case ui.SessionModality.individual:
      return 'individual';
    case ui.SessionModality.couple:
      return 'couple';
    case ui.SessionModality.family:
      return 'family';
    case ui.SessionModality.group:
      return 'group';
  }
}

ui.SessionStatus _mapStatusFromString(String status) {
  switch (status) {
    case 'scheduled':
      return ui.SessionStatus.scheduled;
    case 'confirmed':
      return ui.SessionStatus.confirmed;
    case 'inProgress':
      return ui.SessionStatus.inProgress;
    case 'completed':
      return ui.SessionStatus.completed;
    case 'draft':
      return ui.SessionStatus.draft;
    case 'cancelledByTherapist':
      return ui.SessionStatus.cancelledByTherapist;
    case 'cancelledByPatient':
      return ui.SessionStatus.cancelledByPatient;
    case 'noShow':
      return ui.SessionStatus.noShow;
    default:
      return ui.SessionStatus.scheduled;
  }
}

String _mapStatusToString(ui.SessionStatus status) {
  switch (status) {
    case ui.SessionStatus.scheduled:
      return 'scheduled';
    case ui.SessionStatus.confirmed:
      return 'confirmed';
    case ui.SessionStatus.inProgress:
      return 'inProgress';
    case ui.SessionStatus.completed:
      return 'completed';
    case ui.SessionStatus.draft:
      return 'draft';
    case ui.SessionStatus.cancelledByTherapist:
      return 'cancelledByTherapist';
    case ui.SessionStatus.cancelledByPatient:
      return 'cancelledByPatient';
    case ui.SessionStatus.noShow:
      return 'noShow';
  }
}

ui.PaymentStatus _mapPaymentStatusFromString(String status) {
  switch (status) {
    case 'pending':
      return ui.PaymentStatus.pending;
    case 'paid':
      return ui.PaymentStatus.paid;
    case 'exempt':
      return ui.PaymentStatus.exempt;
    default:
      return ui.PaymentStatus.pending;
  }
}

String _mapPaymentStatusToString(ui.PaymentStatus status) {
  switch (status) {
    case ui.PaymentStatus.pending:
      return 'pending';
    case ui.PaymentStatus.paid:
      return 'paid';
    case ui.PaymentStatus.exempt:
      return 'exempt';
  }
}

String _mapRiskLevelToString(ui.RiskLevel risk) {
  switch (risk) {
    case ui.RiskLevel.low:
      return 'low';
    case ui.RiskLevel.medium:
      return 'medium';
    case ui.RiskLevel.high:
      return 'high';
  }
}

ui.RiskLevel _mapRiskLevelFromString(String risk) {
  switch (risk) {
    case 'low':
      return ui.RiskLevel.low;
    case 'medium':
      return ui.RiskLevel.medium;
    case 'high':
      return ui.RiskLevel.high;
    default:
      return ui.RiskLevel.low;
  }
}
