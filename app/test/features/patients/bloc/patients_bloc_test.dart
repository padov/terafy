import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/core/domain/usecases/patient/create_patient_usecase.dart';
import 'package:terafy/core/domain/usecases/patient/get_patient_usecase.dart';
import 'package:terafy/core/domain/usecases/patient/get_patients_usecase.dart';
import 'package:terafy/core/domain/usecases/patient/update_patient_usecase.dart';
import 'package:terafy/core/services/patients_cache_service.dart';
import 'package:terafy/features/patients/bloc/patients_bloc.dart';
import 'package:terafy/features/patients/bloc/patients_bloc_models.dart';
import 'package:terafy/features/patients/models/patient.dart';

class _MockGetPatientsUseCase extends Mock implements GetPatientsUseCase {}

class _MockCreatePatientUseCase extends Mock implements CreatePatientUseCase {}

class _MockGetPatientUseCase extends Mock implements GetPatientUseCase {}

class _MockUpdatePatientUseCase extends Mock implements UpdatePatientUseCase {}

class _MockPatientsCacheService extends Mock implements PatientsCacheService {}

void main() {
  group('PatientsBloc', () {
    late _MockGetPatientsUseCase getPatientsUseCase;
    late _MockCreatePatientUseCase createPatientUseCase;
    late _MockGetPatientUseCase getPatientUseCase;
    late _MockUpdatePatientUseCase updatePatientUseCase;
    late _MockPatientsCacheService patientsCacheService;
    late PatientsBloc bloc;

    setUp(() {
      getPatientsUseCase = _MockGetPatientsUseCase();
      createPatientUseCase = _MockCreatePatientUseCase();
      getPatientUseCase = _MockGetPatientUseCase();
      updatePatientUseCase = _MockUpdatePatientUseCase();
      patientsCacheService = _MockPatientsCacheService();
      bloc = PatientsBloc(
        getPatientsUseCase: getPatientsUseCase,
        createPatientUseCase: createPatientUseCase,
        getPatientUseCase: getPatientUseCase,
        updatePatientUseCase: updatePatientUseCase,
        patientsCacheService: patientsCacheService,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('estado inicial é PatientsInitial', () {
      expect(bloc.state, const PatientsInitial());
    });

    blocTest<PatientsBloc, PatientsState>(
      'emite PatientsLoaded quando LoadPatients é adicionado com sucesso',
      build: () {
        when(() => patientsCacheService.getPatients()).thenReturn(null);
        when(() => getPatientsUseCase()).thenAnswer((_) async => [
              Patient(
                id: '1',
                therapistId: '1',
                fullName: 'Paciente Teste',
                phone: '11999999999',
                status: PatientStatus.active,
                totalSessions: 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ]);
        when(() => patientsCacheService.savePatients(any())).thenReturn({});
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadPatients()),
      expect: () => [
        const PatientsLoading(),
        isA<PatientsLoaded>(),
      ],
    );

    blocTest<PatientsBloc, PatientsState>(
      'emite PatientsError quando LoadPatients falha',
      build: () {
        when(() => patientsCacheService.getPatients()).thenReturn(null);
        when(() => getPatientsUseCase()).thenThrow(Exception('Erro ao carregar'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadPatients()),
      expect: () => [
        const PatientsLoading(),
        isA<PatientsError>(),
      ],
    );

    blocTest<PatientsBloc, PatientsState>(
      'filtra pacientes quando SearchPatients é adicionado',
      build: () => bloc,
      seed: () {
        final now = DateTime.now();
        return PatientsLoaded(
          patients: [
            Patient(
              id: '1',
              therapistId: '1',
              fullName: 'João Silva',
              phone: '11999999999',
              status: PatientStatus.active,
              totalSessions: 0,
              createdAt: now,
              updatedAt: now,
            ),
            Patient(
              id: '2',
              therapistId: '1',
              fullName: 'Maria Santos',
              phone: '11888888888',
              status: PatientStatus.active,
              totalSessions: 0,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          filteredPatients: [
            Patient(
              id: '1',
              therapistId: '1',
              fullName: 'João Silva',
              phone: '11999999999',
              status: PatientStatus.active,
              totalSessions: 0,
              createdAt: now,
              updatedAt: now,
            ),
            Patient(
              id: '2',
              therapistId: '1',
              fullName: 'Maria Santos',
              phone: '11888888888',
              status: PatientStatus.active,
              totalSessions: 0,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );
      },
      act: (bloc) => bloc.add(const SearchPatients('João')),
      expect: () => [
        isA<PatientsLoaded>(),
      ],
      verify: (bloc) {
        final state = bloc.state as PatientsLoaded;
        expect(state.filteredPatients.length, 1);
        expect(state.filteredPatients.first.fullName, 'João Silva');
      },
    );

    blocTest<PatientsBloc, PatientsState>(
      'filtra pacientes por status quando FilterPatientsByStatus é adicionado',
      build: () => bloc,
      seed: () {
        final now = DateTime.now();
        return PatientsLoaded(
          patients: [
            Patient(
              id: '1',
              therapistId: '1',
              fullName: 'João Silva',
              phone: '11999999999',
              status: PatientStatus.active,
              totalSessions: 0,
              createdAt: now,
              updatedAt: now,
            ),
            Patient(
              id: '2',
              therapistId: '1',
              fullName: 'Maria Santos',
              phone: '11888888888',
              status: PatientStatus.inactive,
              totalSessions: 0,
              createdAt: now,
              updatedAt: now,
            ),
          ],
          filteredPatients: [
            Patient(
              id: '1',
              therapistId: '1',
              fullName: 'João Silva',
              phone: '11999999999',
              status: PatientStatus.active,
              totalSessions: 0,
              createdAt: now,
              updatedAt: now,
            ),
            Patient(
              id: '2',
              therapistId: '1',
              fullName: 'Maria Santos',
              phone: '11888888888',
              status: PatientStatus.inactive,
              totalSessions: 0,
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );
      },
      act: (bloc) => bloc.add(const FilterPatientsByStatus(PatientStatus.active)),
      expect: () => [
        isA<PatientsLoaded>(),
      ],
      verify: (bloc) {
        final state = bloc.state as PatientsLoaded;
        expect(state.filteredPatients.every((p) => p.status == PatientStatus.active), isTrue);
      },
    );

    blocTest<PatientsBloc, PatientsState>(
      'emite PatientAdded quando AddQuickPatient é adicionado com sucesso',
      build: () {
        when(() => createPatientUseCase(
              fullName: any(named: 'fullName'),
              phone: any(named: 'phone'),
              email: any(named: 'email'),
              birthDate: any(named: 'birthDate'),
            )).thenAnswer((_) async => Patient(
              id: '1',
              therapistId: '1',
              fullName: 'Novo Paciente',
              phone: '11999999999',
              status: PatientStatus.active,
              totalSessions: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const AddQuickPatient(
          fullName: 'Novo Paciente',
          phone: '11999999999',
        ),
      ),
      expect: () => [
        const PatientAdding(),
        isA<PatientAdded>(),
      ],
    );

    blocTest<PatientsBloc, PatientsState>(
      'emite PatientSelected quando SelectPatient é adicionado',
      build: () {
        when(() => getPatientUseCase(any())).thenAnswer((_) async => Patient(
              id: '1',
              therapistId: '1',
              fullName: 'Paciente Selecionado',
              phone: '11999999999',
              status: PatientStatus.active,
              totalSessions: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
        return bloc;
      },
      act: (bloc) => bloc.add(const SelectPatient('1')),
      expect: () => [
        isA<PatientSelected>(),
      ],
    );
  });
}

