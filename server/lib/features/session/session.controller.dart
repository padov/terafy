import 'package:common/common.dart';
import 'package:server/features/session/session.repository.dart';
import 'package:server/features/schedule/schedule.repository.dart';
import 'package:server/features/financial/financial.repository.dart';

class SessionException implements Exception {
  SessionException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class SessionController {
  SessionController(this._repository, this._scheduleRepository, [this._financialRepository]);

  final SessionRepository _repository;
  final ScheduleRepository _scheduleRepository;
  final FinancialRepository? _financialRepository;

  Future<Session> createSession({
    required Session session,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      // Validações básicas
      if (session.patientId <= 0) {
        throw SessionException('ID do paciente inválido', 400);
      }

      if (session.therapistId <= 0) {
        throw SessionException('ID do terapeuta inválido', 400);
      }

      if (session.durationMinutes <= 0) {
        throw SessionException('Duração deve ser maior que zero', 400);
      }

      if (session.scheduledEndTime != null && session.scheduledStartTime.isAfter(session.scheduledEndTime!)) {
        throw SessionException('Data de término deve ser posterior à data de início', 400);
      }

      // Se session_number não foi fornecido, calcular automaticamente
      Session sessionToCreate = session;
      if (session.sessionNumber <= 0) {
        final nextNumber = await _repository.getNextSessionNumber(
          patientId: session.patientId,
          userId: userId,
          userRole: userRole,
          accountId: accountId,
        );
        sessionToCreate = session.copyWith(sessionNumber: nextNumber);
      }

      final created = await _repository.createSession(
        session: sessionToCreate,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      // Trigger: Se a sessão tem um agendamento vinculado, marcar como completed
      if (created.appointmentId != null) {
        try {
          final appointment = await _scheduleRepository.getAppointmentById(
            appointmentId: created.appointmentId!,
            userId: userId,
            userRole: userRole,
            accountId: accountId,
            bypassRLS: userRole == 'admin',
          );

          if (appointment != null && appointment.status != 'completed') {
            final updatedAppointment = appointment.copyWith(status: 'completed');
            await _scheduleRepository.updateAppointment(
              appointmentId: appointment.id,
              appointment: updatedAppointment,
              userId: userId,
              userRole: userRole,
              accountId: accountId,
              bypassRLS: userRole == 'admin',
            );
            AppLogger.info(
              'Agendamento ${appointment.id} marcado como completed automaticamente via criação de sessão.',
            );
          }
        } catch (e) {
          AppLogger.warning('Falha ao atualizar status do agendamento vinculado: $e');
        }
      }

      return created;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is SessionException) rethrow;
      throw SessionException('Erro ao criar sessão: ${e.toString()}', 500);
    }
  }

  Future<Session> getSession({required int sessionId, required int userId, String? userRole, int? accountId}) async {
    AppLogger.func();
    try {
      final session = await _repository.getSessionById(
        sessionId: sessionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (session == null) {
        throw SessionException('Sessão não encontrada', 404);
      }

      return session;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is SessionException) rethrow;
      throw SessionException('Erro ao buscar sessão: ${e.toString()}', 500);
    }
  }

  Future<List<Session>> listSessions({
    int? patientId,
    int? therapistId,
    int? appointmentId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      final sessions = await _repository.listSessions(
        patientId: patientId,
        therapistId: therapistId,
        appointmentId: appointmentId,
        statuses: status != null ? [status] : null,
        startDate: startDate,
        endDate: endDate,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return sessions;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is SessionException) rethrow;
      throw SessionException('Erro ao listar sessões: ${e.toString()}', 500);
    }
  }

  Future<Session> updateSession({
    required int sessionId,
    required Session session,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      // Validações básicas
      if (session.durationMinutes <= 0) {
        throw SessionException('Duração deve ser maior que zero', 400);
      }

      if (session.scheduledEndTime != null && session.scheduledStartTime.isAfter(session.scheduledEndTime!)) {
        throw SessionException('Data de término deve ser posterior à data de início', 400);
      }

      // Buscar sessão atual para verificar mudança de status
      final currentSession = await _repository.getSessionById(
        sessionId: sessionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (currentSession == null) {
        throw SessionException('Sessão não encontrada', 404);
      }

      final wasCompleted = currentSession.status == 'completed';
      final isCompleted = session.status == 'completed';

      final updated = await _repository.updateSession(
        sessionId: sessionId,
        session: session,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (updated == null) {
        throw SessionException('Sessão não encontrada', 404);
      }

      // Trigger: Se a sessão tem um agendamento vinculado, marcar como completed
      // Isso garante que se o appointmentId for adicionado ou se o status mudar, o agendamento reflete
      if (updated.appointmentId != null && updated.status == 'completed') {
        try {
          final appointment = await _scheduleRepository.getAppointmentById(
            appointmentId: updated.appointmentId!,
            userId: userId,
            userRole: userRole,
            accountId: accountId,
            bypassRLS: userRole == 'admin',
          );

          if (appointment != null && appointment.status != 'completed' && appointment.id != null) {
            final updatedAppointment = appointment.copyWith(status: 'completed');
            await _scheduleRepository.updateAppointment(
              appointmentId: appointment.id!,
              appointment: updatedAppointment,
              userId: userId,
              userRole: userRole,
              accountId: accountId,
              bypassRLS: userRole == 'admin',
            );
            AppLogger.info(
              'Agendamento ${appointment.id} marcado como completed automaticamente via atualização de sessão.',
            );
          }
        } catch (e) {
          AppLogger.warning('Falha ao atualizar status do agendamento vinculado: $e');
        }
      }

      // Se sessão foi marcada como completed e tem charged_amount, criar transação automaticamente
      if (!wasCompleted && isCompleted && updated.chargedAmount != null && updated.chargedAmount! > 0) {
        // Verificar se já existe transação vinculada a esta sessão
        if (_financialRepository != null) {
          try {
            final financialRepo = _financialRepository;
            final existingTransactions = await financialRepo.listTransactions(
              userId: userId,
              userRole: userRole,
              accountId: accountId,
              sessionId: sessionId,
              bypassRLS: userRole == 'admin',
            );

            // Se não existe transação vinculada, criar uma nova
            if (existingTransactions.isEmpty) {
              final chargedAmount = updated.chargedAmount!;
              final transaction = FinancialTransaction(
                therapistId: updated.therapistId,
                patientId: updated.patientId,
                sessionId: updated.id,
                transactionDate: updated.scheduledStartTime.toLocal(),
                type: 'recebimento',
                amount: chargedAmount,
                paymentMethod: 'pix', // Método padrão, pode ser alterado depois
                status: 'pendente',
                category: 'sessao',
                createdAt: DateTime.now().toUtc(),
                updatedAt: DateTime.now().toUtc(),
              );

              await financialRepo.createTransaction(
                transaction: transaction,
                userId: userId,
                userRole: userRole,
                accountId: accountId,
                bypassRLS: userRole == 'admin',
              );

              AppLogger.info('Transação financeira criada automaticamente para sessão ${updated.id}');
            }
          } catch (e, stack) {
            // Log erro mas não falha a atualização da sessão
            AppLogger.error('Erro ao criar transação financeira automaticamente: $e', stack);
          }
        }
      }

      return updated;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is SessionException) rethrow;
      throw SessionException('Erro ao atualizar sessão: ${e.toString()}', 500);
    }
  }

  Future<void> deleteSession({required int sessionId, required int userId, String? userRole, int? accountId}) async {
    AppLogger.func();
    try {
      final deleted = await _repository.deleteSession(
        sessionId: sessionId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (!deleted) {
        throw SessionException('Sessão não encontrada', 404);
      }
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is SessionException) rethrow;
      throw SessionException('Erro ao remover sessão: ${e.toString()}', 500);
    }
  }

  Future<int> getNextSessionNumber({
    required int patientId,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      final nextNumber = await _repository.getNextSessionNumber(
        patientId: patientId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return nextNumber;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is SessionException) rethrow;
      throw SessionException('Erro ao calcular próximo número de sessão: ${e.toString()}', 500);
    }
  }
}
