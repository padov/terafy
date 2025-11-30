/// Canal de envio de mensagem
enum MessageChannel {
  email,
  sms,
  whatsapp,
  push,
}

/// Status da mensagem
enum MessageStatus {
  pending, // Aguardando envio
  scheduled, // Agendada
  sent, // Enviada
  delivered, // Entregue
  failed, // Falhou
  cancelled, // Cancelada
}

/// Tipo de mensagem
enum MessageType {
  appointmentReminder, // Lembrete de agendamento
  appointmentConfirmation, // Confirmação de agendamento
  appointmentCancellation, // Cancelamento de agendamento
  sessionReminder, // Lembrete de sessão
  general, // Mensagem geral
  notification, // Notificação do sistema
}

/// Prioridade da mensagem
enum MessagePriority {
  low,
  normal,
  high,
  urgent,
}

/// Tipo de destinatário
enum RecipientType {
  therapist,
  patient,
}

