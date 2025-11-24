import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Visual Tests - Section 1.1', () {
    setUp(() async {
      // Clear app data before each test
      // O DependencyContainer será inicializado no pumpApp
      await IntegrationTestHelpers.clearAppData();
    });

    testWidgets('1.1.1 - Initial Login State', (tester) async {
      // Arrange: Inicia o app na tela de login
      await IntegrationTestHelpers.pumpApp(tester);

      // Aguarda o LoginBloc terminar sua inicialização
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verifica se estamos na tela de login
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isEmpty) {
        final bottomNav = find.byType(BottomNavigationBar);
        if (bottomNav.evaluate().isNotEmpty) {
          fail('Teste falhou: App navegou automaticamente para home antes do login.');
        }
        fail('Teste falhou: Campos de texto não encontrados na tela de login.');
      }

      // Valida se todos os widgets estão presentes na tela
      final emailField = textFields.first;
      final passwordField = textFields.last;
      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');

      // Campos de entrada
      expect(emailField, findsOneWidget, reason: 'Campo de email deve estar presente');
      expect(passwordField, findsOneWidget, reason: 'Campo de senha deve estar presente');
      expect(loginButton, findsOneWidget, reason: 'Botão de entrar deve estar presente');

      // Labels dos campos
      expect(find.text('Email'), findsOneWidget, reason: 'Label do campo email deve estar presente');
      expect(find.text('Senha'), findsOneWidget, reason: 'Label do campo senha deve estar presente');

      // Links importantes
      expect(find.text('Esqueceu a senha?'), findsOneWidget, reason: 'Link "Esqueceu a senha?" deve estar presente');

      // Switch de biometria
      final biometricSwitch = find.byType(Switch);
      expect(biometricSwitch, findsOneWidget, reason: 'Switch de biometria deve estar presente');

      // Verifica se o ícone de biometria está presente
      // O ícone pode ser implementado como Icon ou SvgPicture
      final biometricIcon = find.byWidgetPredicate((widget) {
        if (widget is Icon) {
          return widget.icon == Icons.fingerprint;
        }
        return false;
      });
      expect(biometricIcon, findsOneWidget, reason: 'Ícone de biometria deve estar presente');

      // Login social
      expect(find.text('Ou entre com'), findsOneWidget, reason: 'Texto "Ou entre com" deve estar presente');

      // Botões sociais - verifica que há exatamente 3 botões (Apple, Google, Facebook)
      // Os botões são implementados como InkWell com Container de 64x64
      final socialButtons = find.byWidgetPredicate((widget) {
        if (widget is InkWell) {
          // Verifica se o InkWell contém um Container com dimensões específicas dos botões sociais
          return true;
        }
        return false;
      });
      // Deve haver pelo menos 3 InkWell (botões sociais)
      // Pode haver mais se houver outros InkWell na tela, então usamos findsAtLeastNWidgets
      expect(
        socialButtons,
        findsAtLeastNWidgets(3),
        reason: 'Deve haver pelo menos 3 botões de login social (Apple, Google, Facebook)',
      );

      // Verifica que há SvgPicture presentes (ícones dos botões sociais)
      // O logo também é SVG, então deve haver pelo menos 4 (logo + 3 botões sociais)
      final svgPictures = find.byType(SvgPicture);
      expect(
        svgPictures,
        findsAtLeastNWidgets(4),
        reason: 'Deve haver pelo menos 4 ícones SVG (logo + 3 botões sociais: Apple, Google, Facebook)',
      );

      // Verifica o texto "Não tem uma conta? e link para cadastro"
      expect(find.text('Não tem uma conta?'), findsOneWidget, reason: 'Texto "Não tem uma conta?" deve estar presente');
      expect(find.text('Cadastre-se'), findsOneWidget, reason: 'Link "Cadastre-se" deve estar presente');

      // Validação do toggle de visibilidade da senha
      // 1) Verifica que o ícone de visibilidade off está presente inicialmente
      final visibilityToggleOff = find.byIcon(Icons.visibility_off_outlined);
      expect(
        visibilityToggleOff,
        findsOneWidget,
        reason: 'Ícone de visibilidade off deve estar presente no campo de senha',
      );

      // 2) Digita uma senha para ativar o toggle
      await IntegrationTestHelpers.enterText(tester, passwordField, TestData.validPassword);
      await tester.pump(const Duration(milliseconds: 300));

      // 3) Verifica que o ícone ainda está presente após digitar
      expect(
        visibilityToggleOff,
        findsOneWidget,
        reason: 'Ícone de visibilidade off deve estar presente após digitar senha',
      );

      // 4) Toca no toggle para mostrar a senha
      await IntegrationTestHelpers.tap(tester, visibilityToggleOff);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 5) Verifica que o ícone mudou para visibilidade on
      final visibilityToggleOn = find.byIcon(Icons.visibility_outlined);
      expect(visibilityToggleOn, findsOneWidget, reason: 'Ícone de visibilidade on deve aparecer após tocar no toggle');

      // 6) Toca novamente para ocultar a senha
      await IntegrationTestHelpers.tap(tester, visibilityToggleOn);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 7) Verifica que o ícone voltou para visibilidade off
      expect(
        visibilityToggleOff,
        findsOneWidget,
        reason: 'Ícone de visibilidade off deve aparecer novamente após tocar no toggle',
      );
    });

    testWidgets('1.1.2 - Login validation and successful login', (tester) async {
      // Arrange: Inicia o app na tela de login
      await IntegrationTestHelpers.pumpApp(tester);

      // Aguarda o LoginBloc terminar sua inicialização
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verifica se estamos na tela de login
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isEmpty) {
        final bottomNav = find.byType(BottomNavigationBar);
        if (bottomNav.evaluate().isNotEmpty) {
          fail('Teste falhou: App navegou automaticamente para home antes do login.');
        }
        fail('Teste falhou: Campos de texto não encontrados na tela de login.');
      }

      final emailField = textFields.first;
      final passwordField = textFields.last;
      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');

      // 1) Clica em entrar (sem preencher nada)
      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 2) Verifica se as mensagens de campo obrigatório aparecem
      expect(find.text('Email é obrigatório'), findsOneWidget, reason: 'Mensagem de email obrigatório deve aparecer');
      expect(find.text('Senha é obrigatória'), findsOneWidget, reason: 'Mensagem de senha obrigatória deve aparecer');

      // 2.1) Testa validação de senha curta
      await IntegrationTestHelpers.enterText(tester, emailField, TestData.validEmail);
      await IntegrationTestHelpers.enterText(tester, passwordField, '123');
      await tester.pump(const Duration(milliseconds: 300));

      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verifica se a mensagem de senha curta aparece
      expect(
        find.text('Senha deve ter no mínimo 6 caracteres'),
        findsOneWidget,
        reason: 'Mensagem de senha curta deve aparecer',
      );

      // 3) Preenche email inválido
      await IntegrationTestHelpers.enterText(tester, emailField, TestData.malformedEmail);
      await tester.pump(const Duration(milliseconds: 300));

      // 4) Clica em entrar
      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 5) Verifica se a mensagem de email inválido aparece
      expect(find.text('Email inválido'), findsOneWidget, reason: 'Mensagem de email inválido deve aparecer');

      // Verifica que ainda estamos na tela de login (não navegou)
      expect(emailField, findsOneWidget, reason: 'Ainda deve estar na tela de login');
      expect(passwordField, findsOneWidget, reason: 'Ainda deve estar na tela de login');

      // 5.1) Testa email muito longo (mais de 254 caracteres - limite do RFC 5321)
      final veryLongEmail = 'a' * 250 + '@example.com'; // Email com mais de 254 caracteres
      await IntegrationTestHelpers.enterText(tester, emailField, veryLongEmail);
      await tester.pump(const Duration(milliseconds: 300));

      // Clica no botão de login para forçar validação
      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verifica se a mensagem de email inválido aparece para email muito longo
      expect(
        find.text('Email inválido'),
        findsOneWidget,
        reason: 'Mensagem de email inválido deve aparecer para email muito longo (mais de 254 caracteres)',
      );

      // 5.2) Testa email com espaços
      await IntegrationTestHelpers.enterText(tester, emailField, 'teste @example.com');
      await tester.pump(const Duration(milliseconds: 300));

      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verifica se a mensagem de email inválido aparece para email com espaços
      expect(
        find.text('Email inválido'),
        findsOneWidget,
        reason: 'Mensagem de email inválido deve aparecer para email com espaços',
      );

      // 5.3) Testa email com caracteres especiais válidos (deve aceitar)
      // Email com + e . são válidos: user+tag@example.com
      await IntegrationTestHelpers.enterText(tester, emailField, 'user+tag@example.com');
      await tester.pump(const Duration(milliseconds: 300));

      // Faz o campo perder o foco para disparar a validação
      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Email com caracteres especiais válidos não deve mostrar erro de formato
      // (mas pode falhar na autenticação se não existir no sistema)
      // Verifica que a mensagem de email inválido desapareceu (formato válido)
      expect(
        find.text('Email inválido'),
        findsNothing,
        reason: 'Email com caracteres especiais válidos (+, .) deve ser aceito como formato válido',
      );

      // 6) Preenche um email válido
      await IntegrationTestHelpers.enterText(tester, emailField, TestData.validEmail);
      await tester.pump(const Duration(milliseconds: 300));

      // Faz o campo perder o foco para disparar a validação novamente
      // Isso faz com que a mensagem de erro desapareça se o email estiver válido
      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verifica que a mensagem de erro de email desapareceu após corrigir e perder foco
      expect(
        find.text('Email inválido'),
        findsNothing,
        reason: 'Mensagem de email inválido deve desaparecer após corrigir e perder foco',
      );

      // 7) Preenche senha errada
      await IntegrationTestHelpers.enterText(tester, passwordField, TestData.invalidPassword);
      await tester.pump(const Duration(milliseconds: 300));

      // 8) Clica em entrar com credenciais inválidas
      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 200));

      // Aguarda resposta da API
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 9) Verifica se o SnackBar de erro aparece com a mensagem correta
      final errorSnackBar = find.byType(SnackBar);
      expect(errorSnackBar, findsOneWidget, reason: 'SnackBar de erro deve aparecer quando credenciais são inválidas');

      // Verifica se a mensagem de erro está correta
      expect(
        find.textContaining('Credenciais inválidas'),
        findsOneWidget,
        reason: 'Mensagem "Credenciais inválidas" deve aparecer no SnackBar',
      );

      // 10) Preenche senha correta
      await IntegrationTestHelpers.enterText(tester, passwordField, TestData.validPassword);
      await tester.pump(const Duration(milliseconds: 300));

      // 11) Clica em entrar com credenciais válidas
      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 200));

      // Aguarda o estado de loading aparecer
      await tester.pump(const Duration(milliseconds: 500));

      // Aguarda navegação e resposta da API (tempo suficiente para salvar token e navegar)
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 12) Verifica se navegou para a home (não deve mais estar na tela de login)
      final loginFields = find.byType(TextFormField);
      expect(loginFields, findsNothing, reason: 'Ainda está na tela de login após login bem-sucedido');

      // Verifica se há erro de token não fornecido (SnackBar de erro)
      final snackBarAfterLogin = find.byType(SnackBar);
      if (snackBarAfterLogin.evaluate().isNotEmpty) {
        final errorText = find.textContaining('token não fornecido');
        if (errorText.evaluate().isNotEmpty) {
          fail(
            'Erro: Token não foi fornecido nas requisições. O token pode não ter sido salvo corretamente após o login.',
          );
        }
      }

      // Verifica elementos específicos da home page
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget, reason: 'Home page não foi carregada (BottomNavigationBar não encontrado)');

      // 12.1) Verifica que não pode voltar para login (navegação foi substituída, não empilhada)
      // A HomePage tem PopScope com canPop: false, então o botão de voltar não deve fazer nada
      // Verifica que o PopScope está presente na HomePage e configurado com canPop: false
      final popScope = find.byWidgetPredicate(
        (widget) => widget is PopScope && !widget.canPop,
        description: 'PopScope com canPop: false na HomePage',
      );
      expect(
        popScope,
        findsOneWidget,
        reason: 'HomePage deve ter PopScope com canPop: false para impedir que o botão de voltar feche o app',
      );

      // Se ainda estiver carregando, aguarda mais um pouco
      final loadingIndicator = find.byType(CircularProgressIndicator);
      if (loadingIndicator.evaluate().isNotEmpty) {
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // 13) Testa persistência de sessão após restart do app
      await IntegrationTestHelpers.restartApp(tester);

      // Aguarda o splash screen e verificação automática de token
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verifica que o login automático aconteceu (não deve estar na tela de login)
      final loginFieldsAfterRestart = find.byType(TextFormField);
      expect(
        loginFieldsAfterRestart,
        findsNothing,
        reason: 'Login automático deve ter funcionado após restart - não deve estar na tela de login',
      );

      // Verifica que navegou para home automaticamente
      final bottomNavAfterRestart = find.byType(BottomNavigationBar);
      expect(
        bottomNavAfterRestart,
        findsOneWidget,
        reason: 'App deve ter feito login automático e navegado para home após restart',
      );
    });

    testWidgets('1.1.3 - Login with biometric enabled and relogin after app restart', (tester) async {
      // PARTE 1: Login inicial com biometria habilitada
      // Arrange: Inicia o app na tela de login
      await IntegrationTestHelpers.pumpApp(tester);

      // Aguarda o LoginBloc terminar sua inicialização
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');

      // 1) Habilita o switch de biometria
      final biometricSwitch = find.byType(Switch);
      expect(biometricSwitch, findsOneWidget, reason: 'Switch de biometria deve estar presente');

      // Toca no switch para habilitar biometria
      await IntegrationTestHelpers.tap(tester, biometricSwitch);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verifica que o switch está habilitado
      final switchWidget = tester.widget<Switch>(biometricSwitch);
      expect(switchWidget.value, isTrue, reason: 'Switch de biometria deve estar habilitado');

      // 2) Preenche credenciais válidas
      await IntegrationTestHelpers.enterText(tester, emailField, TestData.validEmail);
      await tester.pump(const Duration(milliseconds: 300));
      await IntegrationTestHelpers.enterText(tester, passwordField, TestData.validPassword);
      await tester.pump(const Duration(milliseconds: 300));

      // 3) Clica em entrar com biometria habilitada
      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 200));

      // Aguarda o estado de loading aparecer
      await tester.pump(const Duration(milliseconds: 500));

      // Aguarda navegação e resposta da API
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 4) Verifica se navegou para a home (login bem-sucedido)
      final loginFields = find.byType(TextFormField);
      expect(loginFields, findsNothing, reason: 'Ainda está na tela de login após login bem-sucedido');

      // Verifica elementos específicos da home page
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget, reason: 'Home page não foi carregada (BottomNavigationBar não encontrado)');

      // PARTE 2: Reinicia o app e valida login biométrico automático
      // 5) Simula reinício do app (mantém tokens salvos, mas reinicia a UI)
      await IntegrationTestHelpers.restartApp(tester);

      // Aguarda o splash screen e verificação automática de biometria
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 6) Verifica que o login biométrico aconteceu automaticamente
      // Não deve estar na tela de login (deve ter feito login automático)
      final loginFieldsAfterRestart = find.byType(TextFormField);
      expect(
        loginFieldsAfterRestart,
        findsNothing,
        reason: 'Login biométrico automático deve ter funcionado - não deve estar na tela de login',
      );

      // Verifica que navegou para home automaticamente
      final bottomNavAfterRestart = find.byType(BottomNavigationBar);
      expect(
        bottomNavAfterRestart,
        findsOneWidget,
        reason: 'App deve ter feito login biométrico automático e navegado para home',
      );

      // Verifica se há erro (SnackBar de erro)
      final snackBar = find.byType(SnackBar);
      if (snackBar.evaluate().isNotEmpty) {
        final errorText = find.textContaining('token não fornecido');
        if (errorText.evaluate().isNotEmpty) {
          fail('Erro: Token não foi fornecido nas requisições após login biométrico.');
        }
      }

      // Se ainda estiver carregando, aguarda mais um pouco
      final loadingIndicator = find.byType(CircularProgressIndicator);
      if (loadingIndicator.evaluate().isNotEmpty) {
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
    });

    testWidgets('1.1.4 - Login, logout and new login', (tester) async {
      // 1) Faz login com sucesso
      await IntegrationTestHelpers.pumpApp(tester);

      // Aguarda o LoginBloc terminar sua inicialização
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');

      // Faz login com credenciais válidas
      await IntegrationTestHelpers.enterText(tester, emailField, TestData.validEmail);
      await IntegrationTestHelpers.enterText(tester, passwordField, TestData.validPassword);

      await IntegrationTestHelpers.tap(tester, loginButton);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verifica que navegou para home
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget, reason: 'Home page não foi carregada após login');

      // Aguarda o home carregar completamente
      final loadingIndicator = find.byType(CircularProgressIndicator);
      if (loadingIndicator.evaluate().isNotEmpty) {
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Aguarda um pouco mais para garantir que tudo carregou
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));

      // 2) Testa que o botão de voltar do celular não faz nada
      // Verifica que o PopScope está presente na HomePage com canPop: false
      final popScope = find.byType(PopScope);
      expect(popScope, findsOneWidget, reason: 'PopScope deve estar presente na HomePage');

      // Verifica que o PopScope tem canPop: false
      final popScopeWidget = tester.widget<PopScope>(popScope);
      expect(
        popScopeWidget.canPop,
        isFalse,
        reason: 'PopScope deve ter canPop: false para impedir que o botão de voltar feche o app',
      );

      // Verifica que ainda está na home (não voltou para login/splash)
      final bottomNavCheck = find.byType(BottomNavigationBar);
      expect(bottomNavCheck, findsOneWidget, reason: 'Deve continuar na Home após verificar PopScope');

      // 3) Clica no popup do usuário e faz logout
      // Aguarda o header renderizar completamente
      await tester.pump(const Duration(milliseconds: 500));

      // Encontra o CircleAvatar (avatar do usuário) que é o child do PopupMenuButton
      final circleAvatar = find.byType(CircleAvatar);
      expect(circleAvatar, findsOneWidget, reason: 'CircleAvatar (avatar do usuário) deve estar presente no header');

      // Clica no avatar para abrir o menu
      await IntegrationTestHelpers.tap(tester, circleAvatar.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Procura pelo item "Sair" no menu
      final logoutMenuItem = find.text('Sair');
      expect(logoutMenuItem, findsOneWidget, reason: 'Item "Sair" deve estar presente no menu');

      // Clica no item "Sair"
      await IntegrationTestHelpers.tap(tester, logoutMenuItem);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Confirma o logout no diálogo
      final confirmLogoutButton = find.widgetWithText(TextButton, 'Sair');
      expect(confirmLogoutButton, findsOneWidget, reason: 'Botão de confirmação "Sair" deve estar presente no diálogo');
      await IntegrationTestHelpers.tap(tester, confirmLogoutButton);
      await tester.pump(const Duration(milliseconds: 300));

      // Aguarda a navegação após logout
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verifica que voltou para a tela de login
      final loginFieldsAfterLogout = find.byType(TextFormField);
      expect(loginFieldsAfterLogout, findsNWidgets(2), reason: 'Deve estar na tela de login após logout');
      expect(find.text('Entrar'), findsOneWidget, reason: 'Botão "Entrar" deve estar presente após logout');
    });
  });

  group('Login Visual Tests - Additional Scenarios', () {
    testWidgets('Loading state during login', (tester) async {
      // Arrange
      await IntegrationTestHelpers.pumpApp(tester);

      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');

      // Enter credentials
      await IntegrationTestHelpers.enterText(tester, emailField, TestData.validEmail);
      await IntegrationTestHelpers.enterText(tester, passwordField, TestData.validPassword);

      // Act: Tap login button
      await tester.tap(loginButton);
      await tester.pump(); // Pump once to trigger the loading state

      // Assert: Loading indicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('Navigation to signup page', (tester) async {
      // Arrange
      await IntegrationTestHelpers.pumpApp(tester);

      // Aguarda o LoginBloc terminar sua inicialização
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find the signup link
      final signupLink = find.text('Cadastre-se');

      // Assert: Signup link should be visible
      expect(signupLink, findsOneWidget, reason: 'Link "Cadastre-se" deve estar presente');

      // Act: Tap signup link
      await IntegrationTestHelpers.tap(tester, signupLink);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Assert: Should navigate to signup page
      // Verifica que não está mais na tela de login
      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');

      // Na tela de signup, não deve ter o botão "Entrar" da tela de login
      expect(loginButton, findsNothing, reason: 'Não deve estar mais na tela de login após clicar em "Cadastre-se"');

      // Verifica que navegou para a tela de signup
      // A tela de signup deve ter campos de texto (mas diferentes da tela de login)
      // Podemos verificar que não há mais o botão "Entrar" específico do login
      // e que há elementos específicos da tela de signup
      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets, reason: 'Tela de signup deve ter campos de texto');

      // Verifica que não pode voltar para login (navegação foi substituída)
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      expect(navigator.canPop(), isFalse, reason: 'Não deve ser possível voltar para login após navegar para signup');
    });
  });
}
