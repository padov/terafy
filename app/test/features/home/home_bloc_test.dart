import 'package:bloc_test/bloc_test.dart';
import 'package:common/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/core/domain/usecases/home/get_home_summary_usecase.dart';
import 'package:terafy/core/domain/usecases/therapist/get_current_therapist_usecase.dart';
import 'package:terafy/features/home/bloc/home_bloc.dart';
import 'package:terafy/features/home/bloc/home_bloc_models.dart';

class _MockGetCurrentTherapistUseCase extends Mock implements GetCurrentTherapistUseCase {}

class _MockGetHomeSummaryUseCase extends Mock implements GetHomeSummaryUseCase {}

void main() {
  group('HomeBloc', () {
    late _MockGetCurrentTherapistUseCase getCurrentTherapistUseCase;
    late _MockGetHomeSummaryUseCase getHomeSummaryUseCase;
    late HomeBloc bloc;

    setUp(() {
      getCurrentTherapistUseCase = _MockGetCurrentTherapistUseCase();
      getHomeSummaryUseCase = _MockGetHomeSummaryUseCase();
      bloc = HomeBloc(
        getCurrentTherapistUseCase: getCurrentTherapistUseCase,
        getHomeSummaryUseCase: getHomeSummaryUseCase,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('estado inicial é HomeInitial', () {
      expect(bloc.state, const HomeInitial());
      expect(bloc.state.currentNavIndex, 0);
    });

    blocTest<HomeBloc, HomeState>(
      'emite HomeLoading e HomeLoaded quando LoadHomeData é adicionado',
      build: () {
        when(() => getCurrentTherapistUseCase()).thenAnswer((_) async => {
              'name': 'Dr. João Silva',
              'plan': {'id': 1, 'name': 'Premium', 'price': 99.0, 'patient_limit': 50},
            });
        when(() => getHomeSummaryUseCase()).thenAnswer((_) async => HomeSummary(
              referenceDate: DateTime.now(),
              therapistId: 1,
              todayPendingSessions: 2,
              todayConfirmedSessions: 3,
              monthlyCompletionRate: 0.85,
              monthlySessions: 20,
              listOfTodaySessions: [],
              pendingSessions: [],
            ));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadHomeData()),
      expect: () => [
        const HomeLoading(currentNavIndex: 0),
        isA<HomeLoaded>(),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'emite HomeError quando LoadHomeData falha',
      build: () {
        when(() => getCurrentTherapistUseCase()).thenThrow(Exception('Erro ao carregar'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadHomeData()),
      expect: () => [
        const HomeLoading(currentNavIndex: 0),
        isA<HomeError>(),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'atualiza dados quando RefreshHomeData é adicionado',
      build: () {
        when(() => getCurrentTherapistUseCase()).thenAnswer((_) async => {
              'name': 'Dr. João Silva',
              'plan': {'id': 1, 'name': 'Premium', 'price': 99.0, 'patient_limit': 50},
            });
        when(() => getHomeSummaryUseCase()).thenAnswer((_) async => HomeSummary(
              referenceDate: DateTime.now(),
              therapistId: 1,
              todayPendingSessions: 2,
              todayConfirmedSessions: 3,
              monthlyCompletionRate: 0.85,
              monthlySessions: 20,
              listOfTodaySessions: [],
              pendingSessions: [],
            ));
        return bloc;
      },
      seed: () => const HomeLoaded(
        currentNavIndex: 0,
        data: HomeData(
          userName: 'Teste',
          userRole: 'therapist',
          stats: DailyStats(
            todayPatients: 0,
            pendingAppointments: 0,
            monthlyRevenue: 0.0,
            completionRate: 0,
          ),
          todayAppointments: [],
          reminders: [],
          recentPatients: [],
        ),
      ),
      act: (bloc) => bloc.add(const RefreshHomeData()),
      expect: () => [
        isA<HomeLoaded>(),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'atualiza currentNavIndex quando ChangeBottomNavIndex é adicionado',
      build: () => bloc,
      seed: () => const HomeLoaded(
        currentNavIndex: 0,
        data: HomeData(
          userName: 'Teste',
          userRole: 'therapist',
          stats: DailyStats(
            todayPatients: 0,
            pendingAppointments: 0,
            monthlyRevenue: 0.0,
            completionRate: 0,
          ),
          todayAppointments: [],
          reminders: [],
          recentPatients: [],
        ),
      ),
      act: (bloc) => bloc.add(const ChangeBottomNavIndex(2)),
      expect: () => [
        const HomeLoaded(
          currentNavIndex: 2,
          data: HomeData(
            userName: 'Teste',
            userRole: 'therapist',
            stats: DailyStats(
              todayPatients: 0,
              pendingAppointments: 0,
              monthlyRevenue: 0.0,
              completionRate: 0,
            ),
            todayAppointments: [],
            reminders: [],
            recentPatients: [],
          ),
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'não altera estado quando ChangeBottomNavIndex é adicionado em estado não-loaded',
      build: () => bloc,
      seed: () => const HomeInitial(),
      act: (bloc) => bloc.add(const ChangeBottomNavIndex(2)),
      expect: () => [],
    );

    blocTest<HomeBloc, HomeState>(
      'emite HomeError quando RefreshHomeData falha',
      build: () {
        when(() => getCurrentTherapistUseCase()).thenThrow(Exception('Erro ao atualizar'));
        when(() => getHomeSummaryUseCase()).thenThrow(Exception('Erro ao atualizar'));
        return bloc;
      },
      seed: () => const HomeLoaded(
        currentNavIndex: 0,
        data: HomeData(
          userName: 'Teste',
          userRole: 'therapist',
          stats: DailyStats(
            todayPatients: 0,
            pendingAppointments: 0,
            monthlyRevenue: 0.0,
            completionRate: 0,
          ),
          todayAppointments: [],
          reminders: [],
          recentPatients: [],
        ),
      ),
      act: (bloc) => bloc.add(const RefreshHomeData()),
      expect: () => [
        isA<HomeError>().having((e) => e.message, 'message', contains('Erro')),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'mapeia corretamente dados com sessões pendentes',
      build: () {
        when(() => getCurrentTherapistUseCase()).thenAnswer((_) async => {
              'name': 'Dr. João Silva',
              'plan': {'id': 1, 'name': 'Premium', 'price': 99.0, 'patient_limit': 50},
            });
        when(() => getHomeSummaryUseCase()).thenAnswer((_) async => HomeSummary(
              referenceDate: DateTime.now(),
              therapistId: 1,
              todayPendingSessions: 2,
              todayConfirmedSessions: 3,
              monthlyCompletionRate: 0.85,
              monthlySessions: 20,
              listOfTodaySessions: [
                HomeAgendaItem(
                  appointmentId: 1,
                  patientId: 100,
                  patientName: 'Paciente Teste',
                  startTime: DateTime.now(),
                  endTime: DateTime.now().add(const Duration(hours: 1)),
                  type: 'session',
                  status: 'confirmed',
                  title: 'Consulta',
                ),
              ],
              pendingSessions: [
                PendingSession(
                  id: 1,
                  sessionNumber: 5,
                  patientId: 100,
                  patientName: 'Paciente Teste',
                  scheduledStartTime: DateTime.now(),
                  status: 'draft',
                ),
              ],
            ));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadHomeData()),
      expect: () => [
        const HomeLoading(currentNavIndex: 0),
        isA<HomeLoaded>()
            .having((s) => s.data?.pendingSessions.length, 'pendingSessions length', 1)
            .having((s) => s.data?.todayAppointments.length, 'todayAppointments length', 1),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'mapeia corretamente diferentes status de compromisso',
      build: () {
        when(() => getCurrentTherapistUseCase()).thenAnswer((_) async => {
              'name': 'Dr. João Silva',
            });
        when(() => getHomeSummaryUseCase()).thenAnswer((_) async => HomeSummary(
              referenceDate: DateTime.now(),
              therapistId: 1,
              todayPendingSessions: 0,
              todayConfirmedSessions: 4,
              monthlyCompletionRate: 0.85,
              monthlySessions: 20,
              listOfTodaySessions: [
                HomeAgendaItem(
                  appointmentId: 1,
                  patientName: 'Paciente 1',
                  startTime: DateTime.now(),
                  endTime: DateTime.now().add(const Duration(hours: 1)),
                  type: 'session',
                  status: 'reserved',
                ),
                HomeAgendaItem(
                  appointmentId: 2,
                  patientName: 'Paciente 2',
                  startTime: DateTime.now(),
                  endTime: DateTime.now().add(const Duration(hours: 1)),
                  type: 'session',
                  status: 'confirmed',
                ),
                HomeAgendaItem(
                  appointmentId: 3,
                  patientName: 'Paciente 3',
                  startTime: DateTime.now(),
                  endTime: DateTime.now().add(const Duration(hours: 1)),
                  type: 'session',
                  status: 'completed',
                ),
                HomeAgendaItem(
                  appointmentId: 4,
                  patientName: 'Paciente 4',
                  startTime: DateTime.now(),
                  endTime: DateTime.now().add(const Duration(hours: 1)),
                  type: 'session',
                  status: 'cancelled',
                ),
              ],
              pendingSessions: [],
            ));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadHomeData()),
      expect: () => [
        const HomeLoading(currentNavIndex: 0),
        isA<HomeLoaded>().having((s) {
          final appointments = s.data?.todayAppointments ?? [];
          return appointments.length == 4 &&
              appointments[0].status == AppointmentStatus.reserved &&
              appointments[1].status == AppointmentStatus.confirmed &&
              appointments[2].status == AppointmentStatus.completed &&
              appointments[3].status == AppointmentStatus.cancelled;
        }, 'all appointment statuses mapped correctly', true),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'mapeia corretamente diferentes tipos de serviço',
      build: () {
        when(() => getCurrentTherapistUseCase()).thenAnswer((_) async => {
              'name': 'Dr. João Silva',
            });
        when(() => getHomeSummaryUseCase()).thenAnswer((_) async => HomeSummary(
              referenceDate: DateTime.now(),
              therapistId: 1,
              todayPendingSessions: 0,
              todayConfirmedSessions: 3,
              monthlyCompletionRate: 0.85,
              monthlySessions: 20,
              listOfTodaySessions: [
                HomeAgendaItem(
                  appointmentId: 1,
                  patientName: 'Paciente 1',
                  startTime: DateTime.now(),
                  endTime: DateTime.now().add(const Duration(hours: 1)),
                  type: 'session',
                  status: 'confirmed',
                  title: 'Terapia Individual',
                ),
                HomeAgendaItem(
                  appointmentId: 2,
                  patientName: 'Paciente 2',
                  startTime: DateTime.now(),
                  endTime: DateTime.now().add(const Duration(hours: 1)),
                  type: 'personal',
                  status: 'confirmed',
                ),
                HomeAgendaItem(
                  appointmentId: 3,
                  patientName: 'Paciente 3',
                  startTime: DateTime.now(),
                  endTime: DateTime.now().add(const Duration(hours: 1)),
                  type: 'block',
                  status: 'confirmed',
                ),
              ],
              pendingSessions: [],
            ));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadHomeData()),
      expect: () => [
        const HomeLoading(currentNavIndex: 0),
        isA<HomeLoaded>().having((s) {
          final appointments = s.data?.todayAppointments ?? [];
          return appointments.length == 3 &&
              appointments[0].serviceType == 'Terapia Individual' &&
              appointments[1].serviceType == 'Compromisso pessoal' &&
              appointments[2].serviceType == 'Bloqueio de agenda';
        }, 'all service types mapped correctly', true),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'trata corretamente quando therapist não tem plano',
      build: () {
        when(() => getCurrentTherapistUseCase()).thenAnswer((_) async => {
              'name': 'Dr. João Silva',
              // sem plano
            });
        when(() => getHomeSummaryUseCase()).thenAnswer((_) async => HomeSummary(
              referenceDate: DateTime.now(),
              therapistId: 1,
              todayPendingSessions: 0,
              todayConfirmedSessions: 0,
              monthlyCompletionRate: 0.85,
              monthlySessions: 20,
              listOfTodaySessions: [],
              pendingSessions: [],
            ));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadHomeData()),
      expect: () => [
        const HomeLoading(currentNavIndex: 0),
        isA<HomeLoaded>().having(
          (s) => s.data?.plan?.name,
          'default plan name',
          'Free',
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'agrupa corretamente pacientes únicos em recentPatients',
      build: () {
        final now = DateTime.now();
        when(() => getCurrentTherapistUseCase()).thenAnswer((_) async => {
              'name': 'Dr. João Silva',
            });
        when(() => getHomeSummaryUseCase()).thenAnswer((_) async => HomeSummary(
              referenceDate: DateTime.now(),
              therapistId: 1,
              todayPendingSessions: 0,
              todayConfirmedSessions: 3,
              monthlyCompletionRate: 0.85,
              monthlySessions: 20,
              listOfTodaySessions: [
                HomeAgendaItem(
                  appointmentId: 1,
                  patientId: 100,
                  patientName: 'Paciente A',
                  startTime: now,
                  endTime: now.add(const Duration(hours: 1)),
                  type: 'session',
                  status: 'confirmed',
                ),
                HomeAgendaItem(
                  appointmentId: 2,
                  patientId: 100, // mesmo paciente
                  patientName: 'Paciente A',
                  startTime: now.add(const Duration(hours: 1)),
                  endTime: now.add(const Duration(hours: 2)),
                  type: 'session',
                  status: 'confirmed',
                ),
                HomeAgendaItem(
                  appointmentId: 3,
                  patientId: 200,
                  patientName: 'Paciente B',
                  startTime: now.add(const Duration(hours: 2)),
                  endTime: now.add(const Duration(hours: 3)),
                  type: 'session',
                  status: 'confirmed',
                ),
              ],
              pendingSessions: [],
            ));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadHomeData()),
      expect: () => [
        const HomeLoading(currentNavIndex: 0),
        isA<HomeLoaded>().having(
          (s) => s.data?.recentPatients.length,
          'unique patients count',
          2, // apenas 2 pacientes únicos
        ),
      ],
    );
  });
}

