import 'package:test/test.dart';
import 'package:common/common.dart';
import 'helpers/test_session_repository.dart';

void main() {
  group('SessionRepository', () {
    late TestSessionRepository repository;

    setUp(() {
      repository = TestSessionRepository();
    });

    tearDown(() {
      repository.clear();
    });

    group('createSession', () {
      test('deve criar sessão com dados válidos', () async {
        final session = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );

        final created = await repository.createSession(session: session, userId: 1, bypassRLS: true);

        expect(created.id, isNotNull);
        expect(created.patientId, 1);
        expect(created.therapistId, 1);
        expect(created.status, 'agendada');
        expect(created.createdAt, isNotNull);
      });
    });

    group('getSessionById', () {
      test('deve retornar sessão quando existe', () async {
        final session = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final created = await repository.createSession(session: session, userId: 1, bypassRLS: true);

        final found = await repository.getSessionById(sessionId: created.id!, userId: 1, bypassRLS: true);

        expect(found, isNotNull);
        expect(found!.id, created.id);
      });

      test('deve retornar null quando sessão não existe', () async {
        final found = await repository.getSessionById(sessionId: 999, userId: 1, bypassRLS: true);
        expect(found, isNull);
      });
    });

    group('listSessions', () {
      test('deve filtrar por patient', () async {
        final session1 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final session2 = Session(
          patientId: 2,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );

        await repository.createSession(session: session1, userId: 1, bypassRLS: true);
        await repository.createSession(session: session2, userId: 1, bypassRLS: true);

        final sessions = await repository.listSessions(userId: 1, patientId: 1, bypassRLS: true);

        expect(sessions.length, 1);
        expect(sessions.first.patientId, 1);
      });
    });

    group('listSessions - histórico por paciente', () {
      test('deve retornar sessões do paciente ordenadas por data', () async {
        final session1 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime(2024, 1, 1),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final session2 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime(2024, 1, 15),
          durationMinutes: 60,
          sessionNumber: 2,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );

        await repository.createSession(session: session1, userId: 1, bypassRLS: true);
        await repository.createSession(session: session2, userId: 1, bypassRLS: true);

        final sessions = await repository.listSessions(patientId: 1, userId: 1, bypassRLS: true);

        expect(sessions.length, 2);
        expect(sessions.any((s) => s.scheduledStartTime.month == 1), isTrue);
      });
    });

    group('listSessions - filtros adicionais', () {
      test('deve filtrar por therapistId', () async {
        final session1 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final session2 = Session(
          patientId: 1,
          therapistId: 2,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );

        await repository.createSession(session: session1, userId: 1, bypassRLS: true);
        await repository.createSession(session: session2, userId: 1, bypassRLS: true);

        final sessions = await repository.listSessions(userId: 1, therapistId: 1, bypassRLS: true);

        expect(sessions.length, 1);
        expect(sessions.first.therapistId, 1);
      });

      test('deve filtrar por status', () async {
        final session1 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final session2 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 2,
          type: 'individual',
          modality: 'presencial',
          status: 'completed',
          paymentStatus: 'pendente',
        );

        await repository.createSession(session: session1, userId: 1, bypassRLS: true);
        await repository.createSession(session: session2, userId: 1, bypassRLS: true);

        final sessions = await repository.listSessions(userId: 1, statuses: ['completed'], bypassRLS: true);

        expect(sessions.length, 1);
        expect(sessions.first.status, 'completed');
      });

      test('deve filtrar por appointmentId', () async {
        final session1 = Session(
          patientId: 1,
          therapistId: 1,
          appointmentId: 10,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final session2 = Session(
          patientId: 1,
          therapistId: 1,
          appointmentId: 20,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 2,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );

        await repository.createSession(session: session1, userId: 1, bypassRLS: true);
        await repository.createSession(session: session2, userId: 1, bypassRLS: true);

        final sessions = await repository.listSessions(userId: 1, appointmentId: 10, bypassRLS: true);

        expect(sessions.length, 1);
        expect(sessions.first.appointmentId, 10);
      });

      test('deve filtrar por data de início', () async {
        final session1 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime(2024, 1, 1),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final session2 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime(2024, 2, 1),
          durationMinutes: 60,
          sessionNumber: 2,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );

        await repository.createSession(session: session1, userId: 1, bypassRLS: true);
        await repository.createSession(session: session2, userId: 1, bypassRLS: true);

        final sessions = await repository.listSessions(userId: 1, startDate: DateTime(2024, 2, 1), bypassRLS: true);

        expect(sessions.length, 1);
        expect(sessions.first.scheduledStartTime.month, 2);
      });

      test('deve filtrar por data de término', () async {
        final session1 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime(2024, 1, 1),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final session2 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime(2024, 2, 1),
          durationMinutes: 60,
          sessionNumber: 2,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );

        await repository.createSession(session: session1, userId: 1, bypassRLS: true);
        await repository.createSession(session: session2, userId: 1, bypassRLS: true);

        final sessions = await repository.listSessions(userId: 1, endDate: DateTime(2024, 1, 31), bypassRLS: true);

        expect(sessions.length, 1);
        expect(sessions.first.scheduledStartTime.month, 1);
      });
    });

    group('updateSession', () {
      test('deve atualizar sessão quando existe', () async {
        final session = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final created = await repository.createSession(session: session, userId: 1, bypassRLS: true);

        final updated = await repository.updateSession(
          sessionId: created.id!,
          session: created.copyWith(status: 'completed'),
          userId: 1,
          bypassRLS: true,
        );

        expect(updated, isNotNull);
        expect(updated!.status, 'completed');
        expect(updated.id, created.id);
      });

      test('deve retornar null quando sessão não existe', () async {
        final session = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );

        final updated = await repository.updateSession(sessionId: 999, session: session, userId: 1, bypassRLS: true);

        expect(updated, isNull);
      });

      test('não deve permitir alterar sessionNumber', () async {
        final session = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final created = await repository.createSession(session: session, userId: 1, bypassRLS: true);

        final updated = await repository.updateSession(
          sessionId: created.id!,
          session: created.copyWith(sessionNumber: 999),
          userId: 1,
          bypassRLS: true,
        );

        expect(updated, isNotNull);
        expect(updated!.sessionNumber, 1); // sessionNumber não deve mudar
      });
    });

    group('deleteSession', () {
      test('deve deletar sessão quando existe', () async {
        final session = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final created = await repository.createSession(session: session, userId: 1, bypassRLS: true);

        final deleted = await repository.deleteSession(sessionId: created.id!, userId: 1, bypassRLS: true);

        expect(deleted, isTrue);

        final found = await repository.getSessionById(sessionId: created.id!, userId: 1, bypassRLS: true);
        expect(found, isNull);
      });

      test('deve retornar false quando sessão não existe', () async {
        final deleted = await repository.deleteSession(sessionId: 999, userId: 1, bypassRLS: true);

        expect(deleted, isFalse);
      });
    });

    group('getNextSessionNumber', () {
      test('deve retornar 1 quando paciente não tem sessões', () async {
        final nextNumber = await repository.getNextSessionNumber(patientId: 1, userId: 1, bypassRLS: true);

        expect(nextNumber, 1);
      });

      test('deve retornar próximo número sequencial', () async {
        final session1 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final session2 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 2,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final session3 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 5,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );

        await repository.createSession(session: session1, userId: 1, bypassRLS: true);
        await repository.createSession(session: session2, userId: 1, bypassRLS: true);
        await repository.createSession(session: session3, userId: 1, bypassRLS: true);

        final nextNumber = await repository.getNextSessionNumber(patientId: 1, userId: 1, bypassRLS: true);

        expect(nextNumber, 6); // Máximo é 5, então próximo é 6
      });

      test('deve calcular número por paciente específico', () async {
        final session1 = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 3,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );
        final session2 = Session(
          patientId: 2,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 7,
          type: 'individual',
          modality: 'presencial',
          status: 'agendada',
          paymentStatus: 'pendente',
        );

        await repository.createSession(session: session1, userId: 1, bypassRLS: true);
        await repository.createSession(session: session2, userId: 1, bypassRLS: true);

        final nextNumber1 = await repository.getNextSessionNumber(patientId: 1, userId: 1, bypassRLS: true);
        final nextNumber2 = await repository.getNextSessionNumber(patientId: 2, userId: 1, bypassRLS: true);

        expect(nextNumber1, 4); // Paciente 1 tem máximo 3
        expect(nextNumber2, 8); // Paciente 2 tem máximo 7
      });
    });

    group('createSession - campos adicionais', () {
      test('deve criar sessão com todos os campos clínicos', () async {
        final session = Session(
          patientId: 1,
          therapistId: 1,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 60,
          sessionNumber: 1,
          type: 'presential',
          modality: 'individual',
          status: 'completed',
          paymentStatus: 'paid',
          patientMood: 'ansioso',
          topicsDiscussed: ['ansiedade', 'trabalho'],
          sessionNotes: 'Notas da sessão',
          observedBehavior: 'Comportamento observado',
          interventionsUsed: ['TCC', 'Mindfulness'],
          resourcesUsed: 'Exercícios de respiração',
          homework: 'Praticar exercícios diários',
          patientReactions: 'Reações do paciente',
          progressObserved: 'Progresso observado',
          difficultiesIdentified: 'Dificuldades identificadas',
          nextSteps: 'Próximos passos',
          nextSessionGoals: 'Objetivos da próxima sessão',
          needsReferral: false,
          currentRisk: 'low',
          importantObservations: 'Observações importantes',
          chargedAmount: 150.0,
        );

        final created = await repository.createSession(session: session, userId: 1, bypassRLS: true);

        expect(created.id, isNotNull);
        expect(created.patientMood, 'ansioso');
        expect(created.topicsDiscussed, ['ansiedade', 'trabalho']);
        expect(created.sessionNotes, 'Notas da sessão');
        expect(created.interventionsUsed, ['TCC', 'Mindfulness']);
        expect(created.chargedAmount, 150.0);
      });
    });
  });
}
