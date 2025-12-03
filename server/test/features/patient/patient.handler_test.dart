import 'dart:convert';

import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:common/common.dart';
import 'package:server/features/patient/patient.handler.dart';
import 'package:server/features/patient/patient.controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockPatientController extends Mock implements PatientController {}

void main() {
  setUpAll(() {
    registerFallbackValue(Patient(therapistId: 1, fullName: 'Fallback'));
  });

  group('PatientHandler', () {
    late _MockPatientController controller;
    late PatientHandler handler;

    setUp(() {
      controller = _MockPatientController();
      handler = PatientHandler(controller);
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
    }) {
      final uri = Uri.parse('http://localhost$path');
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'x-user-id': (userId ?? 1).toString(),
        'x-user-role': userRole ?? 'therapist',
        if (accountId != null) 'x-account-id': accountId.toString(),
        ...?headers,
      };

      return Request(method, uri, body: body != null ? jsonEncode(body) : null, headers: defaultHeaders);
    }

    final samplePatient = Patient(
      id: 1,
      therapistId: 10,
      fullName: 'Paciente Teste',
      email: 'teste@test.com',
      status: 'active',
    );

    group('handleList', () {
      test('retorna lista de pacientes (200)', () async {
        when(
          () => controller.listPatients(
            userId: 1,
            userRole: 'therapist',
            therapistId: 10,
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenAnswer((_) async => [samplePatient]);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/patients',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleList(request);

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as List;
        expect(data.length, equals(1));
        expect(data[0]['id'], equals(1));
      });

      test('retorna 401 quando não autenticado (userId null)', () async {
        final request = Request('GET', Uri.parse('http://localhost/patients'));

        final response = await handler.handleList(request);

        expect(response.statusCode, 401);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Autenticação'));
      });

      test('retorna 401 quando role null', () async {
        final request = Request('GET', Uri.parse('http://localhost/patients'), headers: {'x-user-id': '1'});

        final response = await handler.handleList(request);

        expect(response.statusCode, 401);
      });

      test('therapist sem accountId retorna 400', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/patients',
          userId: 1,
          userRole: 'therapist',
          accountId: null,
        );

        final response = await handler.handleList(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Conta de terapeuta não vinculada'));
      });

      test('admin pode filtrar por therapistId (query param)', () async {
        when(
          () => controller.listPatients(userId: 1, userRole: 'admin', therapistId: 5, accountId: null, bypassRLS: true),
        ).thenAnswer((_) async => [samplePatient]);

        final request = Request(
          'GET',
          Uri.parse('http://localhost/patients?therapistId=5'),
          headers: {'x-user-id': '1', 'x-user-role': 'admin'},
        );

        final response = await handler.handleList(request);

        expect(response.statusCode, 200);
        verify(
          () => controller.listPatients(userId: 1, userRole: 'admin', therapistId: 5, accountId: null, bypassRLS: true),
        ).called(1);
      });

      test('admin com therapistId inválido retorna 400', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/patients?therapistId=invalid'),
          headers: {'x-user-id': '1', 'x-user-role': 'admin'},
        );

        final response = await handler.handleList(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('therapistId inválido'));
      });

      test('trata PatientException do controller', () async {
        when(
          () => controller.listPatients(
            userId: 1,
            userRole: 'therapist',
            therapistId: 10,
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenThrow(PatientException('Erro ao listar', 500));

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/patients',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleList(request);

        expect(response.statusCode, 500);
      });

      test('trata exceções genéricas (500)', () async {
        when(
          () => controller.listPatients(
            userId: 1,
            userRole: 'therapist',
            therapistId: 10,
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenThrow(Exception('Erro genérico'));

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/patients',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleList(request);

        expect(response.statusCode, 500);
      });
    });

    group('handleGetById', () {
      test('retorna paciente encontrado (200)', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenAnswer((_) async => samplePatient);

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/patients/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleGetById(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], equals(1));
      });

      test('retorna 400 quando ID inválido (não numérico)', () async {
        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/patients/abc',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleGetById(request, 'abc');

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('ID inválido'));
      });

      test('retorna 401 quando não autenticado', () async {
        final request = Request('GET', Uri.parse('http://localhost/patients/1'));

        final response = await handler.handleGetById(request, '1');

        expect(response.statusCode, 401);
      });

      test('retorna 404 quando paciente não encontrado', () async {
        when(
          () => controller.getPatientById(999, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenThrow(PatientException('Paciente não encontrado', 404));

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/patients/999',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleGetById(request, '999');

        expect(response.statusCode, 404);
      });

      test('trata PatientException do controller', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenThrow(PatientException('Erro ao buscar', 500));

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/patients/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleGetById(request, '1');

        expect(response.statusCode, 500);
      });

      test('trata exceções genéricas (500)', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenThrow(Exception('Erro genérico'));

        final request = createAuthenticatedRequest(
          method: 'GET',
          path: '/patients/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleGetById(request, '1');

        expect(response.statusCode, 500);
      });
    });

    group('handleCreate', () {
      test('cria paciente com sucesso (201)', () async {
        when(
          () => controller.createPatient(
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenAnswer((_) async => samplePatient);

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Paciente Novo', 'email': 'novo@test.com', 'therapistId': 10},
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 201);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['id'], equals(1));
      });

      test('retorna 401 quando não autenticado', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients'),
          body: jsonEncode({'fullName': 'Teste'}),
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 401);
      });

      test('retorna 400 quando body vazio', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients'),
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '10',
          },
          body: '',
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('JSON inválido ou corpo da requisição vazio'));
      });

      test('retorna 400 quando JSON inválido', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/patients'),
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '10',
          },
          body: 'invalid json',
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 400);
      });

      test('therapist sem accountId retorna 400', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Teste'},
          userId: 1,
          userRole: 'therapist',
          accountId: null,
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Conta de terapeuta não vinculada'));
      });

      test('role diferente de therapist/admin retorna 403', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Teste'},
          userId: 1,
          userRole: 'patient',
          accountId: null,
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 403);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('Apenas terapeutas ou administradores'));
      });

      test('retorna 400 quando therapistId não fornecido (admin)', () async {
        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Teste'},
          userId: 1,
          userRole: 'admin',
          accountId: null,
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 400);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['error'], contains('therapistId'));
      });

      test('retorna 409 quando CPF duplicado', () async {
        when(
          () => controller.createPatient(
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenThrow(PatientException('CPF já cadastrado', 409));

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Teste', 'cpf': '12345678900', 'therapistId': 10},
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 409);
      });

      test('parse aceita snake_case e camelCase', () async {
        when(
          () => controller.createPatient(
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenAnswer((_) async => samplePatient);

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/patients',
          body: {'full_name': 'Paciente', 'birth_date': '1990-01-01', 'therapist_id': 10},
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 201);
      });

      test('parse correto de campos opcionais (dates, doubles, JSON, arrays)', () async {
        when(
          () => controller.createPatient(
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenAnswer((_) async => samplePatient);

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/patients',
          body: {
            'fullName': 'Paciente',
            'birthDate': '1990-01-01T00:00:00Z',
            'sessionPrice': 150.5,
            'emergencyContact': {'name': 'Contato', 'phone': '11999999999'},
            'phones': ['11999999999', '11888888888'],
            'therapistId': 10,
          },
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 201);
      });

      test('trata PatientException do controller', () async {
        when(
          () => controller.createPatient(
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenThrow(PatientException('Erro ao criar', 500));

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Teste', 'therapistId': 10},
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 500);
      });

      test('trata exceções genéricas (500)', () async {
        when(
          () => controller.createPatient(
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenThrow(Exception('Erro genérico'));

        final request = createAuthenticatedRequest(
          method: 'POST',
          path: '/patients',
          body: {'fullName': 'Teste', 'therapistId': 10},
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleCreate(request);

        expect(response.statusCode, 500);
      });
    });

    group('handleUpdate', () {
      test('atualiza paciente com sucesso (200)', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenAnswer((_) async => samplePatient);

        when(
          () => controller.updatePatient(
            1,
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenAnswer((_) async => samplePatient.copyWith(fullName: 'Atualizado'));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/patients/1',
          body: {'fullName': 'Atualizado'},
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 200);
      });

      test('retorna 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/patients/abc',
          body: {'fullName': 'Teste'},
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleUpdate(request, 'abc');

        expect(response.statusCode, 400);
      });

      test('retorna 401 quando não autenticado', () async {
        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/1'),
          body: jsonEncode({'fullName': 'Teste'}),
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 401);
      });

      test('retorna 400 quando body vazio', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenAnswer((_) async => samplePatient);

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/1'),
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '10',
          },
          body: '',
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 400);
      });

      test('retorna 400 quando JSON inválido', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenAnswer((_) async => samplePatient);

        final request = Request(
          'PUT',
          Uri.parse('http://localhost/patients/1'),
          headers: {
            'Content-Type': 'application/json',
            'x-user-id': '1',
            'x-user-role': 'therapist',
            'x-account-id': '10',
          },
          body: 'invalid json',
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 400);
      });

      test('therapist sem accountId retorna 400', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: null, bypassRLS: false),
        ).thenAnswer((_) async => samplePatient);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/patients/1',
          body: {'fullName': 'Teste'},
          userId: 1,
          userRole: 'therapist',
          accountId: null,
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 400);
      });

      test('admin pode alterar therapistId', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'admin', accountId: null, bypassRLS: true),
        ).thenAnswer((_) async => samplePatient);

        when(
          () => controller.updatePatient(
            1,
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'admin',
            accountId: 5,
            bypassRLS: true,
          ),
        ).thenAnswer((_) async => samplePatient);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/patients/1',
          body: {'therapistId': 5},
          userId: 1,
          userRole: 'admin',
          accountId: null,
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 200);
        verify(
          () => controller.updatePatient(
            1,
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'admin',
            accountId: 5,
            bypassRLS: true,
          ),
        ).called(1);
      });

      test('therapist não pode alterar therapistId (usa accountId)', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenAnswer((_) async => samplePatient);

        when(
          () => controller.updatePatient(
            1,
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenAnswer((_) async => samplePatient);

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/patients/1',
          body: {'therapistId': 999}, // Tentativa de alterar
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 200);
        // Verifica que usa accountId, não o therapistId do body
        verify(
          () => controller.updatePatient(
            1,
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10, // accountId, não 999
            bypassRLS: false,
          ),
        ).called(1);
      });

      test('retorna 404 quando paciente não existe', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenThrow(PatientException('Paciente não encontrado', 404));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/patients/1',
          body: {'fullName': 'Teste'},
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 404);
      });

      test('retorna 409 quando CPF duplicado', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenAnswer((_) async => samplePatient);

        when(
          () => controller.updatePatient(
            1,
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenThrow(PatientException('CPF já cadastrado', 409));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/patients/1',
          body: {'cpf': '12345678900'},
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 409);
      });

      test('trata PatientException do controller', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenAnswer((_) async => samplePatient);

        when(
          () => controller.updatePatient(
            1,
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenThrow(PatientException('Erro ao atualizar', 500));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/patients/1',
          body: {'fullName': 'Teste'},
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 500);
      });

      test('trata exceções genéricas (500)', () async {
        when(
          () => controller.getPatientById(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenAnswer((_) async => samplePatient);

        when(
          () => controller.updatePatient(
            1,
            patient: any(named: 'patient'),
            userId: 1,
            userRole: 'therapist',
            accountId: 10,
            bypassRLS: false,
          ),
        ).thenThrow(Exception('Erro genérico'));

        final request = createAuthenticatedRequest(
          method: 'PUT',
          path: '/patients/1',
          body: {'fullName': 'Teste'},
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleUpdate(request, '1');

        expect(response.statusCode, 500);
      });
    });

    group('handleDelete', () {
      test('remove paciente com sucesso (200)', () async {
        when(
          () => controller.deletePatient(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenAnswer((_) async => Future.value());

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/patients/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleDelete(request, '1');

        expect(response.statusCode, 200);
        final body = await response.readAsString();
        final data = jsonDecode(body) as Map;
        expect(data['message'], contains('removido com sucesso'));
      });

      test('retorna 400 quando ID inválido', () async {
        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/patients/abc',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleDelete(request, 'abc');

        expect(response.statusCode, 400);
      });

      test('retorna 401 quando não autenticado', () async {
        final request = Request('DELETE', Uri.parse('http://localhost/patients/1'));

        final response = await handler.handleDelete(request, '1');

        expect(response.statusCode, 401);
      });

      test('retorna 404 quando paciente não existe', () async {
        when(
          () => controller.deletePatient(999, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenThrow(PatientException('Paciente não encontrado', 404));

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/patients/999',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleDelete(request, '999');

        expect(response.statusCode, 404);
      });

      test('trata PatientException do controller', () async {
        when(
          () => controller.deletePatient(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenThrow(PatientException('Erro ao remover', 500));

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/patients/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleDelete(request, '1');

        expect(response.statusCode, 500);
      });

      test('trata exceções genéricas (500)', () async {
        when(
          () => controller.deletePatient(1, userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
        ).thenThrow(Exception('Erro genérico'));

        final request = createAuthenticatedRequest(
          method: 'DELETE',
          path: '/patients/1',
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        );

        final response = await handler.handleDelete(request, '1');

        expect(response.statusCode, 500);
      });
    });
  });
}
