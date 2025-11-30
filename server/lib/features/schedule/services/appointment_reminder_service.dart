import 'package:common/common.dart';
import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_channel.dart';
import 'package:server/features/messaging/domain/message_repository.dart';
import 'package:server/features/patient/patient.repository.dart';
import 'package:server/features/therapist/therapist.repository.dart';

/// Serviço para criar mensagens de lembrete ao criar agendamento
class AppointmentReminderService {
  final MessageRepository _messageRepository;
  final PatientRepository _patientRepository;
  final TherapistRepository _therapistRepository;

  AppointmentReminderService(
    this._messageRepository,
    this._patientRepository,
    this._therapistRepository,
  );

  /// Cria mensagens de lembrete para um agendamento
  Future<void> createReminderMessages({
    required Appointment appointment,
    required int userId,
    String? userRole,
  }) async {
    AppLogger.func();

    // Verifica se há lembretes configurados
    if (appointment.reminders == null || appointment.reminders!.isEmpty) {
      return;
    }

    // Verifica se tem paciente
    if (appointment.patientId == null) {
      return;
    }

    try {
      // Busca dados do paciente
      final patient = await _patientRepository.getPatientById(
        appointment.patientId!,
        userId: userId,
        userRole: userRole,
        accountId: appointment.therapistId,
        bypassRLS: userRole == 'admin',
      );

      if (patient == null) {
        AppLogger.warning('Paciente ${appointment.patientId} não encontrado');
        return;
      }

      // Busca dados do terapeuta
      final therapist = await _therapistRepository.getTherapistById(
        appointment.therapistId,
        userId: userId,
        userRole: userRole,
        bypassRLS: userRole == 'admin',
      );

      if (therapist == null) {
        AppLogger.warning('Terapeuta ${appointment.therapistId} não encontrado');
        return;
      }

      // Processa cada lembrete configurado
      for (final reminderData in appointment.reminders!) {
        Map<String, dynamic> reminderMap;
        if (reminderData is Map) {
          reminderMap = reminderData.map((key, value) => MapEntry(key.toString(), value));
        } else {
          continue;
        }

        final enabled = reminderMap['enabled'] as bool? ?? false;
        if (!enabled) continue;

        final channelStr = reminderMap['channel'] as String? ?? 'email';
        MessageChannel channel;
        try {
          channel = MessageChannel.values.firstWhere(
            (e) => e.name == channelStr,
          );
        } catch (_) {
          channel = MessageChannel.email;
        }

        final antecedenceMinutes = reminderMap['antecedence'] as int? ?? 1440; // 24h padrão
        final scheduledAt = appointment.startTime.subtract(Duration(minutes: antecedenceMinutes));

        // Só cria se a data agendada ainda não passou
        if (scheduledAt.isBefore(DateTime.now())) {
          continue;
        }

        // Prepara metadata com informações do destinatário
        final metadata = <String, dynamic>{
          'recipient_email': patient.email,
          'recipient_phone': patient.phones?.isNotEmpty == true ? patient.phones!.first : null,
          'appointment_id': appointment.id,
        };

        // Cria mensagem agendada
        final message = Message(
          messageType: MessageType.appointmentReminder,
          channel: channel,
          recipientType: RecipientType.patient,
          recipientId: patient.id!,
          senderId: therapist.id,
          subject: 'Lembrete de Agendamento',
          content: _buildReminderContent(patient, therapist, appointment),
          status: MessageStatus.scheduled,
          priority: MessagePriority.normal,
          scheduledAt: scheduledAt,
          relatedEntityType: 'appointment',
          relatedEntityId: appointment.id,
          metadata: metadata,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _messageRepository.create(message);
        AppLogger.info('Mensagem de lembrete criada para agendamento ${appointment.id}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      // Não falha a criação do agendamento se houver erro ao criar lembretes
    }
  }

  /// Constrói conteúdo do lembrete
  String _buildReminderContent(Patient patient, Therapist therapist, Appointment appointment) {
    final dateStr = _formatDate(appointment.startTime);
    final timeStr = _formatTime(appointment.startTime);

    return '''
Olá ${patient.fullName}!

Este é um lembrete de que você tem uma consulta agendada:

Data: $dateStr
Horário: $timeStr
Terapeuta: ${therapist.name}
${appointment.location != null ? 'Local: ${appointment.location}' : ''}
${appointment.onlineLink != null ? 'Link online: ${appointment.onlineLink}' : ''}

Por favor, confirme sua presença ou entre em contato caso precise reagendar.''';
  }

  /// Formata data em português
  String _formatDate(DateTime date) {
    final days = ['Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'];
    final months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro'
    ];

    final dayName = days[date.weekday % 7];
    return '$dayName, ${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  /// Formata horário
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

