import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terafy/features/home/widgets/stats_cards.dart';

void main() {
  group('StatsCards', () {
    testWidgets('renderiza todos os cards de estatísticas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCards(
              todayPatients: 5,
              pendingAppointments: 3,
              monthlyRevenue: 1500.0,
              completionRate: 85,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se os valores são exibidos
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.textContaining('1.500'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('renderiza ícones corretos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCards(
              todayPatients: 5,
              pendingAppointments: 3,
              monthlyRevenue: 1500.0,
              completionRate: 85,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se os ícones estão presentes
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('formata valores monetários corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCards(
              todayPatients: 0,
              pendingAppointments: 0,
              monthlyRevenue: 1234.56,
              completionRate: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se o valor monetário está formatado
      expect(find.textContaining('1.234'), findsOneWidget);
    });
  });
}

