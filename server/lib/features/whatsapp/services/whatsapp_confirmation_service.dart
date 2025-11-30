import 'package:common/common.dart';
import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_channel.dart';
import 'package:server/features/messaging/domain/message_repository.dart';
import 'package:server/features/messaging/providers/whatsapp_message_provider.dart';
import 'package:server/features/patient/patient.repository.dart';
import 'package:server/features/schedule/schedule.repository.dart';
import 'package:server/features/therapist/therapist.repository.dart';

/// Serviço para envio de confirmações automáticas via WhatsApp
class WhatsAppConfirmationService {
  final MessageRepository _messageRepository;
  final WhatsAppMessageProvider _whatsappProvider;
  final ScheduleRepository _scheduleRepository;
  final PatientRepository _patientRepository;
  final TherapistRepository _therapistRepository;

  WhatsAppConfirmationService(
    this._messageRepository,
    this._whatsappProvider,
    this._scheduleRepository,
    this._patientRepository,
    this._therapistRepository,
  );

  /// Envia confirmação de agendamento com X dias de antecedência
  Future<void> sendAppointmentConfirmations({
    required int therapistId,
    required int daysBefore,
  }) async {
    AppLogger.func();

    try {
      // Calcula data alvo (X dias a partir de hoje)
      final targetDate = DateTime.now().add(Duration(days: daysBefore));
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0);
      final endOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59);

      // Busca agendamentos do terapeuta para a data alvo
      // Usa userId=0 pois bypassRLS=true ignora o RLS
      final appointments = await _scheduleRepository.listAppointments(
        therapistId: therapistId,
        start: startOfDay,
        end: endOfDay,
        userId: 0,
        userRole: null,
        accountId: therapistId,
        bypassRLS: true,
      );

      // Filtra apenas agendamentos que precisam de confirmação
      final appointmentsToConfirm = appointments.where((apt) {
        // Apenas agendamentos reservados ou confirmados
        if (apt.status != 'reserved' && apt.status != 'confirmed') {
          return false;
        }

        // Apenas se tiver paciente
        if (apt.patientId == null) {
          return false;
        }

        // Verifica se já foi enviada confirmação
        // TODO: Verificar se já existe mensagem de confirmação para este agendamento

        return true;
      }).toList();

      AppLogger.info('Encontrados ${appointmentsToConfirm.length} agendamentos para confirmar');

      // Envia confirmação para cada agendamento
      for (final appointment in appointmentsToConfirm) {
        try {
          await _sendConfirmationForAppointment(appointment);
        } catch (e, stackTrace) {
          AppLogger.error(e, stackTrace);
          AppLogger.error('Erro ao enviar confirmação para agendamento ${appointment.id}');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      rethrow;
    }
  }

  /// Envia confirmação para um agendamento específico
  Future<void> _sendConfirmationForAppointment(Appointment appointment) async {
    if (appointment.patientId == null) {
      return;
    }

    // Busca dados do paciente
    final patient = await _patientRepository.getPatientById(
      appointment.patientId!,
      userId: null,
      userRole: null,
      accountId: appointment.therapistId,
      bypassRLS: true,
    );

    if (patient == null) {
      AppLogger.warning('Paciente ${appointment.patientId} não encontrado');
      return;
    }

    // Verifica se paciente tem telefone
    if (patient.phones == null || patient.phones!.isEmpty) {
      AppLogger.warning('Paciente ${patient.id} não tem telefone cadastrado');
      return;
    }

    // Busca dados do terapeuta
    final therapist = await _therapistRepository.getTherapistById(
      appointment.therapistId,
      userId: null,
      userRole: null,
      bypassRLS: true,
    );

    if (therapist == null) {
      AppLogger.warning('Terapeuta ${appointment.therapistId} não encontrado');
      return;
    }

    // Formata data e hora
    final dateStr = _formatDate(appointment.startTime);
    final timeStr = _formatTime(appointment.startTime);

    // Monta mensagem
    final message = '''
Olá ${patient.fullName}! 👋

Este é um lembrete de que você tem uma consulta agendada:

📅 Data: $dateStr
⏰ Horário: $timeStr
👨‍⚕️ Terapeuta: ${therapist.name}
${appointment.location != null ? '📍 Local: ${appointment.location}' : ''}
${appointment.onlineLink != null ? '🔗 Link online: ${appointment.onlineLink}' : ''}

Por favor, confirme sua presença ou entre em contato caso precise reagendar.''';

    // Envia mensagem com botões
    final phoneNumber = patient.phones!.first;
    final result = await _whatsappProvider.sendButtons(
      phoneNumber,
      message,
      [
        {'id': 'confirm_${appointment.id}', 'text': '✅ Confirmar'},
        {'id': 'cancel_${appointment.id}', 'text': '❌ Cancelar'},
        {'id': 'reschedule_${appointment.id}', 'text': '🔄 Reagendar'},
      ],
    );

    if (result.success) {
      // Cria registro da mensagem
      final messageEntity = Message(
        messageType: MessageType.appointmentReminder,
        channel: MessageChannel.whatsapp,
        recipientType: RecipientType.patient,
        recipientId: patient.id!,
        senderId: therapist.id,
        subject: 'Confirmação de Agendamento',
        content: message,
        status: MessageStatus.sent,
        priority: MessagePriority.normal,
        relatedEntityType: 'appointment',
        relatedEntityId: appointment.id,
        metadata: {
          'recipient_phone': phoneNumber,
          'appointment_id': appointment.id,
          'confirmation_type': 'reminder',
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _messageRepository.create(messageEntity);
      AppLogger.info('Confirmação enviada para paciente ${patient.id}');
    } else {
      AppLogger.error('Erro ao enviar confirmação: ${result.errorMessage}');
    }
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

