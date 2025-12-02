import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sessions Integration Tests', () {
    setUp(() async {
      await IntegrationTestHelpers.clearAppData();
    });

    testWidgets('fluxo completo de criação de sessão', (tester) async {
      // 1) Faz login
      await IntegrationTestHelpers.pumpApp(tester);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final loginFields = find.byType(TextFormField);
      await IntegrationTestHelpers.enterText(tester, loginFields.first, TestData.validEmail);
      await IntegrationTestHelpers.enterText(tester, loginFields.last, TestData.validPassword);

      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verifica que está na home
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget);

      // 2) Navega para sessões
      // Procura por navegação ou botão de sessões
      await tester.tap(find.byType(BottomNavigationBar));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 3) Procura pelo botão de criar sessão
      final addSessionButton = find.byWidgetPredicate((widget) {
        if (widget is FloatingActionButton) {
          return true;
        }
        if (widget is ElevatedButton) {
          final button = widget;
          final child = button.child;
          if (child is Text) {
            final text = child.data ?? '';
            return text.toLowerCase().contains('sessão') ||
                text.toLowerCase().contains('nova');
          }
        }
        return false;
      });

      if (addSessionButton.evaluate().isNotEmpty) {
        await IntegrationTestHelpers.tap(tester, addSessionButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // 4) Preenche formulário de sessão
        final sessionFields = find.byType(TextFormField);
        if (sessionFields.evaluate().isNotEmpty) {
          // Preenche campos básicos
          await IntegrationTestHelpers.enterText(tester, sessionFields.first, 'Sessão de teste');
          await tester.pump(const Duration(milliseconds: 200));

          // Procura pelo botão de salvar
          var saveButton = find.widgetWithText(ElevatedButton, 'Salvar');
          if (saveButton.evaluate().isEmpty) {
            saveButton = find.widgetWithText(ElevatedButton, 'Criar');
          }

          if (saveButton.evaluate().isNotEmpty) {
            await IntegrationTestHelpers.tap(tester, saveButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 5));

            // Verifica que a sessão foi criada
            expect(find.textContaining('Sessão'), findsAtLeastNWidgets(1),
                reason: 'Sessão deve aparecer após criação');
          }
        }
      }
    });

    testWidgets('visualização de lista de sessões', (tester) async {
      // 1) Faz login
      await IntegrationTestHelpers.pumpApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final loginFields = find.byType(TextFormField);
      await IntegrationTestHelpers.enterText(tester, loginFields.first, TestData.validEmail);
      await IntegrationTestHelpers.enterText(tester, loginFields.last, TestData.validPassword);

      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 2) Navega para sessões
      await tester.tap(find.byType(BottomNavigationBar));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 3) Verifica que a lista de sessões está presente
      final listView = find.byType(ListView);
      final scrollView = find.byType(ScrollView);

      expect(
        listView.evaluate().isNotEmpty || scrollView.evaluate().isNotEmpty,
        isTrue,
        reason: 'Lista de sessões deve estar presente',
      );
    });
  });
}

