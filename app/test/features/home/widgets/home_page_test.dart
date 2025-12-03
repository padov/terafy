import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:terafy/features/home/bloc/home_bloc.dart';
import 'package:terafy/features/home/bloc/home_bloc_models.dart';
import 'package:terafy/features/home/home_page.dart';

class _MockHomeBloc extends Mock implements HomeBloc {}

class FakeHomeEvent extends Fake implements HomeEvent {}

void main() {
  late _MockHomeBloc mockHomeBloc;

  setUpAll(() {
    registerFallbackValue(FakeHomeEvent());
  });

  setUp(() {
    mockHomeBloc = _MockHomeBloc();
    when(() => mockHomeBloc.close()).thenAnswer((_) async {});
  });

  Widget createHomePage() {
    return MaterialApp(
      home: BlocProvider<HomeBloc>.value(value: mockHomeBloc, child: const HomePage()),
    );
  }

  group('HomePage', () {
    testWidgets('renderiza CircularProgressIndicator em estado loading', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(const HomeLoading(currentNavIndex: 0));
      when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createHomePage());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renderiza mensagem de erro em estado error', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(const HomeError(currentNavIndex: 0, message: 'Erro ao carregar dados'));
      when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createHomePage());
      await tester.pump();

      expect(find.text('Erro ao carregar dados'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renderiza botão de tentar novamente em estado error', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(const HomeError(currentNavIndex: 0, message: 'Erro ao carregar dados'));
      when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockHomeBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(createHomePage());
      await tester.pump();

      final retryButton = find.byType(ElevatedButton);
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pump();

      verify(() => mockHomeBloc.add(const LoadHomeData())).called(1);
    });

    testWidgets('renderiza conteúdo em estado loaded', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(
        const HomeLoaded(
          currentNavIndex: 0,
          data: HomeData(
            userName: 'Dr. João Silva',
            userRole: 'Terapeuta',
            stats: DailyStats(todayPatients: 5, pendingAppointments: 3, monthlyRevenue: 1500.0, completionRate: 85),
            todayAppointments: [],
            reminders: [],
            recentPatients: [],
          ),
        ),
      );
      when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      expect(find.text('Dr. João Silva'), findsOneWidget);
      expect(find.text('Terapeuta'), findsOneWidget);
    });

    testWidgets('renderiza bottom navigation bar', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(
        const HomeLoaded(
          currentNavIndex: 0,
          data: HomeData(
            userName: 'Dr. João Silva',
            userRole: 'Terapeuta',
            stats: DailyStats(todayPatients: 5, pendingAppointments: 3, monthlyRevenue: 1500.0, completionRate: 85),
            todayAppointments: [],
            reminders: [],
            recentPatients: [],
          ),
        ),
      );
      when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('bottom navigation tem 5 itens', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(
        const HomeLoaded(
          currentNavIndex: 0,
          data: HomeData(
            userName: 'Dr. João Silva',
            userRole: 'Terapeuta',
            stats: DailyStats(todayPatients: 5, pendingAppointments: 3, monthlyRevenue: 1500.0, completionRate: 85),
            todayAppointments: [],
            reminders: [],
            recentPatients: [],
          ),
        ),
      );
      when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.items.length, 5);
    });

    testWidgets('altera índice ao clicar em item do bottom navigation', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(
        const HomeLoaded(
          currentNavIndex: 0,
          data: HomeData(
            userName: 'Dr. João Silva',
            userRole: 'Terapeuta',
            stats: DailyStats(todayPatients: 5, pendingAppointments: 3, monthlyRevenue: 1500.0, completionRate: 85),
            todayAppointments: [],
            reminders: [],
            recentPatients: [],
          ),
        ),
      );
      when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockHomeBloc.add(any())).thenReturn(null);

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      // Tenta clicar no segundo item (índice 1)
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pump();

      verify(() => mockHomeBloc.add(const ChangeBottomNavIndex(1))).called(1);
    });

    testWidgets('exibe FloatingActionButton', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(
        const HomeLoaded(
          currentNavIndex: 0,
          data: HomeData(
            userName: 'Dr. João Silva',
            userRole: 'Terapeuta',
            stats: DailyStats(todayPatients: 5, pendingAppointments: 3, monthlyRevenue: 1500.0, completionRate: 85),
            todayAppointments: [],
            reminders: [],
            recentPatients: [],
          ),
        ),
      );
      when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renderiza stats cards com dados corretos', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(
        const HomeLoaded(
          currentNavIndex: 0,
          data: HomeData(
            userName: 'Dr. João Silva',
            userRole: 'Terapeuta',
            stats: DailyStats(todayPatients: 5, pendingAppointments: 3, monthlyRevenue: 1500.0, completionRate: 85),
            todayAppointments: [],
            reminders: [],
            recentPatients: [],
          ),
        ),
      );
      when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('renderiza agenda vazia quando não há compromissos', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(
        const HomeLoaded(
          currentNavIndex: 0,
          data: HomeData(
            userName: 'Dr. João Silva',
            userRole: 'Terapeuta',
            stats: DailyStats(todayPatients: 0, pendingAppointments: 0, monthlyRevenue: 0.0, completionRate: 0),
            todayAppointments: [],
            reminders: [],
            recentPatients: [],
          ),
        ),
      );
      when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.event_available), findsOneWidget);
    });

    testWidgets('renderiza sessões pendentes vazias quando não há sessões', (tester) async {
      when(() => mockHomeBloc.state).thenReturn(
        const HomeLoaded(
          currentNavIndex: 0,
          data: HomeData(
            userName: 'Dr. João Silva',
            userRole: 'Terapeuta',
            stats: DailyStats(todayPatients: 0, pendingAppointments: 0, monthlyRevenue: 0.0, completionRate: 0),
            todayAppointments: [],
            reminders: [],
            recentPatients: [],
            pendingSessions: [],
          ),
        ),
      );
      when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createHomePage());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma sessão pendente'), findsOneWidget);
    });
  });
}
