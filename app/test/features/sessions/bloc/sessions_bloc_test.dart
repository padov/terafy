import 'package:bloc_test/bloc_test.dart';
import 'package:common/common.dart' as common;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/core/domain/usecases/schedule/get_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/update_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/session/create_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/delete_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_sessions_usecase.dart';
import 'package:terafy/core/domain/usecases/session/update_session_usecase.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc_models.dart';
import 'package:terafy/features/sessions/models/session.dart' as ui;

class _MockGetSessionsUseCase extends Mock implements GetSessionsUseCase {}

class _MockGetSessionUseCase extends Mock implements GetSessionUseCase {}

class _MockCreateSessionUseCase extends Mock implements CreateSessionUseCase {}

class _MockUpdateSessionUseCase extends Mock implements UpdateSessionUseCase {}

class _MockDeleteSessionUseCase extends Mock implements DeleteSessionUseCase {}

class _MockGetAppointmentUseCase extends Mock implements GetAppointmentUseCase {}

class _MockUpdateAppointmentUseCase extends Mock implements UpdateAppointmentUseCase {}

void main() {
  group('SessionsBloc', () {
    late _MockGetSessionsUseCase getSessionsUseCase;
    late _MockGetSessionUseCase getSessionUseCase;
    late _MockCreateSessionUseCase createSessionUseCase;
    late _MockUpdateSessionUseCase updateSessionUseCase;
    late _MockDeleteSessionUseCase deleteSessionUseCase;
    late _MockGetAppointmentUseCase getAppointmentUseCase;
    late _MockUpdateAppointmentUseCase updateAppointmentUseCase;
    late SessionsBloc bloc;

    setUp(() {
      getSessionsUseCase = _MockGetSessionsUseCase();
      getSessionUseCase = _MockGetSessionUseCase();
      createSessionUseCase = _MockCreateSessionUseCase();
      updateSessionUseCase = _MockUpdateSessionUseCase();
      deleteSessionUseCase = _MockDeleteSessionUseCase();
      getAppointmentUseCase = _MockGetAppointmentUseCase();
      updateAppointmentUseCase = _MockUpdateAppointmentUseCase();
      bloc = SessionsBloc(
        getSessionsUseCase: getSessionsUseCase,
        getSessionUseCase: getSessionUseCase,
        createSessionUseCase: createSessionUseCase,
        updateSessionUseCase: updateSessionUseCase,
        deleteSessionUseCase: deleteSessionUseCase,
        getAppointmentUseCase: getAppointmentUseCase,
        updateAppointmentUseCase: updateAppointmentUseCase,
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
        when(() => getSessionsUseCase(patientId: any(named: 'patientId'))).thenAnswer((_) async => [
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
                paymentStatus: 'pending',
              ),
            ]);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadPatientSessions('1')),
      expect: () => [
        SessionsLoading(),
        isA<SessionsLoaded>(),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'emite SessionsError quando LoadPatientSessions com ID inválido',
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadPatientSessions('invalid')),
      expect: () => [
        SessionsLoading(),
        SessionsError('ID do paciente inválido'),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'emite SessionDetailsLoaded quando LoadSessionDetails é adicionado',
      build: () {
        when(() => getSessionUseCase(any())).thenAnswer((_) async => common.Session(
              id: 1,
              patientId: 1,
              therapistId: 1,
              scheduledStartTime: DateTime.now(),
              durationMinutes: 60,
              sessionNumber: 1,
              type: 'therapy',
              modality: 'online',
              status: 'scheduled',
              paymentStatus: 'pending',
            ));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSessionDetails('1')),
      expect: () => [
        SessionsLoading(),
        isA<SessionDetailsLoaded>(),
      ],
    );

    blocTest<SessionsBloc, SessionsState>(
      'emite SessionCreated quando CreateSession é adicionado',
      build: () {
        when(() => createSessionUseCase(any())).thenAnswer((_) async => common.Session(
              id: 1,
              patientId: 1,
              therapistId: 1,
              scheduledStartTime: DateTime.now(),
              durationMinutes: 60,
              sessionNumber: 1,
              type: 'therapy',
              modality: 'online',
              status: 'scheduled',
              paymentStatus: 'pending',
            ));
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
            paymentStatus: ui.PaymentStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ),
      expect: () => [
        SessionsLoading(),
        isA<SessionCreated>(),
      ],
    );
  });
}

