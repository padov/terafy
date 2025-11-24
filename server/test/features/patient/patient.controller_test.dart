import 'package:common/common.dart';
import 'package:mocktail/mocktail.dart';
import 'package:server/features/patient/patient.controller.dart';
import 'package:server/features/patient/patient.repository.dart';
import 'package:test/test.dart';

class _MockPatientRepository extends Mock implements PatientRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Patient(therapistId: 1, fullName: 'Fallback'));
  });

  late _MockPatientRepository repository;
  late PatientController controller;

  final samplePatient = Patient(
    id: 1,
    therapistId: 10,
    fullName: 'Paciente de Teste',
    email: 'paciente@teste.com',
  );

  setUp(() {
    repository = _MockPatientRepository();
    controller = PatientController(repository);
  });

  group('PatientController', () {
    test('listPatients delega chamada ao repositório', () async {
      when(
        () => repository.getPatients(
          therapistId: 5,
          userId: 1,
          userRole: 'therapist',
          accountId: 5,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => [samplePatient]);

      final result = await controller.listPatients(
        userId: 1,
        userRole: 'therapist',
        therapistId: 5,
        accountId: 5,
      );

      expect(result, hasLength(1));
      expect(result.first.fullName, equals(samplePatient.fullName));

      verify(
        () => repository.getPatients(
          therapistId: 5,
          userId: 1,
          userRole: 'therapist',
          accountId: 5,
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('getPatientById retorna paciente quando encontrado', () async {
      when(
        () => repository.getPatientById(
          7,
          userId: 2,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
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
        () => repository.getPatientById(
          7,
          userId: 2,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).called(1);
    });

    test('getPatientById lança PatientException quando não encontrado', () {
      when(
        () => repository.getPatientById(
          99,
          userId: 3,
          userRole: 'therapist',
          accountId: 10,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      expect(
        () => controller.getPatientById(
          99,
          userId: 3,
          userRole: 'therapist',
          accountId: 10,
        ),
        throwsA(
          isA<PatientException>().having((e) => e.statusCode, 'status', 404),
        ),
      );
    });

    test('createPatient retorna paciente criado', () async {
      when(
        () => repository.createPatient(
          any(),
          userId: 5,
          userRole: 'therapist',
          accountId: 10,
          bypassRLS: false,
        ),
      ).thenAnswer((invocation) async => samplePatient);

      final result = await controller.createPatient(
        patient: samplePatient,
        userId: 5,
        userRole: 'therapist',
        accountId: 10,
      );

      expect(result.fullName, equals(samplePatient.fullName));

      verify(
        () => repository.createPatient(
          any(),
          userId: 5,
          userRole: 'therapist',
          accountId: 10,
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('updatePatient lança exceção quando não encontrado', () async {
      when(
        () => repository.updatePatient(
          77,
          any(),
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      await expectLater(
        () => controller.updatePatient(
          77,
          patient: samplePatient,
          userId: 1,
          userRole: 'therapist',
          accountId: 10,
        ),
        throwsA(
          isA<PatientException>().having((e) => e.statusCode, 'status', 404),
        ),
      );
    });

    test('deletePatient lança exceção quando delete retorna false', () async {
      when(
        () => repository.deletePatient(
          88,
          userId: 2,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
      ).thenAnswer((_) async => false);

      await expectLater(
        () => controller.deletePatient(
          88,
          userId: 2,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        ),
        throwsA(
          isA<PatientException>().having((e) => e.statusCode, 'status', 404),
        ),
      );
    });
  });
}
