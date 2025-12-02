import 'package:common/common.dart';
import 'package:mocktail/mocktail.dart';
import 'package:server/features/patient/patient.controller.dart';
import 'package:server/features/patient/patient.repository.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

class _MockPatientRepository extends Mock implements PatientRepository {}

// Classe mock que implementa ServerException do postgres
// ServerException do postgres estende PgException e tem várias propriedades
// Implementamos todos os getters necessários
class _MockServerException implements ServerException {
  final String _message;
  final String _code;

  _MockServerException(this._message, this._code);

  @override
  String get message => _message;
  @override
  String get code => _code;
  @override
  String? get detail => null;
  @override
  String? get hint => null;
  String? get where => null;
  @override
  String? get schemaName => null;
  @override
  String? get tableName => null;
  @override
  String? get columnName => null;
  @override
  String? get constraintName => null;
  @override
  String? get dataTypeName => null;
  @override
  Severity get severity => Severity.error;
  @override
  String? get fileName => null;
  @override
  int? get lineNumber => null;
  String? get routineName => null;
  @override
  int? get internalPosition => null;
  @override
  String? get internalQuery => null;
  int? get position => null;
  String? get routine => null;
  String? get trace => null;

  @override
  String toString() => _message;
}

void main() {
  setUpAll(() {
    registerFallbackValue(Patient(therapistId: 1, fullName: 'Fallback'));
  });

  late _MockPatientRepository repository;
  late PatientController controller;

  final samplePatient = Patient(id: 1, therapistId: 10, fullName: 'Paciente de Teste', email: 'paciente@teste.com');

  setUp(() {
    repository = _MockPatientRepository();
    controller = PatientController(repository);
  });

  group('PatientController', () {
    test('listPatients delega chamada ao repositório', () async {
      when(
        () => repository.getPatients(therapistId: 5, userId: 1, userRole: 'therapist', accountId: 5, bypassRLS: false),
      ).thenAnswer((_) async => [samplePatient]);

      final result = await controller.listPatients(userId: 1, userRole: 'therapist', therapistId: 5, accountId: 5);

      expect(result, hasLength(1));
      expect(result.first.fullName, equals(samplePatient.fullName));

      verify(
        () => repository.getPatients(therapistId: 5, userId: 1, userRole: 'therapist', accountId: 5, bypassRLS: false),
      ).called(1);
    });

    test('getPatientById retorna paciente quando encontrado', () async {
      when(
        () => repository.getPatientById(7, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
      ).thenAnswer((_) async => samplePatient);

      final patient = await controller.getPatientById(
        7,
        userId: 2,
        userRole: 'admin',
        accountId: null,
        bypassRLS: true,
      );

      expect(patient.id, equals(samplePatient.id));

      verify(
        () => repository.getPatientById(7, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
      ).called(1);
    });

    test('getPatientById lança PatientException quando não encontrado', () {
      when(
        () => repository.getPatientById(99, userId: 3, userRole: 'therapist', accountId: 10, bypassRLS: false),
      ).thenAnswer((_) async => null);

      expect(
        () => controller.getPatientById(99, userId: 3, userRole: 'therapist', accountId: 10),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 404)),
      );
    });

    test('createPatient retorna paciente criado', () async {
      when(
        () => repository.createPatient(any(), userId: 5, userRole: 'therapist', accountId: 10, bypassRLS: false),
      ).thenAnswer((invocation) async => samplePatient);

      final result = await controller.createPatient(
        patient: samplePatient,
        userId: 5,
        userRole: 'therapist',
        accountId: 10,
      );

      expect(result.fullName, equals(samplePatient.fullName));

      verify(
        () => repository.createPatient(any(), userId: 5, userRole: 'therapist', accountId: 10, bypassRLS: false),
      ).called(1);
    });

    test('updatePatient lança exceção quando não encontrado', () async {
      when(
        () => repository.updatePatient(77, any(), userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
      ).thenAnswer((_) async => null);

      await expectLater(
        () => controller.updatePatient(77, patient: samplePatient, userId: 1, userRole: 'therapist', accountId: 10),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 404)),
      );
    });

    test('deletePatient lança exceção quando delete retorna false', () async {
      when(
        () => repository.deletePatient(88, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
      ).thenAnswer((_) async => false);

      await expectLater(
        () => controller.deletePatient(88, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 404)),
      );
    });

    test('listPatients trata exceções do repository', () async {
      when(
        () =>
            repository.getPatients(therapistId: null, userId: 1, userRole: 'therapist', accountId: 5, bypassRLS: false),
      ).thenThrow(Exception('Erro de conexão'));

      expect(
        () => controller.listPatients(userId: 1, userRole: 'therapist', therapistId: null, accountId: 5),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 500)),
      );
    });

    test('getPatientById trata exceções do repository', () async {
      when(
        () => repository.getPatientById(7, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
      ).thenThrow(Exception('Erro de conexão'));

      expect(
        () => controller.getPatientById(7, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 500)),
      );
    });

    test('getPatientById re-lança PatientException', () async {
      when(
        () => repository.getPatientById(7, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
      ).thenThrow(PatientException('Erro customizado', 400));

      expect(
        () => controller.getPatientById(7, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 400)),
      );
    });

    test('createPatient trata CPF duplicado (ServerException code 23505)', () async {
      when(
        () => repository.createPatient(any(), userId: 5, userRole: 'therapist', accountId: 10, bypassRLS: false),
      ).thenThrow(_MockServerException('CPF já cadastrado', '23505'));

      expect(
        () => controller.createPatient(patient: samplePatient, userId: 5, userRole: 'therapist', accountId: 10),
        throwsA(
          isA<PatientException>()
              .having((e) => e.statusCode, 'status', 409)
              .having((e) => e.message, 'message', contains('CPF já cadastrado')),
        ),
      );
    });

    test('createPatient trata outras ServerException', () async {
      when(
        () => repository.createPatient(any(), userId: 5, userRole: 'therapist', accountId: 10, bypassRLS: false),
      ).thenThrow(_MockServerException('Erro de constraint', '23503'));

      expect(
        () => controller.createPatient(patient: samplePatient, userId: 5, userRole: 'therapist', accountId: 10),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 500)),
      );
    });

    test('createPatient trata exceções genéricas', () async {
      when(
        () => repository.createPatient(any(), userId: 5, userRole: 'therapist', accountId: 10, bypassRLS: false),
      ).thenThrow(Exception('Erro genérico'));

      expect(
        () => controller.createPatient(patient: samplePatient, userId: 5, userRole: 'therapist', accountId: 10),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 500)),
      );
    });

    test('updatePatient trata CPF duplicado (ServerException code 23505)', () async {
      when(
        () => repository.updatePatient(77, any(), userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
      ).thenThrow(_MockServerException('CPF já cadastrado', '23505'));

      await expectLater(
        () => controller.updatePatient(77, patient: samplePatient, userId: 1, userRole: 'therapist', accountId: 10),
        throwsA(
          isA<PatientException>()
              .having((e) => e.statusCode, 'status', 409)
              .having((e) => e.message, 'message', contains('CPF já cadastrado')),
        ),
      );
    });

    test('updatePatient trata outras ServerException', () async {
      when(
        () => repository.updatePatient(77, any(), userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
      ).thenThrow(_MockServerException('Erro de constraint', '23503'));

      await expectLater(
        () => controller.updatePatient(77, patient: samplePatient, userId: 1, userRole: 'therapist', accountId: 10),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 500)),
      );
    });

    test('updatePatient trata exceções genéricas', () async {
      when(
        () => repository.updatePatient(77, any(), userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
      ).thenThrow(Exception('Erro genérico'));

      await expectLater(
        () => controller.updatePatient(77, patient: samplePatient, userId: 1, userRole: 'therapist', accountId: 10),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 500)),
      );
    });

    test('updatePatient re-lança PatientException', () async {
      when(
        () => repository.updatePatient(77, any(), userId: 1, userRole: 'therapist', accountId: 10, bypassRLS: false),
      ).thenThrow(PatientException('Erro customizado', 400));

      await expectLater(
        () => controller.updatePatient(77, patient: samplePatient, userId: 1, userRole: 'therapist', accountId: 10),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 400)),
      );
    });

    test('deletePatient trata exceções do repository', () async {
      when(
        () => repository.deletePatient(88, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
      ).thenThrow(Exception('Erro de conexão'));

      await expectLater(
        () => controller.deletePatient(88, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 500)),
      );
    });

    test('deletePatient re-lança PatientException', () async {
      when(
        () => repository.deletePatient(88, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
      ).thenThrow(PatientException('Erro customizado', 400));

      await expectLater(
        () => controller.deletePatient(88, userId: 2, userRole: 'admin', accountId: null, bypassRLS: true),
        throwsA(isA<PatientException>().having((e) => e.statusCode, 'status', 400)),
      );
    });
  });
}
