import 'package:common/common.dart';
import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_channel.dart';
import 'package:server/features/messaging/services/reminder_scheduler.dart';
import 'package:server/features/messaging/usecases/get_message_history_usecase.dart';
import 'package:server/features/messaging/usecases/send_appointment_reminder_usecase.dart';
import 'package:server/features/messaging/usecases/send_message_usecase.dart';

class MessagingException implements Exception {
  final String message;
  final int statusCode;

  MessagingException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class MessagingController {
  final SendMessageUseCase _sendMessageUseCase;
  final SendAppointmentReminderUseCase _sendAppointmentReminderUseCase;
  final GetMessageHistoryUseCase _getMessageHistoryUseCase;
  final ReminderScheduler _reminderScheduler;

  MessagingController(
    this._sendMessageUseCase,
    this._sendAppointmentReminderUseCase,
    this._getMessageHistoryUseCase,
    this._reminderScheduler,
  );

  /// Envia uma mensagem genérica
  Future<Message> sendMessage(Message message) async {
    AppLogger.func();

    try {
      return await _sendMessageUseCase.execute(message);
    } catch (e) {
      throw MessagingException('Erro ao enviar mensagem: ${e.toString()}', 500);
    }
  }

  /// Envia lembrete de agendamento
  Future<Message> sendAppointmentReminder({
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

    try {
      return await _sendAppointmentReminderUseCase.execute(
        appointmentId: appointmentId,
        patientId: patientId,
        patientName: patientName,
        patientEmail: patientEmail,
        patientPhone: patientPhone,
        therapistId: therapistId,
        therapistName: therapistName,
        appointmentDateTime: appointmentDateTime,
        appointmentDuration: appointmentDuration,
        channel: channel,
        location: location,
        onlineLink: onlineLink,
      );
    } catch (e) {
      throw MessagingException(
        'Erro ao enviar lembrete de agendamento: ${e.toString()}',
        500,
      );
    }
  }

  /// Busca histórico de mensagens
  Future<List<Message>> getMessageHistory({
    required RecipientType recipientType,
    required int recipientId,
    MessageStatus? status,
    MessageChannel? channel,
    int? limit,
    int? offset,
  }) async {
    AppLogger.func();

    try {
      return await _getMessageHistoryUseCase.execute(
        recipientType: recipientType,
        recipientId: recipientId,
        status: status,
        channel: channel,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw MessagingException(
        'Erro ao buscar histórico de mensagens: ${e.toString()}',
        500,
      );
    }
  }

  /// Busca mensagens relacionadas a uma entidade
  Future<List<Message>> getMessagesByRelatedEntity({
    required String entityType,
    required int entityId,
  }) async {
    AppLogger.func();

    try {
      return await _getMessageHistoryUseCase.executeByRelatedEntity(
        entityType: entityType,
        entityId: entityId,
      );
    } catch (e) {
      throw MessagingException(
        'Erro ao buscar mensagens relacionadas: ${e.toString()}',
        500,
      );
    }
  }

  /// Processa lembretes agendados
  Future<int> processReminders() async {
    AppLogger.func();

    try {
      return await _reminderScheduler.processScheduledMessages();
    } catch (e) {
      throw MessagingException(
        'Erro ao processar lembretes: ${e.toString()}',
        500,
      );
    }
  }
}

