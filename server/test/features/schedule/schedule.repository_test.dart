import 'package:test/test.dart';
import 'package:common/common.dart';
import 'helpers/test_schedule_repository.dart';

void main() {
  group('ScheduleRepository', () {
    late TestScheduleRepository repository;

    setUp(() {
      repository = TestScheduleRepository();
    });

    tearDown(() {
      repository.clear();
    });

    group('createAppointment', () {
      test('deve criar appointment com dados válidos', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );

        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);

        expect(created.id, isNotNull);
        expect(created.therapistId, 1);
        expect(created.status, 'agendado');
        expect(created.createdAt, isNotNull);
      });

      test('deve validar conflito de horário (mesmo therapist, horário sobreposto)', () async {
        final appointment1 = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final appointment2 = Appointment(
          therapistId: 1, // Mesmo therapist
          patientId: 2,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 30), // Sobreposto
          endTime: DateTime(2024, 1, 15, 11, 30),
        );

        await repository.createAppointment(appointment: appointment1, userId: 1, bypassRLS: true);

        expect(
          () => repository.createAppointment(appointment: appointment2, userId: 1, bypassRLS: true),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Conflito de horário'))),
        );
      });

      test('deve permitir appointments diferentes no mesmo horário (therapists diferentes)', () async {
        final appointment1 = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final appointment2 = Appointment(
          therapistId: 2, // Therapist diferente
          patientId: 2,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0), // Mesmo horário
          endTime: DateTime(2024, 1, 15, 11, 0),
        );

        await repository.createAppointment(appointment: appointment1, userId: 1, bypassRLS: true);
        final created2 = await repository.createAppointment(appointment: appointment2, userId: 1, bypassRLS: true);

        expect(created2.id, isNotNull);
      });
    });

    group('getAppointmentById', () {
      test('deve retornar appointment quando existe', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);

        final found = await repository.getAppointmentById(appointmentId: created.id!, userId: 1, bypassRLS: true);

        expect(found, isNotNull);
        expect(found!.id, created.id);
      });
    });

    group('listAppointments', () {
      test('deve filtrar por data', () async {
        final appointment1 = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final appointment2 = Appointment(
          therapistId: 1,
          patientId: 2,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 2, 15, 10, 0), // Data diferente
          endTime: DateTime(2024, 2, 15, 11, 0),
        );

        await repository.createAppointment(appointment: appointment1, userId: 1, bypassRLS: true);
        await repository.createAppointment(appointment: appointment2, userId: 1, bypassRLS: true);

        final appointments = await repository.listAppointments(
          therapistId: 1,
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
          userId: 1,
          bypassRLS: true,
        );

        expect(appointments.length, 1);
        expect(appointments.first.startTime.month, 1);
      });

      test('deve filtrar por therapistId', () async {
        final appointment1 = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final appointment2 = Appointment(
          therapistId: 2,
          patientId: 2,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );

        await repository.createAppointment(appointment: appointment1, userId: 1, bypassRLS: true);
        await repository.createAppointment(appointment: appointment2, userId: 1, bypassRLS: true);

        final appointments = await repository.listAppointments(
          therapistId: 1,
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
          userId: 1,
          bypassRLS: true,
        );

        expect(appointments.length, 1);
        expect(appointments.first.therapistId, 1);
      });

      test('deve ordenar por start_time', () async {
        final appointment1 = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 14, 0),
          endTime: DateTime(2024, 1, 15, 15, 0),
        );
        final appointment2 = Appointment(
          therapistId: 1,
          patientId: 2,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );

        await repository.createAppointment(appointment: appointment1, userId: 1, bypassRLS: true);
        await repository.createAppointment(appointment: appointment2, userId: 1, bypassRLS: true);

        final appointments = await repository.listAppointments(
          therapistId: 1,
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
          userId: 1,
          bypassRLS: true,
        );

        expect(appointments.length, 2);
        expect(appointments.first.startTime.hour, 10);
        expect(appointments.last.startTime.hour, 14);
      });

      test('deve retornar lista vazia quando não há agendamentos', () async {
        final appointments = await repository.listAppointments(
          therapistId: 1,
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
          userId: 1,
          bypassRLS: true,
        );

        expect(appointments, isEmpty);
      });

      test('deve usar RLS corretamente', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );

        await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: false);

        final appointments = await repository.listAppointments(
          therapistId: 1,
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        );

        expect(appointments.length, 1);
      });

      test('deve bypassar RLS quando solicitado', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );

        await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);

        final appointments = await repository.listAppointments(
          therapistId: 1,
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 31),
          userId: 1,
          bypassRLS: true,
        );

        expect(appointments.length, 1);
      });
    });

    group('getAppointmentById', () {
      test('deve retornar null quando não existe', () async {
        final found = await repository.getAppointmentById(appointmentId: 999, userId: 1, bypassRLS: true);

        expect(found, isNull);
      });

      test('deve usar RLS corretamente', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: false);

        final found = await repository.getAppointmentById(
          appointmentId: created.id!,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        );

        expect(found, isNotNull);
      });

      test('deve bypassar RLS quando solicitado', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'agendado',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);

        final found = await repository.getAppointmentById(
          appointmentId: created.id!,
          userId: 1,
          bypassRLS: true,
        );

        expect(found, isNotNull);
      });
    });

    group('createAppointment', () {
      test('deve criar appointment com todos os campos', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          patientName: 'Paciente Teste',
          type: 'session',
          status: 'reserved',
          title: 'Sessão de Teste',
          description: 'Descrição da sessão',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
          location: 'Consultório 1',
          onlineLink: 'https://meet.example.com/room',
          color: '#FF0000',
          notes: 'Notas do agendamento',
        );

        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);

        expect(created.id, isNotNull);
        expect(created.title, 'Sessão de Teste');
        expect(created.description, 'Descrição da sessão');
        expect(created.location, 'Consultório 1');
        expect(created.onlineLink, 'https://meet.example.com/room');
        expect(created.color, '#FF0000');
        expect(created.notes, 'Notas do agendamento');
      });

      test('deve definir created_at e updated_at', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'reserved',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );

        final before = DateTime.now();
        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);
        final after = DateTime.now();

        expect(created.createdAt, isNotNull);
        expect(created.updatedAt, isNotNull);
        expect(created.createdAt!.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(created.createdAt!.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });

      test('deve usar RLS corretamente', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'reserved',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );

        final created = await repository.createAppointment(
          appointment: appointment,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        );

        expect(created.id, isNotNull);
      });

      test('deve bypassar RLS quando solicitado', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'reserved',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );

        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);

        expect(created.id, isNotNull);
      });
    });

    group('updateAppointment', () {
      test('deve atualizar appointment com sucesso', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'reserved',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);

        final updated = created.copyWith(
          status: 'confirmed',
          title: 'Sessão Confirmada',
          notes: 'Notas atualizadas',
        );

        final result = await repository.updateAppointment(
          appointmentId: created.id!,
          appointment: updated,
          userId: 1,
          bypassRLS: true,
        );

        expect(result.status, 'confirmed');
        expect(result.title, 'Sessão Confirmada');
        expect(result.notes, 'Notas atualizadas');
        expect(result.updatedAt, isNotNull);
        expect(result.updatedAt!.isAfter(created.updatedAt!), isTrue);
      });

      test('deve retornar null quando não encontrado', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'reserved',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );

        expect(
          () => repository.updateAppointment(
            appointmentId: 999,
            appointment: appointment,
            userId: 1,
            bypassRLS: true,
          ),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('não encontrado'))),
        );
      });

      test('não deve atualizar therapist_id', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'reserved',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);

        final updated = created.copyWith(therapistId: 999); // Tentativa de mudar therapistId

        final result = await repository.updateAppointment(
          appointmentId: created.id!,
          appointment: updated,
          userId: 1,
          bypassRLS: true,
        );

        expect(result.therapistId, 1); // Deve manter o original
      });

      test('deve atualizar updated_at', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'reserved',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);

        await Future.delayed(const Duration(milliseconds: 10));

        final updated = created.copyWith(status: 'confirmed');
        final result = await repository.updateAppointment(
          appointmentId: created.id!,
          appointment: updated,
          userId: 1,
          bypassRLS: true,
        );

        expect(result.updatedAt, isNotNull);
        expect(result.updatedAt!.isAfter(created.updatedAt!), isTrue);
      });

      test('deve usar RLS corretamente', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'reserved',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final created = await repository.createAppointment(
          appointment: appointment,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        );

        final updated = created.copyWith(status: 'confirmed');
        final result = await repository.updateAppointment(
          appointmentId: created.id!,
          appointment: updated,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        );

        expect(result.status, 'confirmed');
      });

      test('deve bypassar RLS quando solicitado', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'reserved',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);

        final updated = created.copyWith(status: 'confirmed');
        final result = await repository.updateAppointment(
          appointmentId: created.id!,
          appointment: updated,
          userId: 1,
          bypassRLS: true,
        );

        expect(result.status, 'confirmed');
      });
    });

    group('deleteAppointment', () {
      test('deve retornar false quando não encontrado', () async {
        final deleted = await repository.deleteAppointment(appointmentId: 999, userId: 1, bypassRLS: true);

        expect(deleted, isFalse);
      });

      test('deve usar RLS corretamente', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'reserved',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final created = await repository.createAppointment(
          appointment: appointment,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        );

        final deleted = await repository.deleteAppointment(
          appointmentId: created.id!,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        );

        expect(deleted, isTrue);
      });

      test('deve bypassar RLS quando solicitado', () async {
        final appointment = Appointment(
          therapistId: 1,
          patientId: 1,
          type: 'session',
          status: 'reserved',
          startTime: DateTime(2024, 1, 15, 10, 0),
          endTime: DateTime(2024, 1, 15, 11, 0),
        );
        final created = await repository.createAppointment(appointment: appointment, userId: 1, bypassRLS: true);

        final deleted = await repository.deleteAppointment(appointmentId: created.id!, userId: 1, bypassRLS: true);

        expect(deleted, isTrue);
      });
    });
  });
}
