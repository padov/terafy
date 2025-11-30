import 'package:common/common.dart';
import 'package:server/features/schedule/schedule.repository.dart';
import 'package:server/features/schedule/services/appointment_reminder_service.dart';

class ScheduleException implements Exception {
  ScheduleException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ScheduleController {
  ScheduleController(
    this._repository, {
    AppointmentReminderService? reminderService,
  }) : _reminderService = reminderService;

  final ScheduleRepository _repository;
  final AppointmentReminderService? _reminderService;

  /// Trata erros e retorna uma mensagem amigável para o usuário
  ScheduleException _handleError(dynamic error, String defaultMessage) {
    // Se já for uma ScheduleException, retorna ela mesma
    if (error is ScheduleException) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    // Detecta erro de conflito de horário da trigger
    // A trigger lança: "Conflito de horário: já existe um agendamento..."
    if (errorString.contains('conflito de horário') ||
        errorString.contains('já existe um agendamento') ||
        errorString.contains('appointment overlap') ||
        (errorString.contains('horário') && errorString.contains('ocupado'))) {
      return ScheduleException(
        'Este horário já está ocupado. Por favor, escolha outro horário.',
        409, // Conflict
      );
    }

    // Erro genérico
    return ScheduleException(defaultMessage, 500);
  }

  Future<TherapistScheduleSettings> getOrCreateSettings({
    required int therapistId,
    required int userId,
    String? userRole,
  }) async {
    try {
      final existing = await _repository.getTherapistSettings(
        therapistId: therapistId,
        userId: userId,
        userRole: userRole,
        bypassRLS: userRole == 'admin',
      );

      if (existing != null) {
        return existing;
      }

      final defaultSettings = TherapistScheduleSettings(
        therapistId: therapistId,
        workingHours: const {},
        sessionDurationMinutes: 50,
        breakMinutes: 10,
        locations: const [],
        daysOff: const [],
        holidays: const [],
        customBlocks: const [],
        reminderEnabled: true,
        reminderDefaultOffset: '24h',
        reminderDefaultChannel: 'email',
        cancellationPolicy: const {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await _repository.upsertTherapistSettings(
        settings: defaultSettings,
        userId: userId,
        userRole: userRole,
        bypassRLS: userRole == 'admin',
      );
    } catch (e) {
      throw ScheduleException('Erro ao carregar configurações de agenda: ${e.toString()}', 500);
    }
  }

  Future<TherapistScheduleSettings> updateSettings({
    required TherapistScheduleSettings settings,
    required int userId,
    String? userRole,
  }) async {
    try {
      return await _repository.upsertTherapistSettings(
        settings: settings,
        userId: userId,
        userRole: userRole,
        bypassRLS: userRole == 'admin',
      );
    } catch (e) {
      throw ScheduleException('Erro ao atualizar configurações de agenda: ${e.toString()}', 500);
    }
  }

  Future<List<Appointment>> listAppointments({
    required int therapistId,
    required DateTime start,
    required DateTime end,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    try {
      return await _repository.listAppointments(
        therapistId: therapistId,
        start: start,
        end: end,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );
    } catch (e) {
      throw ScheduleException('Erro ao listar agendamentos: ${e.toString()}', 500);
    }
  }

  Future<Appointment> createAppointment({
    required Appointment appointment,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      final created = await _repository.createAppointment(
        appointment: appointment,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      // Cria mensagens de lembrete se configurado
      if (_reminderService != null && appointment.reminders != null && appointment.reminders!.isNotEmpty) {
        try {
          await _reminderService!.createReminderMessages(
            appointment: created,
            userId: userId,
            userRole: userRole,
          );
        } catch (e) {
          // Loga erro mas não falha a criação do agendamento
          AppLogger.error(e, StackTrace.current);
          AppLogger.warning('Erro ao criar lembretes, mas agendamento foi criado com sucesso');
        }
      }

      return created;
    } catch (e) {
      throw _handleError(e, 'Erro ao criar agendamento: ${e.toString()}');
    }
  }

  Future<Appointment> updateAppointment({
    required int appointmentId,
    required Appointment appointment,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      final updated = await _repository.updateAppointment(
        appointmentId: appointmentId,
        appointment: appointment,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (updated == null) {
        throw ScheduleException('Agendamento não encontrado', 404);
      }

      return updated;
    } catch (e) {
      AppLogger.error(e, StackTrace.current);
      throw _handleError(e, 'Erro ao atualizar agendamento: ${e.toString()}');
    }
  }

  Future<Appointment> getAppointment({
    required int appointmentId,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      final appointment = await _repository.getAppointmentById(
        appointmentId: appointmentId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (appointment == null) {
        throw ScheduleException('Agendamento não encontrado', 404);
      }

      return appointment;
    } catch (e) {
      if (e is ScheduleException) rethrow;
      throw ScheduleException('Erro ao buscar agendamento: ${e.toString()}', 500);
    }
  }

  Future<void> deleteAppointment({
    required int appointmentId,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    try {
      final deleted = await _repository.deleteAppointment(
        appointmentId: appointmentId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (!deleted) {
        throw ScheduleException('Agendamento não encontrado', 404);
      }
    } catch (e) {
      if (e is ScheduleException) rethrow;
      throw ScheduleException('Erro ao remover agendamento: ${e.toString()}', 500);
    }
  }
}
