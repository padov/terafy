import 'package:common/common.dart';
import 'package:server/features/schedule/schedule.repository.dart';
import 'package:server/features/session/session.repository.dart';
import 'package:server/features/patient/patient.repository.dart';

class HomeException implements Exception {
  HomeException(this.message, [this.statusCode = 500]);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class HomeController {
  HomeController(
    ScheduleRepository scheduleRepository,
    SessionRepository sessionRepository,
    PatientRepository patientRepository,
  ) : _scheduleRepository = scheduleRepository,
      _sessionRepository = sessionRepository,
      _patientRepository = patientRepository;

  final ScheduleRepository _scheduleRepository;
  final SessionRepository _sessionRepository;
  final PatientRepository _patientRepository;

  Future<HomeSummary> getSummary({
    required int therapistId,
    required int userId,
    required String userRole,
    int? accountId,
    DateTime? referenceDate,
  }) async {
    AppLogger.func();
    try {
      final now = referenceDate ?? DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);

      final todaysAppointments = await _scheduleRepository.listAppointments(
        therapistId: therapistId,
        start: dayStart,
        end: dayEnd,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      final monthlyAppointments = await _scheduleRepository.listAppointments(
        therapistId: therapistId,
        start: monthStart,
        end: monthEnd,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      final todayAgenda =
          todaysAppointments
              .where((appointment) => appointment.type == 'session' && appointment.status != 'completed')
              .map(
                (appointment) => HomeAgendaItem(
                  appointmentId: appointment.id,
                  startTime: appointment.startTime,
                  endTime: appointment.endTime,
                  type: appointment.type,
                  status: appointment.status,
                  title: appointment.title,
                  description: appointment.description,
                  patientId: appointment.patientId,
                  patientName: appointment.patientName,
                  sessionId: appointment.sessionId,
                ),
              )
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

      final todayPendingSessions = todaysAppointments
          .where((appointment) => (appointment.type == 'session') && (appointment.status != 'confirmed'))
          .length;
      final todayConfirmedSessions = todaysAppointments
          .where((appointment) => (appointment.type == 'session') && (appointment.status == 'confirmed'))
          .length;

      final monthlyCompleted = monthlyAppointments.where((apt) => apt.status == 'completed').length;
      final monthlySessions = monthlyAppointments.where((apt) => apt.type == 'session').length;
      final monthlyCompletionRate = (monthlySessions > 0 ? monthlyCompleted / monthlySessions : 0.0).toDouble();

      AppLogger.info('monthlySessions: $monthlySessions');
      AppLogger.info('monthlyCompleted: $monthlyCompleted');
      AppLogger.info('monthlyCompletionRate: $monthlyCompletionRate');

      // Buscar sessões pendentes (todas, sem filtro de data)
      List<Session> pendingSessionsList = [];
      try {
        AppLogger.info('Iniciando busca de sessões pendentes...');
        AppLogger.info('SessionRepository tipo: ${_sessionRepository.runtimeType}');

        pendingSessionsList = await _sessionRepository.listSessions(
          therapistId: therapistId,
          statuses: ['draft', 'scheduled', 'confirmed', 'in_progress'],
          startDate: null,
          endDate: null,
          userId: userId,
          userRole: userRole,
          accountId: accountId,
          bypassRLS: userRole == 'admin',
        );
        AppLogger.info('Total de sessões encontradas (já filtradas pelo DB): ${pendingSessionsList.length}');
      } catch (e, stackTrace) {
        AppLogger.error('Erro ao buscar sessões pendentes: $e');
        AppLogger.error('Stack trace: $stackTrace');
        pendingSessionsList = [];
      }

      // As sessões já vêm filtradas do banco
      final filteredSessions = pendingSessionsList;

      AppLogger.info('Total de sessões pendentes: ${filteredSessions.length}');

      // Buscar nomes dos pacientes
      final patientIds = filteredSessions.map((s) => s.patientId).toSet().toList();
      final patientsMap = <int, String>{};

      final accountContext = accountId ?? therapistId;
      for (final patientId in patientIds) {
        try {
          final patient = await _patientRepository.getPatientById(
            patientId,
            userId: userId,
            userRole: userRole,
            accountId: accountContext,
            bypassRLS: userRole == 'admin',
          );
          if (patient != null) {
            patientsMap[patientId] = patient.fullName;
          }
        } catch (e) {
          AppLogger.warning('Erro ao buscar paciente $patientId: $e');
        }
      }

      final pendingSessions =
          filteredSessions
              .where((session) => session.id != null)
              .map(
                (session) => PendingSession(
                  id: session.id!,
                  sessionNumber: session.sessionNumber,
                  patientId: session.patientId,
                  patientName: patientsMap[session.patientId] ?? 'Paciente',
                  scheduledStartTime: session.scheduledStartTime,
                  status: session.status.toString().split('.').last,
                ),
              )
              .toList()
            ..sort((a, b) => b.scheduledStartTime.compareTo(a.scheduledStartTime));

      return HomeSummary(
        referenceDate: dayStart,
        therapistId: therapistId,
        todayPendingSessions: todayPendingSessions,
        todayConfirmedSessions: todayConfirmedSessions,
        monthlyCompletionRate: monthlyCompletionRate,
        monthlySessions: monthlySessions,
        listOfTodaySessions: todayAgenda,
        pendingSessions: pendingSessions,
      );
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is HomeException) rethrow;
      throw HomeException('Erro ao carregar resumo da home: ${e.toString()}', 500);
    }
  }
}
