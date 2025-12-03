import 'dart:convert';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:common/common.dart';
import 'package:server/features/session/session.handler.dart';
import 'package:server/features/session/session.controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionController extends Mock implements SessionController {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Session(
        patientId: 1,
        therapistId: 1,
        scheduledStartTime: DateTime.now(),
        durationMinutes: 60,
        sessionNumber: 1,
        type: 'presential',
        modality: 'individual',
        status: 'scheduled',
        paymentStatus: 'pending',
      ),
    );
  });

  group('SessionHandler', () {
    late _MockSessionController controller;
    late SessionHandler handler;

    setUp(() {
      controller = _MockSessionController();
      handler = SessionHandler(controller);
    });

    // Helper para criar request autenticado
    Request createAuthenticatedRequest({
      required String method,
      required String path,
      Map<String, dynamic>? body,
      Map<String, String>? headers,
      int? userId,
      String? userRole,
      int? accountId,
      Map<String, String>? queryParams,
    }) {
      final uri = Uri.parse('http://localhost$path').replace(queryParameters: queryParams ?? {});
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'x-user-id': (userId ?? 1).toString(),
        'x-user-role': userRole ?? 'therapist',
        if (accountId != null) 'x-account-id': accountId.toString(),
        ...?headers,
      };

      return Request(
        method,
        uri,
        body: body != null ? jsonEncode(body) : null,
        headers: defaultHeaders,
      );
    }

    final sampleSession = Session(
      id: 1,
      patientId: 1,
      therapistId: 1,
      scheduledStartTime: DateTime.now().add(const Duration(days: 1)),
      scheduledEndTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
      durationMinutes: 60,
      sessionNumber: 1,
      type: 'presential',
      modality: 'individual',
      status: 'scheduled',
      paymentStatus: 'pending',
      currentRisk: 'low',
      needsReferral: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    group('handleCreateSession', () {
      test('deve criar sessão quando therapist autenticado (200)', () async {
        when(
          () => controller.createSession(
            session: any(named: 'session'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => sampleSession);

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': 1,
            'scheduledStartTime': sampleSession.scheduledStartTime.toIso8601String(),
            'scheduledEndTime': sampleSession.scheduledEndTime?.toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 1,
            'type': 'presential',
            'modality': 'individual',
            'status': 'scheduled',
            'paymentStatus': 'pending',
            'currentRisk': 'low',
            'needsReferral': false,
          },
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleCreateSession(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], 1);
        expect(data['therapistId'], 1);
      });

      test('deve criar sessão quando admin autenticado com therapistId (200)', () async {
        when(
          () => controller.createSession(
            session: any(named: 'session'),
            userId: 1,
            userRole: 'admin',
            accountId: null,
          ),
        ).thenAnswer((_) async => sampleSession);

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': 1,
            'therapistId': 1,
            'scheduledStartTime': sampleSession.scheduledStartTime.toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 1,
            'type': 'presential',
            'modality': 'individual',
            'status': 'scheduled',
            'paymentStatus': 'pending',
          },
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleCreateSession(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], 1);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/sessions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'patientId': 1,
            'scheduledStartTime': DateTime.now().toIso8601String(),
            'durationMinutes': 60,
          }),
        );

        final response = await handler.handleCreateSession(request);

        expect(response.statusCode, 401);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Autenticação'));
      });

      test('deve retornar 400 quando corpo vazio', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/sessions',
          body: null,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleCreateSession(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('vazio'));
      });

      test('deve retornar 400 quando therapist sem accountId', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': 1,
            'scheduledStartTime': DateTime.now().toIso8601String(),
            'durationMinutes': 60,
          },
          userId: 1,
          userRole: 'therapist',
          accountId: null,
        );

        final response = await handler.handleCreateSession(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('perfil'));
      });

      test('deve retornar 403 quando role não autorizado', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': 1,
            'scheduledStartTime': DateTime.now().toIso8601String(),
            'durationMinutes': 60,
          },
          userId: 1,
          userRole: 'patient',
        );

        final response = await handler.handleCreateSession(request);

        expect(response.statusCode, 403);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('terapeutas ou administradores'));
      });

      test('deve retornar 400 quando admin sem therapistId', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': 1,
            'scheduledStartTime': DateTime.now().toIso8601String(),
            'durationMinutes': 60,
          },
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleCreateSession(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('therapistId'));
      });

      test('deve retornar 400 quando SessionException lançada', () async {
        when(
          () => controller.createSession(
            session: any(named: 'session'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(SessionException('ID do paciente inválido', 400));

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/sessions',
          body: {
            'patientId': 0,
            'scheduledStartTime': DateTime.now().toIso8601String(),
            'durationMinutes': 60,
          },
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleCreateSession(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('paciente inválido'));
      });
    });

    group('handleGetSession', () {
      test('deve retornar sessão quando encontrada (200)', () async {
        when(
          () => controller.getSession(
            sessionId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => sampleSession);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/sessions/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetSession(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], 1);
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/sessions/abc',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetSession(request, 'abc');

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('inválido'));
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request('GET', Uri.parse('http://localhost/sessions/1'));

        final response = await handler.handleGetSession(request, '1');

        expect(response.statusCode, 401);
      });

      test('deve retornar 404 quando sessão não encontrada', () async {
        when(
          () => controller.getSession(
            sessionId: 999,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(SessionException('Sessão não encontrada', 404));

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/sessions/999',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetSession(request, '999');

        expect(response.statusCode, 404);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('não encontrada'));
      });
    });

    group('handleListSessions', () {
      test('deve listar sessões quando therapist autenticado (200)', () async {
        when(
          () => controller.listSessions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: null,
            appointmentId: null,
            status: null,
            startDate: null,
            endDate: null,
          ),
        ).thenAnswer((_) async => [sampleSession]);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/sessions',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleListSessions(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as List;
        expect(data.length, 1);
        expect(data[0]['id'], 1);
      });

      test('deve filtrar por patientId quando fornecido', () async {
        when(
          () => controller.listSessions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: 1,
            appointmentId: null,
            status: null,
            startDate: null,
            endDate: null,
          ),
        ).thenAnswer((_) async => [sampleSession]);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/sessions',
          queryParams: {'patientId': '1'},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleListSessions(request);

        expect(response.statusCode, 200);
        verify(
          () => controller.listSessions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: 1,
            appointmentId: null,
            status: null,
            startDate: null,
            endDate: null,
          ),
        ).called(1);
      });

      test('deve filtrar por status quando fornecido', () async {
        when(
          () => controller.listSessions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: null,
            appointmentId: null,
            status: 'completed',
            startDate: null,
            endDate: null,
          ),
        ).thenAnswer((_) async => []);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/sessions',
          queryParams: {'status': 'completed'},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleListSessions(request);

        expect(response.statusCode, 200);
        verify(
          () => controller.listSessions(
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
            therapistId: 1,
            patientId: null,
            appointmentId: null,
            status: 'completed',
            startDate: null,
            endDate: null,
          ),
        ).called(1);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request('GET', Uri.parse('http://localhost/sessions'));

        final response = await handler.handleListSessions(request);

        expect(response.statusCode, 401);
      });

      test('deve retornar 400 quando therapist sem accountId', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/sessions',
          userId: 1,
          userRole: 'therapist',
          accountId: null,
        );

        final response = await handler.handleListSessions(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('perfil'));
      });

      test('deve retornar 403 quando role não autorizado', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/sessions',
          userId: 1,
          userRole: 'patient',
        );

        final response = await handler.handleListSessions(request);

        expect(response.statusCode, 403);
      });
    });

    group('handleUpdateSession', () {
      test('deve atualizar sessão quando encontrada (200)', () async {
        final updated = sampleSession.copyWith(status: 'completed');
        when(
          () => controller.updateSession(
            sessionId: 1,
            session: any(named: 'session'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => updated);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/sessions/1',
          body: {
            'status': 'completed',
            'patientId': 1,
            'therapistId': 1,
            'scheduledStartTime': sampleSession.scheduledStartTime.toIso8601String(),
            'durationMinutes': 60,
            'sessionNumber': 1,
            'type': 'presential',
            'modality': 'individual',
            'paymentStatus': 'pending',
          },
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleUpdateSession(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['status'], 'completed');
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/sessions/abc',
          body: {'status': 'completed'},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleUpdateSession(request, 'abc');

        expect(response.statusCode, 400);
      });

      test('deve retornar 400 quando corpo vazio', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/sessions/1',
          body: null,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleUpdateSession(request, '1');

        expect(response.statusCode, 400);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/sessions/1'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': 'completed'}),
        );

        final response = await handler.handleUpdateSession(request, '1');

        expect(response.statusCode, 401);
      });

      test('deve retornar 404 quando sessão não encontrada', () async {
        when(
          () => controller.updateSession(
            sessionId: 999,
            session: any(named: 'session'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(SessionException('Sessão não encontrada', 404));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/sessions/999',
          body: {
            'status': 'completed',
            'patientId': 1,
            'therapistId': 1,
            'scheduledStartTime': DateTime.now().toIso8601String(),
            'durationMinutes': 60,
          },
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleUpdateSession(request, '999');

        expect(response.statusCode, 404);
      });
    });

    group('handleDeleteSession', () {
      test('deve deletar sessão quando encontrada (200)', () async {
        when(
          () => controller.deleteSession(
            sessionId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async {});

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/sessions/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleDeleteSession(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['message'], contains('removida'));
      });

      test('deve retornar 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/sessions/abc',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleDeleteSession(request, 'abc');

        expect(response.statusCode, 400);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request('DELETE', Uri.parse('http://localhost/sessions/1'));

        final response = await handler.handleDeleteSession(request, '1');

        expect(response.statusCode, 401);
      });

      test('deve retornar 404 quando sessão não encontrada', () async {
        when(
          () => controller.deleteSession(
            sessionId: 999,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(SessionException('Sessão não encontrada', 404));

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/sessions/999',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleDeleteSession(request, '999');

        expect(response.statusCode, 404);
      });
    });

    group('handleGetNextSessionNumber', () {
      test('deve retornar próximo número quando patientId fornecido (200)', () async {
        when(
          () => controller.getNextSessionNumber(
            patientId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => 5);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/sessions/next-number',
          queryParams: {'patientId': '1'},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetNextSessionNumber(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['nextNumber'], 5);
      });

      test('deve retornar 400 quando patientId não fornecido', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/sessions/next-number',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetNextSessionNumber(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('patientId'));
      });

      test('deve retornar 400 quando patientId inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/sessions/next-number',
          queryParams: {'patientId': 'abc'},
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetNextSessionNumber(request);

        expect(response.statusCode, 400);
      });

      test('deve retornar 401 quando não autenticado', () async {
        final request = Request('GET', Uri.parse('http://localhost/sessions/next-number?patientId=1'));

        final response = await handler.handleGetNextSessionNumber(request);

        expect(response.statusCode, 401);
      });
    });
  });
}

