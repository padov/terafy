import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_repository.dart';
import 'package:server/features/messaging/domain/message_channel.dart';
import 'package:server/features/messaging/services/message_template_service.dart';
import 'package:server/features/messaging/usecases/send_message_usecase.dart';
import 'package:common/common.dart';

/// UseCase para envio de lembrete de agendamento
class SendAppointmentReminderUseCase {
  final MessageRepository _repository;
  final MessageTemplateService _templateService;
  final SendMessageUseCase _sendMessageUseCase;

  SendAppointmentReminderUseCase(
    this._repository,
    this._templateService,
    this._sendMessageUseCase,
  );

  /// Envia lembrete de agendamento
  Future<Message> execute({
    required int appointmentId,
    required int patientId,
    required String patientName,
    required String? patientEmail,
    required String? patientPhone,
    required int therapistId,
    required String therapistName,
    required DateTime appointmentDateTime,
    required Duration appointmentDuration,
    required MessageChannel channel,
    String? location,
    String? onlineLink,
  }) async {
    AppLogger.func();

    // Valida se o canal tem os dados necessários
    if (channel == MessageChannel.email && (patientEmail == null || patientEmail.isEmpty)) {
      throw Exception('Email do paciente não disponível para envio por email');
    }

    if ((channel == MessageChannel.sms || channel == MessageChannel.whatsapp) &&
        (patientPhone == null || patientPhone.isEmpty)) {
      throw Exception('Telefone do paciente não disponível para envio por SMS/WhatsApp');
    }

    // Busca template para lembrete de agendamento
    final template = await _repository.findTemplateByTypeAndChannel(
      type: MessageType.appointmentReminder,
      channel: channel,
    );

    if (template == null) {
      throw Exception('Template não encontrado para lembrete de agendamento no canal ${channel.name}');
    }

    // Prepara variáveis do template
    final variables = <String, dynamic>{
      'patientName': patientName,
      'therapistName': therapistName,
      'appointmentDate': appointmentDateTime,
      'appointmentTime': appointmentDateTime,
      'appointmentDuration': appointmentDuration,
      if (location != null) 'location': location,
      if (onlineLink != null) 'onlineLink': onlineLink,
    };

    // Valida variáveis
    final missingVars = _templateService.validateVariables(template, variables);
    if (missingVars.isNotEmpty) {
      throw Exception('Variáveis faltando no template: ${missingVars.join(', ')}');
    }

    // Processa template
    final processed = _templateService.processTemplate(template, variables);

    // Prepara metadata com informações do destinatário
    final metadata = <String, dynamic>{
      'recipient_email': patientEmail,
      'recipient_phone': patientPhone,
      'appointment_id': appointmentId,
    };

    // Cria mensagem
    final message = Message(
      messageType: MessageType.appointmentReminder,
      channel: channel,
      recipientType: RecipientType.patient,
      recipientId: patientId,
      senderId: therapistId,
      subject: processed.subject,
      content: processed.content,
      templateId: template.id,
      priority: MessagePriority.normal,
      relatedEntityType: 'appointment',
      relatedEntityId: appointmentId,
      metadata: metadata,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Envia mensagem
    return await _sendMessageUseCase.execute(message);
  }
}

