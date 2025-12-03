import 'package:common/common.dart';
import 'package:mocktail/mocktail.dart';
import 'package:server/features/schedule/schedule.controller.dart';
import 'package:server/features/schedule/schedule.repository.dart';
import 'package:test/test.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

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
      TherapistScheduleSettings(
        therapistId: 1,
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
      ),
    );
  });

  late _MockScheduleRepository repository;
  late ScheduleController controller;

  final sampleAppointment = Appointment(
    id: 1,
    therapistId: 1,
    patientId: 1,
    type: 'session',
    status: 'agendado',
    startTime: DateTime(2024, 1, 15, 10, 0),
    endTime: DateTime(2024, 1, 15, 11, 0),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    repository = _MockScheduleRepository();
    controller = ScheduleController(repository);
  });

  group('ScheduleController - createAppointment', () {
    test('deve criar appointment com dados válidos', () async {
      when(
        () => repository.createAppointment(
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleAppointment);

      final result = await controller.createAppointment(
        appointment: sampleAppointment,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.id, equals(1));
      expect(result.status, 'agendado');
    });

    test('deve lançar ScheduleException quando há conflito de horário', () async {
      when(
        () => repository.createAppointment(
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Conflito de horário: já existe um agendamento'));

      expect(
        () => controller.createAppointment(
          appointment: sampleAppointment,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(
          isA<ScheduleException>().having(
            (e) => e.statusCode,
            'statusCode',
            409, // Conflict
          ),
        ),
      );
    });
  });

  group('ScheduleController - updateAppointment', () {
    test('deve atualizar appointment quando encontrado', () async {
      final updated = sampleAppointment.copyWith(status: 'confirmado');

      when(
        () => repository.updateAppointment(
          appointmentId: 1,
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => updated);

      final result = await controller.updateAppointment(
        appointmentId: 1,
        appointment: updated,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.status, 'confirmado');
    });

    test('deve lançar ScheduleException quando appointment não encontrado', () async {
      when(
        () => repository.updateAppointment(
          appointmentId: 999,
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      expect(
        () => controller.updateAppointment(
          appointmentId: 999,
          appointment: sampleAppointment,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<ScheduleException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('ScheduleController - getAppointment', () {
    test('deve retornar appointment quando encontrado', () async {
      when(
        () => repository.getAppointmentById(
          appointmentId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleAppointment);

      final result = await controller.getAppointment(appointmentId: 1, userId: 1, userRole: 'therapist', accountId: 1);

      expect(result.id, equals(1));
    });

    test('deve lançar ScheduleException quando appointment não encontrado', () async {
      when(
        () => repository.getAppointmentById(
          appointmentId: 999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      expect(
        () => controller.getAppointment(appointmentId: 999, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(isA<ScheduleException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('ScheduleController - deleteAppointment', () {
    test('deve deletar appointment quando encontrado', () async {
      when(
        () => repository.deleteAppointment(
          appointmentId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => true);

      await controller.deleteAppointment(appointmentId: 1, userId: 1, userRole: 'therapist', accountId: 1);

      verify(
        () => repository.deleteAppointment(
          appointmentId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('deve lançar ScheduleException quando appointment não encontrado', () async {
      when(
        () => repository.deleteAppointment(
          appointmentId: 999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => false);

      expect(
        () => controller.deleteAppointment(appointmentId: 999, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(isA<ScheduleException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('ScheduleController - getOrCreateSettings', () {
    final sampleSettings = TherapistScheduleSettings(
      therapistId: 1,
      workingHours: {'monday': {'start': '09:00', 'end': '18:00'}},
      sessionDurationMinutes: 50,
      breakMinutes: 10,
      locations: ['Consultório 1'],
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

    test('retorna configurações existentes', () async {
      when(
        () => repository.getTherapistSettings(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleSettings);

      final result = await controller.getOrCreateSettings(
        therapistId: 1,
        userId: 1,
        userRole: 'therapist',
      );

      expect(result.therapistId, 1);
      expect(result.sessionDurationMinutes, 50);
    });

    test('cria configurações padrão quando não existem', () async {
      when(
        () => repository.getTherapistSettings(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      when(
        () => repository.upsertTherapistSettings(
          settings: any(named: 'settings'),
          userId: 1,
          userRole: 'therapist',
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleSettings);

      final result = await controller.getOrCreateSettings(
        therapistId: 1,
        userId: 1,
        userRole: 'therapist',
      );

      expect(result.therapistId, 1);
      expect(result.sessionDurationMinutes, 50);
      verify(
        () => repository.upsertTherapistSettings(
          settings: any(named: 'settings'),
          userId: 1,
          userRole: 'therapist',
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('trata erros do repository', () async {
      when(
        () => repository.getTherapistSettings(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro de conexão'));

      expect(
        () => controller.getOrCreateSettings(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
        ),
        throwsA(isA<ScheduleException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('usa bypassRLS quando admin', () async {
      when(
        () => repository.getTherapistSettings(
          therapistId: 5,
          userId: 1,
          userRole: 'admin',
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => sampleSettings.copyWith(therapistId: 5));

      final result = await controller.getOrCreateSettings(
        therapistId: 5,
        userId: 1,
        userRole: 'admin',
      );

      expect(result.therapistId, 5);
      verify(
        () => repository.getTherapistSettings(
          therapistId: 5,
          userId: 1,
          userRole: 'admin',
          bypassRLS: true,
        ),
      ).called(1);
    });
  });

  group('ScheduleController - updateSettings', () {
    final sampleSettings = TherapistScheduleSettings(
      therapistId: 1,
      workingHours: {'monday': {'start': '09:00', 'end': '18:00'}},
      sessionDurationMinutes: 50,
      breakMinutes: 10,
      locations: ['Consultório 1'],
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

    test('atualiza configurações com sucesso', () async {
      final updated = sampleSettings.copyWith(sessionDurationMinutes: 60);

      when(
        () => repository.upsertTherapistSettings(
          settings: any(named: 'settings'),
          userId: 1,
          userRole: 'therapist',
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => updated);

      final result = await controller.updateSettings(
        settings: updated,
        userId: 1,
        userRole: 'therapist',
      );

      expect(result.sessionDurationMinutes, 60);
    });

    test('trata erros do repository', () async {
      when(
        () => repository.upsertTherapistSettings(
          settings: any(named: 'settings'),
          userId: 1,
          userRole: 'therapist',
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro de conexão'));

      expect(
        () => controller.updateSettings(
          settings: sampleSettings,
          userId: 1,
          userRole: 'therapist',
        ),
        throwsA(isA<ScheduleException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('usa bypassRLS quando admin', () async {
      final updated = sampleSettings.copyWith(therapistId: 5, sessionDurationMinutes: 60);

      when(
        () => repository.upsertTherapistSettings(
          settings: any(named: 'settings'),
          userId: 1,
          userRole: 'admin',
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => updated);

      final result = await controller.updateSettings(
        settings: updated,
        userId: 1,
        userRole: 'admin',
      );

      expect(result.therapistId, 5);
      verify(
        () => repository.upsertTherapistSettings(
          settings: any(named: 'settings'),
          userId: 1,
          userRole: 'admin',
          bypassRLS: true,
        ),
      ).called(1);
    });
  });

  group('ScheduleController - listAppointments', () {
    test('lista agendamentos com sucesso', () async {
      when(
        () => repository.listAppointments(
          therapistId: 1,
          start: any(named: 'start'),
          end: any(named: 'end'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => [sampleAppointment]);

      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);
      final result = await controller.listAppointments(
        therapistId: 1,
        start: start,
        end: end,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.length, 1);
      expect(result.first.id, 1);
    });

    test('trata erros do repository', () async {
      when(
        () => repository.listAppointments(
          therapistId: 1,
          start: any(named: 'start'),
          end: any(named: 'end'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro de conexão'));

      expect(
        () => controller.listAppointments(
          therapistId: 1,
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<ScheduleException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('usa bypassRLS quando admin', () async {
      when(
        () => repository.listAppointments(
          therapistId: 5,
          start: any(named: 'start'),
          end: any(named: 'end'),
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => []);

      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);
      await controller.listAppointments(
        therapistId: 5,
        start: start,
        end: end,
        userId: 1,
        userRole: 'admin',
        accountId: null,
      );

      verify(
        () => repository.listAppointments(
          therapistId: 5,
          start: start,
          end: end,
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).called(1);
    });

    test('passa accountId corretamente', () async {
      when(
        () => repository.listAppointments(
          therapistId: 1,
          start: any(named: 'start'),
          end: any(named: 'end'),
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => []);

      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);
      await controller.listAppointments(
        therapistId: 1,
        start: start,
        end: end,
        userId: 1,
        userRole: 'therapist',
        accountId: 10,
      );

      verify(
        () => repository.listAppointments(
          therapistId: 1,
          start: start,
          end: end,
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
          bypassRLS: false,
        ),
      ).called(1);
    });
  });

  group('ScheduleController - createAppointment', () {
    test('trata outros erros do repository', () async {
      when(
        () => repository.createAppointment(
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro genérico'));

      expect(
        () => controller.createAppointment(
          appointment: sampleAppointment,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<ScheduleException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('usa bypassRLS quando admin', () async {
      when(
        () => repository.createAppointment(
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => sampleAppointment);

      await controller.createAppointment(
        appointment: sampleAppointment,
        userId: 1,
        userRole: 'admin',
        accountId: null,
      );

      verify(
        () => repository.createAppointment(
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).called(1);
    });
  });

  group('ScheduleController - updateAppointment', () {
    test('trata outros erros do repository', () async {
      when(
        () => repository.updateAppointment(
          appointmentId: 1,
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro genérico'));

      expect(
        () => controller.updateAppointment(
          appointmentId: 1,
          appointment: sampleAppointment,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<ScheduleException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('usa bypassRLS quando admin', () async {
      final updated = sampleAppointment.copyWith(status: 'confirmed');

      when(
        () => repository.updateAppointment(
          appointmentId: 1,
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => updated);

      await controller.updateAppointment(
        appointmentId: 1,
        appointment: updated,
        userId: 1,
        userRole: 'admin',
        accountId: null,
      );

      verify(
        () => repository.updateAppointment(
          appointmentId: 1,
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).called(1);
    });
  });

  group('ScheduleController - getAppointment', () {
    test('trata erros do repository', () async {
      when(
        () => repository.getAppointmentById(
          appointmentId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro de conexão'));

      expect(
        () => controller.getAppointment(appointmentId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(isA<ScheduleException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('usa bypassRLS quando admin', () async {
      when(
        () => repository.getAppointmentById(
          appointmentId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => sampleAppointment);

      final result = await controller.getAppointment(appointmentId: 1, userId: 1, userRole: 'admin', accountId: null);

      expect(result.id, 1);
      verify(
        () => repository.getAppointmentById(
          appointmentId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).called(1);
    });
  });

  group('ScheduleController - deleteAppointment', () {
    test('trata erros do repository', () async {
      when(
        () => repository.deleteAppointment(
          appointmentId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro de conexão'));

      expect(
        () => controller.deleteAppointment(appointmentId: 1, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(isA<ScheduleException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('usa bypassRLS quando admin', () async {
      when(
        () => repository.deleteAppointment(
          appointmentId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => true);

      await controller.deleteAppointment(appointmentId: 1, userId: 1, userRole: 'admin', accountId: null);

      verify(
        () => repository.deleteAppointment(
          appointmentId: 1,
          userId: 1,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).called(1);
    });
  });

  group('ScheduleController - _handleError', () {
    test('detecta conflito de horário corretamente', () async {
      when(
        () => repository.createAppointment(
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Conflito de horário: já existe um agendamento'));

      expect(
        () => controller.createAppointment(
          appointment: sampleAppointment,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(
          isA<ScheduleException>().having(
            (e) => e.statusCode,
            'statusCode',
            409,
          ).having(
            (e) => e.message,
            'message',
            contains('horário já está ocupado'),
          ),
        ),
      );
    });

    test('retorna ScheduleException quando já é ScheduleException', () async {
      when(
        () => repository.createAppointment(
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(ScheduleException('Erro específico', 400));

      expect(
        () => controller.createAppointment(
          appointment: sampleAppointment,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(
          isA<ScheduleException>().having(
            (e) => e.statusCode,
            'statusCode',
            400,
          ).having(
            (e) => e.message,
            'message',
            'Erro específico',
          ),
        ),
      );
    });

    test('retorna erro genérico para outros casos', () async {
      when(
        () => repository.createAppointment(
          appointment: any(named: 'appointment'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro desconhecido'));

      expect(
        () => controller.createAppointment(
          appointment: sampleAppointment,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(
          isA<ScheduleException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });
  });
}
