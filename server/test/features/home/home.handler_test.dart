import 'package:common/common.dart';
import 'package:mocktail/mocktail.dart';
import 'package:server/features/home/home.controller.dart';
import 'package:server/features/home/home.handler.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _MockHomeController extends Mock implements HomeController {}

class _MockRequest extends Mock implements Request {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      HomeSummary(
        referenceDate: DateTime.now(),
        therapistId: 1,
        todayPendingSessions: 0,
        todayConfirmedSessions: 0,
        monthlyCompletionRate: 0.0,
        monthlySessions: 0,
        listOfTodaySessions: [],
        pendingSessions: [],
      ),
    );
  });

  late _MockHomeController mockController;
  late HomeHandler handler;

  setUp(() {
    mockController = _MockHomeController();
    handler = HomeHandler(mockController);
  });

  group('HomeHandler - handleGetSummary', () {
    test('deve retornar 401 quando não há userId', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary'));

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 401);
      final body = await response.readAsString();
      expect(body, contains('Autenticação necessária'));
    });

    test('deve retornar 401 quando não há userRole', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({'x-user-id': '1'});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary'));

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 401);
      final body = await response.readAsString();
      expect(body, contains('Autenticação necessária'));
    });

    test('deve retornar 400 quando therapist não tem accountId', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({'x-user-id': '1', 'x-user-role': 'therapist'});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary'));

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 400);
      final body = await response.readAsString();
      expect(body, contains('Conta de terapeuta não vinculada'));
    });

    test('deve retornar 400 quando admin não fornece therapistId', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({'x-user-id': '1', 'x-user-role': 'admin', 'x-account-id': '1'});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary'));

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 400);
      final body = await response.readAsString();
      expect(body, contains('Informe o therapistId'));
    });

    test('deve retornar 400 quando therapistId é inválido', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({'x-user-id': '1', 'x-user-role': 'admin', 'x-account-id': '1'});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary?therapistId=invalid'));

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 400);
      final body = await response.readAsString();
      expect(body, contains('therapistId inválido'));
    });

    test('deve retornar 400 quando parâmetro de data é inválido', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary?date=invalid-date'));

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 400);
      final body = await response.readAsString();
      expect(body, contains('Parâmetro de data inválido'));
    });

    test('deve retornar 403 quando userRole não é therapist nem admin', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({'x-user-id': '1', 'x-user-role': 'patient', 'x-account-id': '1'});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary'));

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 403);
      final body = await response.readAsString();
      expect(body, contains('Somente terapeutas ou administradores'));
    });

    test('deve retornar 200 com resumo quando therapist faz requisição válida', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary'));

      final mockSummary = HomeSummary(
        referenceDate: DateTime(2024, 1, 15),
        therapistId: 1,
        todayPendingSessions: 2,
        todayConfirmedSessions: 3,
        monthlyCompletionRate: 0.85,
        monthlySessions: 20,
        listOfTodaySessions: [],
        pendingSessions: [],
      );

      when(
        () => mockController.getSummary(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          referenceDate: null,
        ),
      ).thenAnswer((_) async => mockSummary);

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 200);
      final body = await response.readAsString();
      expect(body, contains('therapistId'));
      expect(body, contains('todayPendingSessions'));
    });

    test('deve retornar 200 quando admin faz requisição válida com therapistId', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({'x-user-id': '1', 'x-user-role': 'admin', 'x-account-id': '1'});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary?therapistId=2'));

      final mockSummary = HomeSummary(
        referenceDate: DateTime(2024, 1, 15),
        therapistId: 2,
        todayPendingSessions: 1,
        todayConfirmedSessions: 2,
        monthlyCompletionRate: 0.75,
        monthlySessions: 15,
        listOfTodaySessions: [],
        pendingSessions: [],
      );

      when(
        () =>
            mockController.getSummary(therapistId: 2, userId: 1, userRole: 'admin', accountId: 2, referenceDate: null),
      ).thenAnswer((_) async => mockSummary);

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 200);
      final body = await response.readAsString();
      expect(body, contains('"therapistId":2'));
    });

    test('deve passar referenceDate quando fornecida', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary?date=2024-02-15'));

      final mockSummary = HomeSummary(
        referenceDate: DateTime(2024, 2, 15),
        therapistId: 1,
        todayPendingSessions: 0,
        todayConfirmedSessions: 0,
        monthlyCompletionRate: 0.0,
        monthlySessions: 0,
        listOfTodaySessions: [],
        pendingSessions: [],
      );

      when(
        () => mockController.getSummary(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          referenceDate: DateTime(2024, 2, 15),
        ),
      ).thenAnswer((_) async => mockSummary);

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 200);
      verify(
        () => mockController.getSummary(
          therapistId: 1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          referenceDate: DateTime(2024, 2, 15),
        ),
      ).called(1);
    });

    test('deve retornar erro quando controller lança HomeException', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary'));

      when(
        () => mockController.getSummary(
          therapistId: any(named: 'therapistId'),
          userId: any(named: 'userId'),
          userRole: any(named: 'userRole'),
          accountId: any(named: 'accountId'),
          referenceDate: any(named: 'referenceDate'),
        ),
      ).thenThrow(HomeException('Erro customizado', 422));

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 422);
      final body = await response.readAsString();
      expect(body, contains('Erro customizado'));
    });

    test('deve retornar 500 quando controller lança exceção genérica', () async {
      final request = _MockRequest();
      when(() => request.headers).thenReturn({'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'});
      when(() => request.url).thenReturn(Uri.parse('http://localhost/api/home/summary'));

      when(
        () => mockController.getSummary(
          therapistId: any(named: 'therapistId'),
          userId: any(named: 'userId'),
          userRole: any(named: 'userRole'),
          accountId: any(named: 'accountId'),
          referenceDate: any(named: 'referenceDate'),
        ),
      ).thenThrow(Exception('Erro inesperado'));

      final response = await handler.handleGetSummary(request);

      expect(response.statusCode, 500);
      final body = await response.readAsString();
      expect(body, contains('Erro ao carregar resumo da home'));
    });
  });
}
