import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/core/domain/usecases/schedule/create_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/get_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/get_appointments_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/update_appointment_usecase.dart';
import 'package:terafy/core/domain/usecases/session/create_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_next_session_number_usecase.dart';
import 'package:terafy/core/domain/usecases/session/get_session_usecase.dart';
import 'package:terafy/core/domain/usecases/session/update_session_usecase.dart';
import 'package:terafy/features/agenda/bloc/agenda_bloc.dart';
import 'package:terafy/features/agenda/bloc/agenda_bloc_models.dart';

class _MockGetAppointmentsUseCase extends Mock implements GetAppointmentsUseCase {}

class _MockGetAppointmentUseCase extends Mock implements GetAppointmentUseCase {}

class _MockCreateAppointmentUseCase extends Mock implements CreateAppointmentUseCase {}

class _MockUpdateAppointmentUseCase extends Mock implements UpdateAppointmentUseCase {}

class _MockCreateSessionUseCase extends Mock implements CreateSessionUseCase {}

class _MockGetNextSessionNumberUseCase extends Mock implements GetNextSessionNumberUseCase {}

class _MockGetSessionUseCase extends Mock implements GetSessionUseCase {}

class _MockUpdateSessionUseCase extends Mock implements UpdateSessionUseCase {}

void main() {
  group('AgendaBloc', () {
    late _MockGetAppointmentsUseCase getAppointmentsUseCase;
    late _MockGetAppointmentUseCase getAppointmentUseCase;
    late _MockCreateAppointmentUseCase createAppointmentUseCase;
    late _MockUpdateAppointmentUseCase updateAppointmentUseCase;
    late _MockCreateSessionUseCase createSessionUseCase;
    late _MockGetNextSessionNumberUseCase getNextSessionNumberUseCase;
    late _MockGetSessionUseCase getSessionUseCase;
    late _MockUpdateSessionUseCase updateSessionUseCase;
    late AgendaBloc bloc;

    setUp(() {
      getAppointmentsUseCase = _MockGetAppointmentsUseCase();
      getAppointmentUseCase = _MockGetAppointmentUseCase();
      createAppointmentUseCase = _MockCreateAppointmentUseCase();
      updateAppointmentUseCase = _MockUpdateAppointmentUseCase();
      createSessionUseCase = _MockCreateSessionUseCase();
      getNextSessionNumberUseCase = _MockGetNextSessionNumberUseCase();
      getSessionUseCase = _MockGetSessionUseCase();
      updateSessionUseCase = _MockUpdateSessionUseCase();
      bloc = AgendaBloc(
        getAppointmentsUseCase: getAppointmentsUseCase,
        getAppointmentUseCase: getAppointmentUseCase,
        createAppointmentUseCase: createAppointmentUseCase,
        updateAppointmentUseCase: updateAppointmentUseCase,
        createSessionUseCase: createSessionUseCase,
        getNextSessionNumberUseCase: getNextSessionNumberUseCase,
        getSessionUseCase: getSessionUseCase,
        updateSessionUseCase: updateSessionUseCase,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('estado inicial é AgendaInitial', () {
      expect(bloc.state, const AgendaInitial());
    });

    blocTest<AgendaBloc, AgendaState>(
      'emite AgendaLoaded quando LoadAgenda é adicionado',
      build: () {
        when(() => getAppointmentsUseCase(
              start: any(named: 'start'),
              end: any(named: 'end'),
            )).thenAnswer((_) async => []);
        return bloc;
      },
      act: (bloc) => bloc.add(
        LoadAgenda(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 7)),
        ),
      ),
      expect: () => [
        const AgendaLoading(),
        isA<AgendaLoaded>(),
      ],
    );

    blocTest<AgendaBloc, AgendaState>(
      'emite AgendaError quando LoadAgenda falha',
      build: () {
        when(() => getAppointmentsUseCase(
              start: any(named: 'start'),
              end: any(named: 'end'),
            )).thenThrow(Exception('Erro'));
        return bloc;
      },
      act: (bloc) => bloc.add(
        LoadAgenda(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 7)),
        ),
      ),
      expect: () => [
        const AgendaLoading(),
        isA<AgendaError>(),
      ],
    );
  });
}

