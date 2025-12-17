import 'package:bloc_test/bloc_test.dart';
import 'package:common/common.dart' as common;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/core/domain/usecases/schedule/get_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/update_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/session/create_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_sessions_usecase.dart';
import 'package:terafy/core/domain/usecases/session/update_session_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/get_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/create_transaction_usecase.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc_models.dart';
import 'package:terafy/features/sessions/models/session.dart' as ui;

class _MockGetSessionsUseCase extends Mock implements GetSessionsUseCase {}

class _MockGetSessionUseCase extends Mock implements GetSessionUseCase {}

class _MockCreateSessionUseCase extends Mock implements CreateSessionUseCase {}

class _MockUpdateSessionUseCase extends Mock implements UpdateSessionUseCase {}

class _MockGetAppointmentUseCase extends Mock implements GetAppointmentUseCase {}

class _MockUpdateAppointmentUseCase extends Mock implements UpdateAppointmentUseCase {}

class MockGetTransactionUseCase extends Mock implements GetTransactionUseCase {}

class MockCreateTransactionUseCase extends Mock implements CreateTransactionUseCase {}

void main() {
  group('SessionsBloc', () {
    late SessionsBloc bloc;
    late _MockGetSessionsUseCase getSessionsUseCase;
    late _MockGetSessionUseCase getSessionUseCase;
    late _MockCreateSessionUseCase createSessionUseCase;
    late _MockUpdateSessionUseCase updateSessionUseCase;
    late _MockGetAppointmentUseCase getAppointmentUseCase;
    late _MockUpdateAppointmentUseCase updateAppointmentUseCase;
    late MockGetTransactionUseCase mockGetTransactionUseCase;
    late MockCreateTransactionUseCase mockCreateTransactionUseCase;

    setUp(() {
      registerFallbackValue(
        common.Session(
          id: 0,
          patientId: 0,
          therapistId: 0,
          scheduledStartTime: DateTime.now(),
          durationMinutes: 0,
          sessionNumber: 0,
          type: '',
          modality: '',
          status: '',
        ),
      );
      getSessionsUseCase = _MockGetSessionsUseCase();
      getSessionUseCase = _MockGetSessionUseCase();
      createSessionUseCase = _MockCreateSessionUseCase();
      updateSessionUseCase = _MockUpdateSessionUseCase();
      getAppointmentUseCase = _MockGetAppointmentUseCase();
      updateAppointmentUseCase = _MockUpdateAppointmentUseCase();
      mockGetTransactionUseCase = MockGetTransactionUseCase();
      mockCreateTransactionUseCase = MockCreateTransactionUseCase();
      bloc = SessionsBloc(
        getSessionsUseCase: getSessionsUseCase,
        getSessionUseCase: getSessionUseCase,
        createSessionUseCase: createSessionUseCase,
        updateSessionUseCase: updateSessionUseCase,
        getAppointmentUseCase: getAppointmentUseCase,
        updateAppointmentUseCase: updateAppointmentUseCase,
        getTransactionUseCase: mockGetTransactionUseCase,
        createTransactionUseCase: mockCreateTransactionUseCase,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('estado inicial é SessionsInitial', () {
      expect(bloc.state, SessionsInitial());
    });

    blocTest<SessionsBloc, SessionsState>(
      'emite SessionsLoaded quando LoadPatientSessions é adicionado com sucesso',
      build: () {
        when(() => getSessionsUseCase(patientId: any(named: 'patientId'))).thenAnswer(
          (_) async => [
            common.Session(
              id: 1,
              patientId: 1,
              therapistId: 1,
              scheduledStartTime: DateTime.now(),
              durationMinutes: 60,
              sessionNumber: 1,
              type: 'therapy',
              modality: 'online',
              status: 'scheduled',
              transactionId: null,
            ),
          ],
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadPatientSessions('1')),
      expect: () => [SessionsLoading(), isA<SessionsLoaded>()],
    );

    blocTest<SessionsBloc, SessionsState>(
      'emite SessionsError quando LoadPatientSessions com ID inválido',
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadPatientSessions('invalid')),
      expect: () => [SessionsLoading(), SessionsError('ID do paciente inválido')],
    );

    blocTest<SessionsBloc, SessionsState>(
      'emite SessionDetailsLoaded quando LoadSessionDetails é adicionado',
      build: () {
        when(() => getSessionUseCase(any())).thenAnswer(
          (_) async => common.Session(
            id: 1,
            patientId: 1,
            therapistId: 1,
            scheduledStartTime: DateTime.now(),
            durationMinutes: 60,
            sessionNumber: 1,
            type: 'therapy',
            modality: 'online',
            status: 'scheduled',
            transactionId: null,
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSessionDetails('1')),
      expect: () => [SessionsLoading(), isA<SessionDetailsLoaded>()],
    );

    blocTest<SessionsBloc, SessionsState>(
      'emite SessionCreated quando CreateSession é adicionado',
      build: () {
        when(() => createSessionUseCase(any())).thenAnswer(
          (_) async => common.Session(
            id: 1,
            patientId: 1,
            therapistId: 1,
            scheduledStartTime: DateTime.now(),
            durationMinutes: 60,
            sessionNumber: 1,
            type: 'therapy',
            modality: 'online',
            status: 'scheduled',
            transactionId: null,
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        CreateSession(
          ui.Session(
            id: '0',
            patientId: '1',
            therapistId: '1',
            scheduledStartTime: DateTime.now(),
            durationMinutes: 60,
            sessionNumber: 1,
            type: ui.SessionType.onlineVideo,
            modality: ui.SessionModality.individual,
            status: ui.SessionStatus.scheduled,

            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ),
      expect: () => [SessionsLoading(), isA<SessionCreated>()],
    );
  });
}
