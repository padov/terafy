import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

/// Teste de debug para identificar o que está causando redirecionamento para login
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DEBUG - Identificar origem do redirecionamento', (tester) async {
    // Limpa dados antes
    await IntegrationTestHelpers.clearAppData();

    // Inicia o app na rota de signup
    await IntegrationTestHelpers.pumpApp(tester, initialRoute: '/signup');

    // Aguarda um pouco para ver se há redirecionamento
    await tester.pump(const Duration(milliseconds: 100));

    // Verifica se ainda está na tela de signup
    final signupTitle = find.text('Crie sua conta');
    final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');

    print('🔍 DEBUG: Verificando estado após pump inicial...');
    print('   - Signup title encontrado: ${signupTitle.evaluate().isNotEmpty}');
    print('   - Login button encontrado: ${loginButton.evaluate().isNotEmpty}');

    if (loginButton.evaluate().isNotEmpty) {
      print('❌ PROBLEMA: App foi redirecionado para login após pump inicial!');
      print('   Isso significa que alguma lógica assíncrona está sendo executada.');
    } else if (signupTitle.evaluate().isNotEmpty) {
      print('✅ OK: App está na tela de signup após pump inicial');
    }

    // Tenta preencher um campo
    final emailFields = find.byType(TextFormField);
    if (emailFields.evaluate().isNotEmpty) {
      print('🔍 DEBUG: Tentando preencher campo de email...');
      final emailField = emailFields.first;

      await tester.tap(emailField);
      print('   - Tap executado');

      await tester.pump();
      print('   - Pump após tap executado');

      // Verifica se ainda está na tela de signup
      final signupTitleAfterTap = find.text('Crie sua conta');
      final loginButtonAfterTap = find.widgetWithText(ElevatedButton, 'Entrar');

      print('   - Signup title após tap: ${signupTitleAfterTap.evaluate().isNotEmpty}');
      print('   - Login button após tap: ${loginButtonAfterTap.evaluate().isNotEmpty}');

      if (loginButtonAfterTap.evaluate().isNotEmpty) {
        print('❌ PROBLEMA: App foi redirecionado para login após tap no campo!');
      }

      // Tenta enterText
      await tester.enterText(emailField, 'teste@test.com');
      print('   - enterText executado');

      // Verifica imediatamente (sem pump)
      final signupTitleAfterEnter = find.text('Crie sua conta');
      final loginButtonAfterEnter = find.widgetWithText(ElevatedButton, 'Entrar');

      print('   - Signup title após enterText (sem pump): ${signupTitleAfterEnter.evaluate().isNotEmpty}');
      print('   - Login button após enterText (sem pump): ${loginButtonAfterEnter.evaluate().isNotEmpty}');

      if (loginButtonAfterEnter.evaluate().isNotEmpty) {
        print('❌ PROBLEMA: App foi redirecionado para login após enterText (sem pump)!');
        print('   Isso significa que o redirecionamento acontece DURANTE o enterText, não após pump.');
      }

      // Agora faz um pump e verifica novamente
      await tester.pump();
      print('   - Pump após enterText executado');

      final signupTitleAfterPump = find.text('Crie sua conta');
      final loginButtonAfterPump = find.widgetWithText(ElevatedButton, 'Entrar');

      print('   - Signup title após pump: ${signupTitleAfterPump.evaluate().isNotEmpty}');
      print('   - Login button após pump: ${loginButtonAfterPump.evaluate().isNotEmpty}');

      if (loginButtonAfterPump.evaluate().isNotEmpty) {
        print('❌ PROBLEMA: App foi redirecionado para login após pump após enterText!');
        print('   Isso significa que o pump() está permitindo que operações assíncronas sejam executadas.');
        print('   Possíveis causas:');
        print('   1. LoginBloc está sendo criado e seu Future.microtask está sendo executado');
        print('   2. AuthInterceptor está verificando token e redirecionando');
        print('   3. Alguma lógica no MaterialApp ou nas rotas está verificando autenticação');
      }
    }

    // Não falha o teste - apenas imprime informações
    expect(true, isTrue);
  });
}
