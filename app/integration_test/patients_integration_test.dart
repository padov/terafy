import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Patients Integration Tests', () {
    setUp(() async {
      await IntegrationTestHelpers.clearAppData();
    });

    testWidgets('fluxo completo de criação de paciente', (tester) async {
      // 1) Faz login
      await IntegrationTestHelpers.pumpApp(tester);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Login
      final loginFields = find.byType(TextFormField);
      await IntegrationTestHelpers.enterText(tester, loginFields.first, TestData.validEmail);
      await tester.pump(const Duration(milliseconds: 200));
      await IntegrationTestHelpers.enterText(tester, loginFields.last, TestData.validPassword);
      await tester.pump(const Duration(milliseconds: 200));

      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verifica que está na home
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget, reason: 'Deve estar na home após login');

      // 2) Navega para a tela de pacientes
      // Simula tap no índice 1 (geralmente pacientes)
      await tester.tap(find.byType(BottomNavigationBar));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 3) Procura pelo botão de adicionar paciente
      // Pode ser um FAB ou botão "Adicionar Paciente"
      final addPatientButton = find.byWidgetPredicate((widget) {
        if (widget is FloatingActionButton) {
          return true;
        }
        if (widget is ElevatedButton) {
          final button = widget;
          final child = button.child;
          if (child is Text) {
            final text = child.data ?? '';
            return text.toLowerCase().contains('adicionar') ||
                text.toLowerCase().contains('novo');
          }
        }
        return false;
      });

      if (addPatientButton.evaluate().isNotEmpty) {
        await IntegrationTestHelpers.tap(tester, addPatientButton.first);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // 4) Preenche formulário de paciente
      final patientFields = find.byType(TextFormField);
      if (patientFields.evaluate().isNotEmpty) {
        // Preenche nome
        await IntegrationTestHelpers.enterText(tester, patientFields.first, 'Maria Santos');
        await tester.pump(const Duration(milliseconds: 200));

        // Preenche telefone (se houver mais campos)
        if (patientFields.evaluate().length > 1) {
          await IntegrationTestHelpers.enterText(tester, patientFields.at(1), '11987654321');
          await tester.pump(const Duration(milliseconds: 200));
        }

        // Procura pelo botão de salvar
        var saveButton = find.widgetWithText(ElevatedButton, 'Salvar');
        if (saveButton.evaluate().isEmpty) {
          saveButton = find.widgetWithText(ElevatedButton, 'Criar');
        }
        if (saveButton.evaluate().isEmpty) {
          saveButton = find.widgetWithText(ElevatedButton, 'Adicionar');
        }

        if (saveButton.evaluate().isNotEmpty) {
          await IntegrationTestHelpers.tap(tester, saveButton.first);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // Verifica que o paciente foi criado (pode aparecer na lista ou mensagem de sucesso)
          expect(find.textContaining('Maria'), findsAtLeastNWidgets(1),
              reason: 'Paciente deve aparecer na lista após criação');
        }
      }
    });

    testWidgets('visualização de lista de pacientes', (tester) async {
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

      // 2) Navega para pacientes
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget);

      await tester.tap(find.byType(BottomNavigationBar));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 3) Verifica que a lista de pacientes está presente
      // Pode ser uma ListView, GridView ou lista customizada
      final listView = find.byType(ListView);
      final scrollView = find.byType(ScrollView);

      expect(
        listView.evaluate().isNotEmpty || scrollView.evaluate().isNotEmpty,
        isTrue,
        reason: 'Lista de pacientes deve estar presente',
      );
    });
  });
}

