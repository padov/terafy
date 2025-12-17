import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terafy/features/financial/reports/widgets/revenue_chart.dart';

void main() {
  group('RevenueChart', () {
    testWidgets('renderiza gráfico de receita corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevenueChart(
              summary: {
                'data': [
                  {'date': '2024-01', 'value': 1000.0},
                  {'date': '2024-02', 'value': 1500.0},
                ],
              },
              period: 'monthly',
              selectedDate: DateTime.now(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se há um Container (gráfico)
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renderiza com dados vazios', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RevenueChart(
              summary: {'data': []},
              period: 'monthly',
              selectedDate: DateTime.now(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se o widget renderiza sem erros
      expect(find.byType(Container), findsWidgets);
    });
  });
}

