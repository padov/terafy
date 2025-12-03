import 'dart:convert';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:common/common.dart';
import 'package:server/features/schedule/schedule.handler.dart';
import 'package:server/features/schedule/schedule.controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduleController extends Mock implements ScheduleController {}

void main() {
  setUpAll(() {
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
    registerFallbackValue(
      Appointment(
        therapistId: 1,
        type: 'session',
        status: 'reserved',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
  });

  group('ScheduleHandler', () {
    late _MockScheduleController controller;
    late ScheduleHandler handler;

    setUp(() {
      controller = _MockScheduleController();
      handler = ScheduleHandler(controller);
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

    final sampleAppointment = Appointment(
      id: 1,
      therapistId: 1,
      patientId: 1,
      type: 'session',
      status: 'reserved',
      startTime: DateTime(2024, 1, 15, 10, 0),
      endTime: DateTime(2024, 1, 15, 11, 0),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    group('handleGetSettings', () {
      test('retorna configurações quando therapist autenticado (200)', () async {
        when(
          () => controller.getOrCreateSettings(
            therapistId: 1,
            userId: 1,
            userRole: 'therapist',
          ),
        ).thenAnswer((_) async => sampleSettings);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetSettings(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['therapistId'], 1);
        expect(data['sessionDurationMinutes'], 50);
      });

      test('retorna configurações quando admin autenticado com therapistId (200)', () async {
        when(
          () => controller.getOrCreateSettings(
            therapistId: 5,
            userId: 1,
            userRole: 'admin',
          ),
        ).thenAnswer((_) async => sampleSettings.copyWith(therapistId: 5));

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'admin',
          queryParams: {'therapistId': '5'},
        );

        final response = await handler.handleGetSettings(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['therapistId'], 5);
      });

      test('cria configurações padrão quando não existem (200)', () async {
        final defaultSettings = TherapistScheduleSettings(
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
        );

        when(
          () => controller.getOrCreateSettings(
            therapistId: 1,
            userId: 1,
            userRole: 'therapist',
          ),
        ).thenAnswer((_) async => defaultSettings);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetSettings(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['sessionDurationMinutes'], 50);
      });

      test('retorna 401 sem autenticação', () async {
        final request = Request('GET', Uri.parse('http://localhost/schedule/settings'));

        final response = await handler.handleGetSettings(request);

        expect(response.statusCode, 401);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Autenticação'));
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'therapist',
          accountId: null,
        );

        final response = await handler.handleGetSettings(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Conta de terapeuta não vinculada'));
      });

      test('retorna 400 quando admin sem therapistId', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleGetSettings(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('therapistId'));
      });

      test('retorna 403 quando role não autorizado', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'patient',
        );

        final response = await handler.handleGetSettings(request);

        expect(response.statusCode, 403);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Somente terapeutas ou administradores'));
      });

      test('retorna 400 quando therapistId inválido (admin)', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'admin',
          queryParams: {'therapistId': 'invalid'},
        );

        final response = await handler.handleGetSettings(request);

        expect(response.statusCode, 400);
      });

      test('trata exceções do controller corretamente', () async {
        when(
          () => controller.getOrCreateSettings(
            therapistId: 1,
            userId: 1,
            userRole: 'therapist',
          ),
        ).thenThrow(ScheduleException('Erro ao carregar configurações', 500));

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetSettings(request);

        expect(response.statusCode, 500);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Erro ao carregar configurações'));
      });
    });

    group('handleUpdateSettings', () {
      test('atualiza configurações quando therapist autenticado (200)', () async {
        final updatedSettings = sampleSettings.copyWith(sessionDurationMinutes: 60);

        when(
          () => controller.updateSettings(
            settings: any(named: 'settings'),
            userId: 1,
            userRole: 'therapist',
          ),
        ).thenAnswer((_) async => updatedSettings);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          body: {
            'sessionDurationMinutes': 60,
          },
        );

        final response = await handler.handleUpdateSettings(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['sessionDurationMinutes'], 60);
      });

      test('atualiza configurações quando admin autenticado (200)', () async {
        final updatedSettings = sampleSettings.copyWith(therapistId: 5, sessionDurationMinutes: 60);

        when(
          () => controller.updateSettings(
            settings: any(named: 'settings'),
            userId: 1,
            userRole: 'admin',
          ),
        ).thenAnswer((_) async => updatedSettings);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'admin',
          body: {
            'therapistId': 5,
            'sessionDurationMinutes': 60,
          },
        );

        final response = await handler.handleUpdateSettings(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['therapistId'], 5);
      });

      test('retorna 401 sem autenticação', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/schedule/settings'),
          body: jsonEncode({'sessionDurationMinutes': 60}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.handleUpdateSettings(request);

        expect(response.statusCode, 401);
      });

      test('retorna 400 quando body vazio', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/schedule/settings'),
          body: '',
          headers: {'Content-Type': 'application/json', 'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await handler.handleUpdateSettings(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('não pode ser vazio'));
      });

      test('retorna 400 quando JSON inválido', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/schedule/settings'),
          body: 'invalid json',
          headers: {'Content-Type': 'application/json', 'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await handler.handleUpdateSettings(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'therapist',
          accountId: null,
          body: {'sessionDurationMinutes': 60},
        );

        final response = await handler.handleUpdateSettings(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Conta de terapeuta não vinculada'));
      });

      test('retorna 400 quando admin sem therapistId', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'admin',
          body: {'sessionDurationMinutes': 60},
        );

        final response = await handler.handleUpdateSettings(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('therapistId'));
      });

      test('retorna 403 quando role não autorizado', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'patient',
          body: {'sessionDurationMinutes': 60},
        );

        final response = await handler.handleUpdateSettings(request);

        expect(response.statusCode, 403);
      });

      test('retorna 400 quando therapistId inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'admin',
          body: {'therapistId': 'invalid'},
        );

        final response = await handler.handleUpdateSettings(request);

        expect(response.statusCode, 400);
      });

      test('trata exceções do controller corretamente', () async {
        when(
          () => controller.updateSettings(
            settings: any(named: 'settings'),
            userId: 1,
            userRole: 'therapist',
          ),
        ).thenThrow(ScheduleException('Erro ao atualizar', 500));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/settings',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          body: {'sessionDurationMinutes': 60},
        );

        final response = await handler.handleUpdateSettings(request);

        expect(response.statusCode, 500);
      });
    });

    group('handleListAppointments', () {
      test('lista agendamentos quando therapist autenticado (200)', () async {
        when(
          () => controller.listAppointments(
            therapistId: 1,
            start: any(named: 'start'),
            end: any(named: 'end'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => [sampleAppointment]);

        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          queryParams: {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        );

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as List;
        expect(data.length, 1);
      });

      test('lista agendamentos quando admin autenticado (200)', () async {
        when(
          () => controller.listAppointments(
            therapistId: 5,
            start: any(named: 'start'),
            end: any(named: 'end'),
            userId: 1,
            userRole: 'admin',
            accountId: null,
          ),
        ).thenAnswer((_) async => [sampleAppointment]);

        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'admin',
          queryParams: {
            'therapistId': '5',
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        );

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 200);
      });

      test('filtra por intervalo de datas corretamente', () async {
        when(
          () => controller.listAppointments(
            therapistId: 1,
            start: any(named: 'start'),
            end: any(named: 'end'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => []);

        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          queryParams: {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        );

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 200);
        verify(
          () => controller.listAppointments(
            therapistId: 1,
            start: start,
            end: end,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).called(1);
      });

      test('retorna 401 sem autenticação', () async {
        final request = Request('GET', Uri.parse('http://localhost/schedule/appointments'));

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 401);
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: null,
          queryParams: {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        );

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando admin sem therapistId', () async {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'admin',
          queryParams: {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        );

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando start/end não fornecidos', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('start e end são obrigatórios'));
      });

      test('retorna 400 quando start/end inválidos', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          queryParams: {
            'start': 'invalid',
            'end': 'invalid',
          },
        );

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando end não é após start', () async {
        final start = DateTime(2024, 1, 31);
        final end = DateTime(2024, 1, 1);
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          queryParams: {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        );

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Intervalo de datas inválido'));
      });

      test('retorna 403 quando role não autorizado', () async {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'patient',
          queryParams: {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        );

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 403);
      });

      test('retorna lista vazia quando não há agendamentos', () async {
        when(
          () => controller.listAppointments(
            therapistId: 1,
            start: any(named: 'start'),
            end: any(named: 'end'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => []);

        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          queryParams: {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        );

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as List;
        expect(data, isEmpty);
      });

      test('trata exceções do controller corretamente', () async {
        when(
          () => controller.listAppointments(
            therapistId: 1,
            start: any(named: 'start'),
            end: any(named: 'end'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(ScheduleException('Erro ao listar', 500));

        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          queryParams: {
            'start': start.toIso8601String(),
            'end': end.toIso8601String(),
          },
        );

        final response = await handler.handleListAppointments(request);

        expect(response.statusCode, 500);
      });
    });

    group('handleGetAppointment', () {
      test('retorna agendamento existente quando therapist (200)', () async {
        when(
          () => controller.getAppointment(
            appointmentId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => sampleAppointment);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetAppointment(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], 1);
      });

      test('retorna agendamento existente quando admin (200)', () async {
        when(
          () => controller.getAppointment(
            appointmentId: 1,
            userId: 1,
            userRole: 'admin',
            accountId: null,
          ),
        ).thenAnswer((_) async => sampleAppointment);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleGetAppointment(request, '1');

        expect(response.statusCode, 200);
      });

      test('retorna 401 sem autenticação', () async {
        final request = Request('GET', Uri.parse('http://localhost/schedule/appointments/1'));

        final response = await handler.handleGetAppointment(request, '1');

        expect(response.statusCode, 401);
      });

      test('retorna 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments/abc',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetAppointment(request, 'abc');

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('ID inválido'));
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'therapist',
          accountId: null,
        );

        final response = await handler.handleGetAppointment(request, '1');

        expect(response.statusCode, 400);
      });

      test('retorna 404 quando agendamento não existe', () async {
        when(
          () => controller.getAppointment(
            appointmentId: 999,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(ScheduleException('Agendamento não encontrado', 404));

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments/999',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetAppointment(request, '999');

        expect(response.statusCode, 404);
      });

      test('therapist só acessa seus agendamentos (404)', () async {
        when(
          () => controller.getAppointment(
            appointmentId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(ScheduleException('Agendamento não encontrado', 404));

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetAppointment(request, '1');

        expect(response.statusCode, 404);
      });

      test('admin acessa qualquer agendamento (200)', () async {
        when(
          () => controller.getAppointment(
            appointmentId: 1,
            userId: 1,
            userRole: 'admin',
            accountId: null,
          ),
        ).thenAnswer((_) async => sampleAppointment);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleGetAppointment(request, '1');

        expect(response.statusCode, 200);
      });

      test('trata exceções do controller corretamente', () async {
        when(
          () => controller.getAppointment(
            appointmentId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(ScheduleException('Erro ao buscar', 500));

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleGetAppointment(request, '1');

        expect(response.statusCode, 500);
      });
    });

    group('handleCreateAppointment', () {
      test('cria agendamento quando therapist autenticado (201)', () async {
        when(
          () => controller.createAppointment(
            appointment: any(named: 'appointment'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => sampleAppointment);

        final startTime = DateTime(2024, 1, 15, 10, 0);
        final endTime = DateTime(2024, 1, 15, 11, 0);
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          body: {
            'patientId': 1,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
        );

        final response = await handler.handleCreateAppointment(request);

        expect(response.statusCode, 201);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], 1);
      });

      test('cria agendamento quando admin autenticado (201)', () async {
        when(
          () => controller.createAppointment(
            appointment: any(named: 'appointment'),
            userId: 1,
            userRole: 'admin',
            accountId: null,
          ),
        ).thenAnswer((_) async => sampleAppointment);

        final startTime = DateTime(2024, 1, 15, 10, 0);
        final endTime = DateTime(2024, 1, 15, 11, 0);
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'admin',
          body: {
            'therapistId': 5,
            'patientId': 1,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
        );

        final response = await handler.handleCreateAppointment(request);

        expect(response.statusCode, 201);
      });

      test('retorna 401 sem autenticação', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/schedule/appointments'),
          body: jsonEncode({'patientId': 1}),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.handleCreateAppointment(request);

        expect(response.statusCode, 401);
      });

      test('retorna 400 quando body vazio', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/schedule/appointments'),
          body: '',
          headers: {'Content-Type': 'application/json', 'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await handler.handleCreateAppointment(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('não pode ser vazio'));
      });

      test('retorna 400 quando JSON inválido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/schedule/appointments'),
          body: 'invalid json',
          headers: {'Content-Type': 'application/json', 'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await handler.handleCreateAppointment(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: null,
          body: {'patientId': 1},
        );

        final response = await handler.handleCreateAppointment(request);

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando admin sem therapistId', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'admin',
          body: {'patientId': 1},
        );

        final response = await handler.handleCreateAppointment(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('therapistId'));
      });

      test('retorna 403 quando role não autorizado', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'patient',
          body: {'patientId': 1},
        );

        final response = await handler.handleCreateAppointment(request);

        expect(response.statusCode, 403);
      });

      test('retorna 400 quando therapistId inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'admin',
          body: {'therapistId': 'invalid'},
        );

        final response = await handler.handleCreateAppointment(request);

        expect(response.statusCode, 400);
      });

      test('retorna 409 quando há conflito de horário', () async {
        when(
          () => controller.createAppointment(
            appointment: any(named: 'appointment'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(ScheduleException('Este horário já está ocupado', 409));

        final startTime = DateTime(2024, 1, 15, 10, 0);
        final endTime = DateTime(2024, 1, 15, 11, 0);
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          body: {
            'patientId': 1,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
        );

        final response = await handler.handleCreateAppointment(request);

        expect(response.statusCode, 409);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('horário já está ocupado'));
      });

      test('trata exceções do controller corretamente', () async {
        when(
          () => controller.createAppointment(
            appointment: any(named: 'appointment'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(ScheduleException('Erro ao criar', 500));

        final startTime = DateTime(2024, 1, 15, 10, 0);
        final endTime = DateTime(2024, 1, 15, 11, 0);
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/schedule/appointments',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          body: {
            'patientId': 1,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'type': 'session',
            'status': 'reserved',
          },
        );

        final response = await handler.handleCreateAppointment(request);

        expect(response.statusCode, 500);
      });
    });

    group('handleUpdateAppointment', () {
      test('atualiza agendamento existente quando therapist (200)', () async {
        final updated = sampleAppointment.copyWith(status: 'confirmed');

        when(
          () => controller.updateAppointment(
            appointmentId: 1,
            appointment: any(named: 'appointment'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => updated);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          body: {
            'status': 'confirmed',
            'startTime': sampleAppointment.startTime.toIso8601String(),
            'endTime': sampleAppointment.endTime.toIso8601String(),
          },
        );

        final response = await handler.handleUpdateAppointment(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['status'], 'confirmed');
      });

      test('atualiza agendamento existente quando admin (200)', () async {
        final updated = sampleAppointment.copyWith(status: 'confirmed');

        when(
          () => controller.updateAppointment(
            appointmentId: 1,
            appointment: any(named: 'appointment'),
            userId: 1,
            userRole: 'admin',
            accountId: null,
          ),
        ).thenAnswer((_) async => updated);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'admin',
          body: {
            'therapistId': 5,
            'status': 'confirmed',
            'startTime': sampleAppointment.startTime.toIso8601String(),
            'endTime': sampleAppointment.endTime.toIso8601String(),
          },
        );

        final response = await handler.handleUpdateAppointment(request, '1');

        expect(response.statusCode, 200);
      });

      test('retorna 401 sem autenticação', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/schedule/appointments/1'),
          body: jsonEncode({
            'status': 'confirmed',
            'startTime': sampleAppointment.startTime.toIso8601String(),
            'endTime': sampleAppointment.endTime.toIso8601String(),
          }),
          headers: {'Content-Type': 'application/json'},
        );

        final response = await handler.handleUpdateAppointment(request, '1');

        expect(response.statusCode, 401);
      });

      test('retorna 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/appointments/abc',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          body: {
            'status': 'confirmed',
            'startTime': sampleAppointment.startTime.toIso8601String(),
            'endTime': sampleAppointment.endTime.toIso8601String(),
          },
        );

        final response = await handler.handleUpdateAppointment(request, 'abc');

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando body vazio', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/schedule/appointments/1'),
          body: '',
          headers: {'Content-Type': 'application/json', 'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await handler.handleUpdateAppointment(request, '1');

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando JSON inválido', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/schedule/appointments/1'),
          body: 'invalid json',
          headers: {'Content-Type': 'application/json', 'x-user-id': '1', 'x-user-role': 'therapist', 'x-account-id': '1'},
        );

        final response = await handler.handleUpdateAppointment(request, '1');

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando therapist sem accountId', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'therapist',
          accountId: null,
          body: {
            'status': 'confirmed',
            'startTime': sampleAppointment.startTime.toIso8601String(),
            'endTime': sampleAppointment.endTime.toIso8601String(),
          },
        );

        final response = await handler.handleUpdateAppointment(request, '1');

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando admin sem therapistId', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'admin',
          body: {
            'status': 'confirmed',
            'startTime': sampleAppointment.startTime.toIso8601String(),
            'endTime': sampleAppointment.endTime.toIso8601String(),
          },
        );

        final response = await handler.handleUpdateAppointment(request, '1');

        expect(response.statusCode, 400);
      });

      test('retorna 404 quando agendamento não existe', () async {
        when(
          () => controller.updateAppointment(
            appointmentId: 999,
            appointment: any(named: 'appointment'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(ScheduleException('Agendamento não encontrado', 404));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/appointments/999',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          body: {
            'status': 'confirmed',
            'startTime': sampleAppointment.startTime.toIso8601String(),
            'endTime': sampleAppointment.endTime.toIso8601String(),
          },
        );

        final response = await handler.handleUpdateAppointment(request, '999');

        expect(response.statusCode, 404);
      });

      test('retorna 409 quando há conflito de horário', () async {
        when(
          () => controller.updateAppointment(
            appointmentId: 1,
            appointment: any(named: 'appointment'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(ScheduleException('Este horário já está ocupado', 409));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          body: {
            'status': 'confirmed',
            'startTime': sampleAppointment.startTime.toIso8601String(),
            'endTime': sampleAppointment.endTime.toIso8601String(),
          },
        );

        final response = await handler.handleUpdateAppointment(request, '1');

        expect(response.statusCode, 409);
      });

      test('trata exceções do controller corretamente', () async {
        when(
          () => controller.updateAppointment(
            appointmentId: 1,
            appointment: any(named: 'appointment'),
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(ScheduleException('Erro ao atualizar', 500));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          body: {
            'status': 'confirmed',
            'startTime': sampleAppointment.startTime.toIso8601String(),
            'endTime': sampleAppointment.endTime.toIso8601String(),
          },
        );

        final response = await handler.handleUpdateAppointment(request, '1');

        expect(response.statusCode, 500);
      });
    });

    group('handleDeleteAppointment', () {
      test('remove agendamento existente quando therapist (200)', () async {
        when(
          () => controller.deleteAppointment(
            appointmentId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenAnswer((_) async => {});

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleDeleteAppointment(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['message'], contains('removido com sucesso'));
      });

      test('remove agendamento existente quando admin (200)', () async {
        when(
          () => controller.deleteAppointment(
            appointmentId: 1,
            userId: 1,
            userRole: 'admin',
            accountId: null,
          ),
        ).thenAnswer((_) async => {});

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'admin',
        );

        final response = await handler.handleDeleteAppointment(request, '1');

        expect(response.statusCode, 200);
      });

      test('retorna 401 sem autenticação', () async {
        final request = Request('DELETE', Uri.parse('http://localhost/schedule/appointments/1'));

        final response = await handler.handleDeleteAppointment(request, '1');

        expect(response.statusCode, 401);
      });

      test('retorna 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/schedule/appointments/abc',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleDeleteAppointment(request, 'abc');

        expect(response.statusCode, 400);
      });

      test('retorna 404 quando agendamento não existe', () async {
        when(
          () => controller.deleteAppointment(
            appointmentId: 999,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(ScheduleException('Agendamento não encontrado', 404));

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/schedule/appointments/999',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleDeleteAppointment(request, '999');

        expect(response.statusCode, 404);
      });

      test('trata exceções do controller corretamente', () async {
        when(
          () => controller.deleteAppointment(
            appointmentId: 1,
            userId: 1,
            userRole: 'therapist',
            accountId: 1,
          ),
        ).thenThrow(ScheduleException('Erro ao remover', 500));

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/schedule/appointments/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        );

        final response = await handler.handleDeleteAppointment(request, '1');

        expect(response.statusCode, 500);
      });
    });
  });
}

