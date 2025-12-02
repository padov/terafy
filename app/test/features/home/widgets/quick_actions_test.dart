import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/features/home/widgets/quick_actions.dart';

void main() {
  group('QuickActions', () {
    testWidgets('renderiza todos os 4 botões de ação', (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('pt', 'BR')],
          path: 'assets/translations',
          fallbackLocale: const Locale('pt', 'BR'),
          child: MaterialApp(
            home: Scaffold(
              body: QuickActions(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se os 4 ícones estão presentes
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('chama callback ao clicar em novo agendamento', (tester) async {
      var newAppointmentTapped = false;

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('pt', 'BR')],
          path: 'assets/translations',
          fallbackLocale: const Locale('pt', 'BR'),
          child: MaterialApp(
            home: Scaffold(
              body: QuickActions(
                onNewAppointment: () {
                  newAppointmentTapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(newAppointmentTapped, true);
    });

    testWidgets('chama callback ao clicar em buscar paciente', (tester) async {
      var searchPatientTapped = false;

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('pt', 'BR')],
          path: 'assets/translations',
          fallbackLocale: const Locale('pt', 'BR'),
          child: MaterialApp(
            home: Scaffold(
              body: QuickActions(
                onSearchPatient: () {
                  searchPatientTapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(searchPatientTapped, true);
    });

    testWidgets('chama callback ao clicar em ver agenda', (tester) async {
      var viewScheduleTapped = false;

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('pt', 'BR')],
          path: 'assets/translations',
          fallbackLocale: const Locale('pt', 'BR'),
          child: MaterialApp(
            home: Scaffold(
              body: QuickActions(
                onViewSchedule: () {
                  viewScheduleTapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.pumpAndSettle();

      expect(viewScheduleTapped, true);
    });

    testWidgets('chama callback ao clicar em financeiro', (tester) async {
      var viewFinancialTapped = false;

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('pt', 'BR')],
          path: 'assets/translations',
          fallbackLocale: const Locale('pt', 'BR'),
          child: MaterialApp(
            home: Scaffold(
              body: QuickActions(
                onViewFinancial: () {
                  viewFinancialTapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.attach_money));
      await tester.pumpAndSettle();

      expect(viewFinancialTapped, true);
    });

    testWidgets('não quebra quando callbacks são null', (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('pt', 'BR')],
          path: 'assets/translations',
          fallbackLocale: const Locale('pt', 'BR'),
          child: MaterialApp(
            home: Scaffold(
              body: QuickActions(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tenta clicar em todos os botões
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.tap(find.byIcon(Icons.search));
      await tester.tap(find.byIcon(Icons.calendar_month));
      await tester.tap(find.byIcon(Icons.attach_money));
      await tester.pumpAndSettle();

      // Não deve lançar exceção
    });

    testWidgets('exibe label Financeiro', (tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('pt', 'BR')],
          path: 'assets/translations',
          fallbackLocale: const Locale('pt', 'BR'),
          child: MaterialApp(
            home: Scaffold(
              body: QuickActions(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Financeiro'), findsOneWidget);
    });
  });
}
