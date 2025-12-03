import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/features/home/bloc/home_bloc_models.dart';
import 'package:terafy/features/home/widgets/home_header.dart';

class _MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  group('HomeHeader', () {
    testWidgets('renderiza avatar com iniciais quando não há foto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
            ),
          ),
        ),
      );

      // Verifica se as iniciais estão presentes
      expect(find.text('JS'), findsOneWidget);
    });

    testWidgets('renderiza iniciais com nome único', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'Maria',
              userRole: 'Terapeuta',
            ),
          ),
        ),
      );

      expect(find.text('M'), findsOneWidget);
    });

    testWidgets('renderiza nome e role do usuário', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'Dr. João Silva',
              userRole: 'Terapeuta',
            ),
          ),
        ),
      );

      expect(find.text('Dr. João Silva'), findsOneWidget);
      expect(find.text('Terapeuta'), findsOneWidget);
    });

    testWidgets('exibe badge do plano Free', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
              plan: const TherapistPlan(
                id: 0,
                name: 'Free',
                price: 0.0,
                patientLimit: 5,
              ),
            ),
          ),
        ),
      );

      expect(find.text('FREE'), findsOneWidget);
    });

    testWidgets('exibe badge do plano Premium', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
              plan: const TherapistPlan(
                id: 1,
                name: 'Premium',
                price: 99.0,
                patientLimit: 50,
              ),
            ),
          ),
        ),
      );

      expect(find.text('PREMIUM'), findsOneWidget);
    });

    testWidgets('não exibe badge quando não há plano', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
            ),
          ),
        ),
      );

      expect(find.text('FREE'), findsNothing);
      expect(find.text('PREMIUM'), findsNothing);
    });

    testWidgets('exibe contador de notificações quando maior que zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
              notificationCount: 5,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('exibe 9+ quando notificações são maiores que 9', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
              notificationCount: 15,
            ),
          ),
        ),
      );

      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('não exibe contador quando notificações são zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
              notificationCount: 0,
            ),
          ),
        ),
      );

      // O badge não deve estar visível
      expect(find.text('0'), findsNothing);
    });

    testWidgets('chama callback ao clicar no sino de notificações', (tester) async {
      var notificationTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
              onNotificationTap: () {
                notificationTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(notificationTapped, true);
    });

    testWidgets('abre menu popup ao clicar no avatar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
            ),
          ),
        ),
      );

      // Clica no avatar
      await tester.tap(find.text('JS'));
      await tester.pumpAndSettle();

      // Verifica se o menu apareceu
      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('exibe ícones corretos no menu popup', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
            ),
          ),
        ),
      );

      await tester.tap(find.text('JS'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('exibe dialog de confirmação ao clicar em Sair', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
            ),
          ),
        ),
      );

      // Abre o menu
      await tester.tap(find.text('JS'));
      await tester.pumpAndSettle();

      // Clica em Sair
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      // Verifica se o dialog apareceu
      expect(find.text('Tem certeza que deseja sair?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('fecha dialog ao clicar em Cancelar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              userName: 'João Silva',
              userRole: 'Terapeuta',
            ),
          ),
        ),
      );

      // Abre o menu e clica em Sair
      await tester.tap(find.text('JS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      // Clica em Cancelar
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Dialog deve ter fechado
      expect(find.text('Tem certeza que deseja sair?'), findsNothing);
    });
  });
}
