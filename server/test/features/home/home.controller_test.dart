import 'package:common/common.dart';
import 'package:mocktail/mocktail.dart';
import 'package:server/features/home/home.controller.dart';
import 'package:server/features/schedule/schedule.repository.dart';
import 'package:server/features/session/session.repository.dart';
import 'package:server/features/patient/patient.repository.dart';
import 'package:test/test.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockPatientRepository extends Mock implements PatientRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Appointment(
        therapistId: 1,
        type: 'session',
        status: 'agendado',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    registerFallbackValue(
      Session(
        patientId: 1,
        therapistId: 1,
        scheduledStartTime: DateTime.now(),
        durationMinutes: 60,
        sessionNumber: 1,
        type: 'individual',
        modality: 'presencial',
        status: 'agendada',
        paymentStatus: 'pendente',
      ),
    );
  });

  late _MockScheduleRepository scheduleRepository;
  late _MockSessionRepository sessionRepository;
  late _MockPatientRepository patientRepository;
  late HomeController controller;

  final sampleAppointment = Appointment(
    id: 1,
    therapistId: 1,
    patientId: 1,
    patientName: 'Paciente Teste',
    type: 'session',
    status: 'agendado',
    startTime: DateTime(2024, 1, 15, 10, 0),
    endTime: DateTime(2024, 1, 15, 11, 0),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleSession = Session(
    id: 1,
    patientId: 1,
    therapistId: 1,
    scheduledStartTime: DateTime.now(),
    durationMinutes: 60,
    sessionNumber: 1,
    type: 'individual',
    modality: 'presencial',
    status: 'agendada',
    paymentStatus: 'pendente',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    scheduleRepository = _MockScheduleRepository();
    sessionRepository = _MockSessionRepository();
    patientRepository = _MockPatientRepository();
    controller = HomeController(scheduleRepository, sessionRepository, patientRepository);
  });

  group('HomeController - getSummary', () {
    test('deve retornar resumo completo quando therapist tem dados', () async {
      when(
        () => scheduleRepository.listAppointments(
          therapistId: 1,
          start: any(named: 'start'),
          end: any(named: 'end'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => [sampleAppointment]);

      when(
        () => sessionRepository.listSessions(
          therapistId: 1,
          statuses: any(named: 'statuses'),
          startDate: null,
          endDate: null,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => [sampleSession]);

      when(
        () => patientRepository.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 1, bypassRLS: false),
      ).thenAnswer(
        (_) async => Patient(
          id: 1,
          fullName: 'Paciente Teste',
          therapistId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final result = await controller.getSummary(therapistId: 1, userId: 1, userRole: 'therapist', accountId: 1);

      expect(result, isNotNull);
      expect(result.therapistId, 1);
      expect(result.listOfTodaySessions, isNotEmpty);
    });

    test('deve calcular estatísticas corretamente', () async {
      final completedAppointment = sampleAppointment.copyWith(status: 'completed');
      final pendingAppointment = sampleAppointment.copyWith(status: 'agendado');

      when(
        () => scheduleRepository.listAppointments(
          therapistId: 1,
          start: any(named: 'start'),
          end: any(named: 'end'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((invocation) {
        final start = invocation.namedArguments[#start] as DateTime;
        final end = invocation.namedArguments[#end] as DateTime;

        // Se for o mês, retorna appointments completados
        if (start.month == end.month) {
          return Future.value([completedAppointment, pendingAppointment]);
        }
        // Se for o dia, retorna appointments do dia
        return Future.value([pendingAppointment]);
      });

      when(
        () => sessionRepository.listSessions(
          therapistId: 1,
          statuses: any(named: 'statuses'),
          startDate: null,
          endDate: null,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => []);

      final result = await controller.getSummary(therapistId: 1, userId: 1, userRole: 'therapist', accountId: 1);

      expect(result.monthlySessions, greaterThan(0));
      expect(result.monthlyCompletionRate, greaterThanOrEqualTo(0.0));
      expect(result.monthlyCompletionRate, lessThanOrEqualTo(1.0));
    });

    test('deve filtrar por data quando fornecida', () async {
      final referenceDate = DateTime(2024, 2, 15);

      when(
        () => scheduleRepository.listAppointments(
          therapistId: 1,
          start: any(named: 'start'),
          end: any(named: 'end'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => []);

      when(
        () => sessionRepository.listSessions(
          therapistId: 1,
          statuses: any(named: 'statuses'),
          startDate: null,
          endDate: null,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => []);

      final result = await controller.getSummary(
        therapistId: 1,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
        referenceDate: referenceDate,
      );

      expect(result.referenceDate.year, 2024);
      expect(result.referenceDate.month, 2);
      expect(result.referenceDate.day, 15);
    });

    test('deve validar permissões (therapist vê apenas seus dados)', () async {
      when(
        () => scheduleRepository.listAppointments(
          therapistId: 1,
          start: any(named: 'start'),
          end: any(named: 'end'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => []);

      when(
        () => sessionRepository.listSessions(
          therapistId: 1,
          statuses: any(named: 'statuses'),
          startDate: null,
          endDate: null,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => []);

      final result = await controller.getSummary(therapistId: 1, userId: 1, userRole: 'therapist', accountId: 1);

      expect(result.therapistId, 1);
      // Verifica que bypassRLS não foi usado (therapist não é admin)
      verifyNever(
        () => scheduleRepository.listAppointments(
          therapistId: any(named: 'therapistId'),
          start: any(named: 'start'),
          end: any(named: 'end'),
          userId: any(named: 'userId'),
          userRole: any(named: 'userRole'),
          accountId: any(named: 'accountId'),
          bypassRLS: true,
        ),
      );
    });
  });
}
