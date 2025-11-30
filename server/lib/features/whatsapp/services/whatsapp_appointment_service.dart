import 'package:common/common.dart';
import 'package:server/features/messaging/usecases/send_appointment_reminder_usecase.dart';
import 'package:server/features/schedule/schedule.controller.dart';
import 'package:server/features/schedule/schedule.repository.dart';

/// Serviço para criar agendamentos via WhatsApp
class WhatsAppAppointmentService {
  final ScheduleController _scheduleController;
  final ScheduleRepository _scheduleRepository;
  final SendAppointmentReminderUseCase _sendReminderUseCase;

  WhatsAppAppointmentService(
    this._scheduleController,
    this._scheduleRepository,
    this._sendReminderUseCase,
  );

  /// Busca horários disponíveis para um terapeuta em uma data específica
  Future<List<Map<String, dynamic>>> findAvailableSlots({
    required int therapistId,
    required DateTime date,
    required int userId,
    String? userRole,
  }) async {
    AppLogger.func();

    try {
      // Busca configurações do terapeuta
      final settings = await _scheduleRepository.getTherapistSettings(
        therapistId: therapistId,
        userId: userId,
        userRole: userRole,
      );

      if (settings == null) {
        return [];
      }

      // Busca agendamentos do dia
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59);

      final existingAppointments = await _scheduleRepository.listAppointments(
        therapistId: therapistId,
        start: startOfDay,
        end: endOfDay,
        userId: userId,
        userRole: userRole,
        accountId: therapistId,
      );

      // Gera slots disponíveis baseado nas configurações
      final duration = Duration(minutes: settings.sessionDurationMinutes);
      final breakDuration = Duration(minutes: settings.breakMinutes);
      final slots = <Map<String, dynamic>>[];

      // Horário padrão: 8h às 18h
      var currentTime = DateTime(date.year, date.month, date.day, 8, 0);
      final endTime = DateTime(date.year, date.month, date.day, 18, 0);

      while (currentTime.add(duration).isBefore(endTime) || currentTime.add(duration).isAtSameMomentAs(endTime)) {
        final slotEnd = currentTime.add(duration);

        // Verifica se o slot está livre
        final isAvailable = !existingAppointments.any((apt) {
          final aptStart = apt.startTime;
          final aptEnd = apt.endTime;
          return (currentTime.isBefore(aptEnd) && slotEnd.isAfter(aptStart));
        });

        if (isAvailable) {
          slots.add({
            'time': currentTime,
            'formatted': _formatTime(currentTime),
            'id': 'slot_${currentTime.toIso8601String()}',
          });
        }

        currentTime = slotEnd.add(breakDuration);
      }

      return slots;
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return [];
    }
  }

  /// Cria um agendamento via WhatsApp
  Future<Appointment> createAppointmentFromWhatsApp({
    required int therapistId,
    required int patientId,
    required DateTime dateTime,
    required Duration duration,
    required int userId,
    String? userRole,
    String? location,
    String? onlineLink,
  }) async {
    AppLogger.func();

    try {
      // Busca dados do paciente para enviar confirmação
      // TODO: Buscar dados do paciente

      // Cria o agendamento
      final appointment = Appointment(
        therapistId: therapistId,
        patientId: patientId,
        type: 'session',
        status: 'reserved',
        startTime: dateTime,
        endTime: dateTime.add(duration),
        location: location,
        onlineLink: onlineLink,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _scheduleController.createAppointment(
        appointment: appointment,
        userId: userId,
        userRole: userRole,
        accountId: therapistId,
      );

      // Envia confirmação via WhatsApp
      // TODO: Implementar envio de confirmação

      return created;
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      rethrow;
    }
  }

  /// Formata horário
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

