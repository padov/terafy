import 'package:common/common.dart';
import 'package:mocktail/mocktail.dart';
import 'package:server/features/session/session.controller.dart';
import 'package:server/features/session/session.repository.dart';
import 'package:server/features/financial/financial.repository.dart';
import 'package:test/test.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockFinancialRepository extends Mock implements FinancialRepository {}

void main() {
  setUpAll(() {
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
    registerFallbackValue(
      FinancialTransaction(
        therapistId: 1,
        patientId: 1,
        transactionDate: DateTime.now(),
        type: 'income',
        amount: 100.0,
        paymentMethod: 'credit_card',
        status: 'pendente',
        category: 'session',
      ),
    );
  });

  late _MockSessionRepository sessionRepository;
  late _MockFinancialRepository financialRepository;
  late SessionController controller;

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
    sessionRepository = _MockSessionRepository();
    financialRepository = _MockFinancialRepository();
    controller = SessionController(sessionRepository, financialRepository);
  });

  group('SessionController - createSession', () {
    test('deve criar sessão com dados válidos', () async {
      when(
        () => sessionRepository.createSession(
          session: any(named: 'session'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleSession);

      final result = await controller.createSession(
        session: sampleSession,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.id, equals(1));
      expect(result.status, 'agendada');
    });

    test('deve validar ID do paciente', () async {
      final invalidSession = sampleSession.copyWith(patientId: 0);

      expect(
        () => controller.createSession(session: invalidSession, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(isA<SessionException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve validar duração maior que zero', () async {
      final invalidSession = sampleSession.copyWith(durationMinutes: 0);

      expect(
        () => controller.createSession(session: invalidSession, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(isA<SessionException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve calcular sessionNumber automaticamente quando não fornecido', () async {
      final sessionWithoutNumber = sampleSession.copyWith(sessionNumber: 0);

      when(
        () => sessionRepository.getNextSessionNumber(
          patientId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => 5);

      when(
        () => sessionRepository.createSession(
          session: any(named: 'session'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleSession.copyWith(sessionNumber: 5));

      final result = await controller.createSession(
        session: sessionWithoutNumber,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.sessionNumber, equals(5));
    });
  });

  group('SessionController - updateSession', () {
    test('deve atualizar sessão quando encontrada', () async {
      final updated = sampleSession.copyWith(status: 'completed');

      when(
        () => sessionRepository.getSessionById(
          sessionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleSession);

      when(
        () => sessionRepository.updateSession(
          sessionId: 1,
          session: any(named: 'session'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => updated);

      final result = await controller.updateSession(
        sessionId: 1,
        session: updated,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.status, 'completed');
    });

    test('deve lançar SessionException quando sessão não encontrada', () async {
      when(
        () => sessionRepository.getSessionById(
          sessionId: 999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      expect(
        () => controller.updateSession(
          sessionId: 999,
          session: sampleSession,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<SessionException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('SessionController - getSession', () {
    test('deve retornar sessão quando encontrada', () async {
      when(
        () => sessionRepository.getSessionById(
          sessionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleSession);

      final result = await controller.getSession(sessionId: 1, userId: 1, userRole: 'therapist', accountId: 1);

      expect(result.id, equals(1));
    });

    test('deve lançar SessionException quando sessão não encontrada', () async {
      when(
        () => sessionRepository.getSessionById(
          sessionId: 999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      expect(
        () => controller.getSession(sessionId: 999, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(isA<SessionException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('SessionController - listSessions', () {
    test('deve listar todas as sessões quando nenhum filtro fornecido', () async {
      when(
        () => sessionRepository.listSessions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
          patientId: null,
          therapistId: null,
          appointmentId: null,
          status: null,
          startDate: null,
          endDate: null,
        ),
      ).thenAnswer((_) async => [sampleSession]);

      final result = await controller.listSessions(
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.length, equals(1));
      expect(result.first.id, equals(1));
    });

    test('deve filtrar por patientId quando fornecido', () async {
      when(
        () => sessionRepository.listSessions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
          patientId: 1,
          therapistId: null,
          appointmentId: null,
          status: null,
          startDate: null,
          endDate: null,
        ),
      ).thenAnswer((_) async => [sampleSession]);

      final result = await controller.listSessions(
        patientId: 1,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.length, equals(1));
      verify(
        () => sessionRepository.listSessions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
          patientId: 1,
          therapistId: null,
          appointmentId: null,
          status: null,
          startDate: null,
          endDate: null,
        ),
      ).called(1);
    });

    test('deve filtrar por status quando fornecido', () async {
      when(
        () => sessionRepository.listSessions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
          patientId: null,
          therapistId: null,
          appointmentId: null,
          status: 'completed',
          startDate: null,
          endDate: null,
        ),
      ).thenAnswer((_) async => []);

      final result = await controller.listSessions(
        status: 'completed',
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.isEmpty, isTrue);
    });
  });

  group('SessionController - updateSession', () {
    test('deve validar duração maior que zero', () async {
      final invalidSession = sampleSession.copyWith(durationMinutes: 0);

      expect(
        () => controller.updateSession(
          sessionId: 1,
          session: invalidSession,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<SessionException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve validar data de término posterior à data de início', () async {
      final invalidSession = sampleSession.copyWith(
        scheduledStartTime: DateTime.now().add(const Duration(days: 2)),
        scheduledEndTime: DateTime.now(),
      );

      expect(
        () => controller.updateSession(
          sessionId: 1,
          session: invalidSession,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<SessionException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve criar transação financeira quando sessão é marcada como completed com chargedAmount', () async {
      final completedSession = sampleSession.copyWith(
        status: 'completed',
        chargedAmount: 150.0,
      );

      when(
        () => sessionRepository.getSessionById(
          sessionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleSession);

      when(
        () => sessionRepository.updateSession(
          sessionId: 1,
          session: any(named: 'session'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => completedSession);

      when(
        () => financialRepository.listTransactions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
          sessionId: 1,
        ),
      ).thenAnswer((_) async => []);

      when(
        () => financialRepository.createTransaction(
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => FinancialTransaction(
            id: 1,
            therapistId: 1,
            patientId: 1,
            sessionId: 1,
            transactionDate: DateTime.now(),
            type: 'recebimento',
            amount: 150.0,
            paymentMethod: 'pix',
            status: 'pendente',
            category: 'sessao',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

      final result = await controller.updateSession(
        sessionId: 1,
        session: completedSession,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.status, 'completed');
      verify(
        () => financialRepository.createTransaction(
          transaction: any(named: 'transaction'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('não deve criar transação quando já existe transação vinculada', () async {
      final completedSession = sampleSession.copyWith(
        status: 'completed',
        chargedAmount: 150.0,
      );

      when(
        () => sessionRepository.getSessionById(
          sessionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleSession);

      when(
        () => sessionRepository.updateSession(
          sessionId: 1,
          session: any(named: 'session'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => completedSession);

      when(
        () => financialRepository.listTransactions(
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
          sessionId: 1,
        ),
      ).thenAnswer((_) async => [
            FinancialTransaction(
              id: 1,
              therapistId: 1,
              patientId: 1,
              sessionId: 1,
              transactionDate: DateTime.now(),
              type: 'recebimento',
              amount: 150.0,
              paymentMethod: 'pix',
              status: 'pendente',
              category: 'sessao',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ]);

      final result = await controller.updateSession(
        sessionId: 1,
        session: completedSession,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.status, 'completed');
      verifyNever(
        () => financialRepository.createTransaction(
          transaction: any(named: 'transaction'),
          userId: any(named: 'userId'),
          userRole: any(named: 'userRole'),
          accountId: any(named: 'accountId'),
          bypassRLS: any(named: 'bypassRLS'),
        ),
      );
    });

    test('não deve criar transação quando sessão já estava completed', () async {
      final alreadyCompleted = sampleSession.copyWith(status: 'completed');
      final updated = alreadyCompleted.copyWith(chargedAmount: 150.0);

      when(
        () => sessionRepository.getSessionById(
          sessionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => alreadyCompleted);

      when(
        () => sessionRepository.updateSession(
          sessionId: 1,
          session: any(named: 'session'),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => updated);

      await controller.updateSession(
        sessionId: 1,
        session: updated,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      verifyNever(
        () => financialRepository.listTransactions(
          userId: any(named: 'userId'),
          userRole: any(named: 'userRole'),
          accountId: any(named: 'accountId'),
          bypassRLS: any(named: 'bypassRLS'),
          sessionId: any(named: 'sessionId'),
        ),
      );
    });
  });

  group('SessionController - deleteSession', () {
    test('deve deletar sessão quando encontrada', () async {
      when(
        () => sessionRepository.deleteSession(
          sessionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => true);

      await controller.deleteSession(
        sessionId: 1,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      verify(
        () => sessionRepository.deleteSession(
          sessionId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('deve lançar SessionException quando sessão não encontrada', () async {
      when(
        () => sessionRepository.deleteSession(
          sessionId: 999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => false);

      expect(
        () => controller.deleteSession(
          sessionId: 999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<SessionException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('SessionController - getNextSessionNumber', () {
    test('deve retornar próximo número de sessão', () async {
      when(
        () => sessionRepository.getNextSessionNumber(
          patientId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => 5);

      final result = await controller.getNextSessionNumber(
        patientId: 1,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result, equals(5));
    });

    test('deve lançar SessionException em caso de erro', () async {
      when(
        () => sessionRepository.getNextSessionNumber(
          patientId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenThrow(Exception('Erro no banco'));

      expect(
        () => controller.getNextSessionNumber(
          patientId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(isA<SessionException>()),
      );
    });
  });

  group('SessionController - createSession validações adicionais', () {
    test('deve validar ID do terapeuta', () async {
      final invalidSession = sampleSession.copyWith(therapistId: 0);

      expect(
        () => controller.createSession(session: invalidSession, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(isA<SessionException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('deve validar data de término posterior à data de início', () async {
      final invalidSession = sampleSession.copyWith(
        scheduledStartTime: DateTime.now().add(const Duration(days: 2)),
        scheduledEndTime: DateTime.now(),
      );

      expect(
        () => controller.createSession(session: invalidSession, userId: 1, userRole: 'therapist', accountId: 1),
        throwsA(isA<SessionException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });
  });
}
