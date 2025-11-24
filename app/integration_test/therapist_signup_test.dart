import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Therapist Signup Tests - Section 1.2', () {
    setUp(() async {
      // Clear app data before each test
      await IntegrationTestHelpers.clearAppData();
    });

    testWidgets('1.2.1 - Complete therapist signup (simple + complete profile)', (tester) async {
      // Gera um email único para cada teste
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'teste$timestamp@terapy.com';
      const testPassword = '123456';

      // 1) Navega para a tela de cadastro seguindo o fluxo normal do app
      // Em vez de acessar /signup diretamente, vamos seguir o fluxo: login -> signup
      // Isso evita problemas com navegação direta que podem causar redirecionamentos
      await IntegrationTestHelpers.pumpApp(tester, initialRoute: '/login');

      // Aguarda o LoginBloc terminar sua inicialização
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verifica que está na tela de login
      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
      expect(loginButton, findsOneWidget, reason: 'Deve estar na tela de login');

      // Navega para a tela de signup clicando no link "Cadastre-se"
      final signupLink = find.text('Cadastre-se');
      expect(signupLink, findsOneWidget, reason: 'Link "Cadastre-se" deve estar presente na tela de login');

      await IntegrationTestHelpers.tap(tester, signupLink);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verifica que está na tela de cadastro simples (não foi redirecionado para login)
      final signupTitle = find.text('Crie sua conta');
      expect(signupTitle, findsOneWidget, reason: 'Deve estar na tela de cadastro simples após navegar do login');
      expect(
        loginButton,
        findsNothing,
        reason: 'Não deve estar mais na tela de login (botão "Entrar" não deve estar presente)',
      );

      // 2) Preenche o cadastro simples (email, senha, confirmar senha)
      final emailFields = find.byType(TextFormField);
      expect(
        emailFields,
        findsAtLeastNWidgets(3),
        reason: 'Deve ter pelo menos 3 campos (email, senha, confirmar senha)',
      );

      // Preenche email
      final emailField = emailFields.first;
      // Usa enterText diretamente - NÃO faz pump antes ou depois para evitar que operações assíncronas sejam executadas
      await tester.tap(emailField);
      // NÃO faz pump aqui - vai direto para enterText
      await tester.enterText(emailField, testEmail);
      // NÃO faz pump aqui também - verifica imediatamente

      // Verifica IMEDIATAMENTE que ainda está na tela de signup (sem fazer pump)
      // Se houver redirecionamento, será detectado aqui
      expect(
        find.text('Crie sua conta'),
        findsOneWidget,
        reason: 'Deve continuar na tela de signup após preencher email (sem pump)',
      );

      // Preenche senha
      final passwordField = emailFields.at(1);
      await tester.tap(passwordField);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.enterText(passwordField, testPassword);
      await tester.pump(const Duration(milliseconds: 200));

      // Verifica que ainda está na tela de signup após preencher senha
      expect(
        find.text('Crie sua conta'),
        findsOneWidget,
        reason: 'Deve continuar na tela de signup após preencher senha',
      );

      // Preenche confirmar senha
      final confirmPasswordField = emailFields.at(2);
      await tester.tap(confirmPasswordField);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.enterText(confirmPasswordField, testPassword);
      await tester.pump(const Duration(milliseconds: 200));

      // Verifica que ainda está na tela de signup após preencher confirmar senha
      expect(
        find.text('Crie sua conta'),
        findsOneWidget,
        reason: 'Deve continuar na tela de signup após preencher confirmar senha',
      );

      // Clica no botão "Criar Conta"
      final createAccountButton = find.widgetWithText(ElevatedButton, 'Criar Conta');
      expect(createAccountButton, findsOneWidget, reason: 'Botão "Criar Conta" deve estar presente');
      await IntegrationTestHelpers.tap(tester, createAccountButton);
      await tester.pump(const Duration(milliseconds: 500));

      // Aguarda o cadastro simples ser processado e navegação para completar perfil
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verifica que navegou para a tela de completar perfil
      expect(
        find.text('Complete seu Perfil'),
        findsOneWidget,
        reason: 'Deve estar na tela de completar perfil após cadastro simples',
      );

      // 3) Preenche Step 1 - Dados Pessoais
      // Verifica que está no Step 1
      final step1Title = find.textContaining('Dados Pessoais');
      if (step1Title.evaluate().isEmpty) {
        // Tenta encontrar pelo título traduzido
        final title = find.textContaining('signup.step1.title');
        expect(title, findsOneWidget, reason: 'Deve estar no Step 1 - Dados Pessoais');
      }

      // Encontra todos os campos de texto do Step 1
      final step1Fields = find.byType(TextFormField);
      expect(step1Fields, findsAtLeastNWidgets(5), reason: 'Step 1 deve ter pelo menos 5 campos');

      // 3.1) Validação de campos obrigatórios - tenta clicar em "Próximo" sem preencher
      final nextButton = find.widgetWithText(ElevatedButton, 'Próximo');
      expect(nextButton, findsOneWidget, reason: 'Botão "Próximo" deve estar presente no Step 1');

      await IntegrationTestHelpers.tap(tester, nextButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verifica se apareceu SnackBar de erro
      final errorSnackBar = find.text('Verifique os dados pessoais informados.');
      expect(
        errorSnackBar,
        findsOneWidget,
        reason: 'SnackBar de erro deve aparecer ao tentar avançar sem preencher campos obrigatórios',
      );

      // Verifica mensagens de erro nos campos obrigatórios
      expect(
        find.text('Informe o nome completo'),
        findsOneWidget,
        reason: 'Mensagem de erro deve aparecer no campo Nome',
      );
      expect(
        find.text('Documento é obrigatório'),
        findsOneWidget,
        reason: 'Mensagem de erro deve aparecer no campo CPF/CNPJ',
      );
      expect(
        find.text('Telefone é obrigatório'),
        findsOneWidget,
        reason: 'Mensagem de erro deve aparecer no campo Telefone',
      );

      // 3.2) Preenche os campos obrigatórios
      // Preenche Nome Completo
      await IntegrationTestHelpers.enterText(tester, step1Fields.at(0), 'João Silva');
      await tester.pump(const Duration(milliseconds: 200));

      // Verifica que a mensagem de erro do nome desapareceu
      // Faz o campo perder o foco para disparar validação
      await IntegrationTestHelpers.tap(tester, step1Fields.at(1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.text('Informe o nome completo'),
        findsNothing,
        reason: 'Mensagem de erro do nome deve desaparecer após preencher',
      );

      // Preenche Apelido (opcional, mas vamos preencher)
      await IntegrationTestHelpers.enterText(tester, step1Fields.at(1), 'João');
      await tester.pump(const Duration(milliseconds: 200));

      // Preenche CPF/CNPJ
      await IntegrationTestHelpers.enterText(tester, step1Fields.at(2), '12345678900');
      await tester.pump(const Duration(milliseconds: 200));

      // Verifica que a mensagem de erro do documento desapareceu
      await IntegrationTestHelpers.tap(tester, step1Fields.at(3));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.text('Documento é obrigatório'),
        findsNothing,
        reason: 'Mensagem de erro do documento deve desaparecer após preencher',
      );

      // Email já está preenchido (readonly)
      // Verifica que o email está presente e correto
      final emailFieldStep1 = tester.widget<TextFormField>(step1Fields.at(3));
      expect(
        emailFieldStep1.controller?.text,
        testEmail,
        reason: 'Email deve estar preenchido com o email do cadastro simples',
      );

      // Preenche Telefone
      await IntegrationTestHelpers.enterText(tester, step1Fields.at(4), '11987654321');
      await tester.pump(const Duration(milliseconds: 200));

      // Verifica que a mensagem de erro do telefone desapareceu
      await IntegrationTestHelpers.tap(tester, nextButton);
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.text('Telefone é obrigatório'),
        findsNothing,
        reason: 'Mensagem de erro do telefone deve desaparecer após preencher',
      );

      // Data de Nascimento: O campo já vem com uma data padrão (01/01/1979)
      // Não precisamos alterá-la para o teste

      // 3.3) Clica no botão "Próximo" novamente (agora com todos os campos preenchidos)
      await IntegrationTestHelpers.tap(tester, nextButton);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 4) Preenche Step 2 - Dados Profissionais
      // Verifica que está no Step 2
      final step2Title = find.textContaining('Dados Profissionais');
      if (step2Title.evaluate().isEmpty) {
        // Tenta encontrar pelo título traduzido
        final title = find.textContaining('signup.step2.title');
        expect(title, findsOneWidget, reason: 'Deve estar no Step 2 - Dados Profissionais');
      }

      // Encontra os campos do Step 2
      final step2Fields = find.byType(TextFormField);

      // Ordem dos campos no Step 2:
      // 0: Campo de especialidade (para adicionar)
      // 1: Campo de registro profissional (para adicionar)
      // 2: Apresentação Profissional
      // 3: Endereço

      // 4.1) Validação de campos obrigatórios - tenta clicar em "Finalizar" sem adicionar especialidade
      final finishButton = find.widgetWithText(ElevatedButton, 'Finalizar');
      expect(finishButton, findsOneWidget, reason: 'Botão "Finalizar" deve estar presente no Step 2');

      await IntegrationTestHelpers.tap(tester, finishButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verifica se apareceu SnackBar de erro para especialidade
      final errorSnackBarSpecialty = find.text('Adicione pelo menos uma especialidade.');
      expect(
        errorSnackBarSpecialty,
        findsOneWidget,
        reason: 'SnackBar de erro deve aparecer ao tentar finalizar sem especialidade',
      );

      // 4.2) Adiciona Especialidade
      final specialtyField = step2Fields.at(0);
      await IntegrationTestHelpers.enterText(tester, specialtyField, 'Psicologia Clínica');
      await tester.pump(const Duration(milliseconds: 200));

      // Procura pelo botão de adicionar especialidade (IconButton com Icons.add_circle)
      final addSpecialtyButtons = find.byIcon(Icons.add_circle);
      expect(
        addSpecialtyButtons,
        findsAtLeastNWidgets(1),
        reason: 'Botão de adicionar especialidade deve estar presente',
      );
      await IntegrationTestHelpers.tap(tester, addSpecialtyButtons.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verifica que a especialidade foi adicionada (deve aparecer um Chip)
      expect(find.text('Psicologia Clínica'), findsOneWidget, reason: 'Especialidade deve ter sido adicionada');

      // 4.3) Tenta clicar em "Finalizar" sem adicionar registro profissional
      await IntegrationTestHelpers.tap(tester, finishButton);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verifica se apareceu SnackBar de erro para registro profissional
      final errorSnackBarRegistration = find.text('Informe pelo menos um registro profissional.');
      expect(
        errorSnackBarRegistration,
        findsOneWidget,
        reason: 'SnackBar de erro deve aparecer ao tentar finalizar sem registro profissional',
      );

      // 4.4) Adiciona Registro Profissional
      final registrationField = step2Fields.at(1);
      await IntegrationTestHelpers.enterText(tester, registrationField, 'CRP 06/123456');
      await tester.pump(const Duration(milliseconds: 200));

      // Procura pelo segundo botão de adicionar (para registro profissional)
      final addRegistrationButtons = find.byIcon(Icons.add_circle);
      expect(
        addRegistrationButtons,
        findsAtLeastNWidgets(2),
        reason: 'Botão de adicionar registro deve estar presente',
      );
      await IntegrationTestHelpers.tap(tester, addRegistrationButtons.at(1));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verifica que o registro foi adicionado (deve aparecer um Chip)
      expect(find.text('CRP 06/123456'), findsOneWidget, reason: 'Registro profissional deve ter sido adicionado');

      // 4.5) Preenche Apresentação Profissional
      final presentationField = step2Fields.at(2);
      await IntegrationTestHelpers.enterText(
        tester,
        presentationField,
        'Terapeuta especializado em terapia cognitivo-comportamental com 10 anos de experiência.',
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Preenche Endereço
      final addressField = step2Fields.at(3);
      await IntegrationTestHelpers.enterText(tester, addressField, 'Rua das Flores, 123 - São Paulo, SP');
      await tester.pump(const Duration(milliseconds: 200));

      // 4.6) Clica no botão "Finalizar" novamente (agora com todos os campos obrigatórios preenchidos)
      await IntegrationTestHelpers.tap(tester, finishButton);
      await tester.pump(const Duration(milliseconds: 500));

      // Aguarda o processamento do cadastro completo
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 5) Verifica que navegou para a home após cadastro completo
      final bottomNav = find.byType(BottomNavigationBar);
      expect(
        bottomNav,
        findsOneWidget,
        reason: 'Deve estar na home após cadastro completo (BottomNavigationBar deve estar presente)',
      );

      // Verifica que não está mais na tela de cadastro
      expect(find.text('Complete seu Perfil'), findsNothing, reason: 'Não deve estar mais na tela de completar perfil');

      // Verifica que não está mais na tela de cadastro simples
      expect(find.text('Crie sua conta'), findsNothing, reason: 'Não deve estar mais na tela de cadastro simples');
    });

    testWidgets('1.2.2 - Signup with app restart during complete profile', (tester) async {
      // Gera um email único para cada teste
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'teste$timestamp@terapy.com';
      const testPassword = '123456';

      // 1) Navega para a tela de cadastro seguindo o fluxo normal do app
      await IntegrationTestHelpers.pumpApp(tester, initialRoute: '/login');

      // Aguarda o LoginBloc terminar sua inicialização
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verifica que está na tela de login
      final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
      expect(loginButton, findsOneWidget, reason: 'Deve estar na tela de login');

      // Navega para a tela de signup clicando no link "Cadastre-se"
      final signupLink = find.text('Cadastre-se');
      expect(signupLink, findsOneWidget, reason: 'Link "Cadastre-se" deve estar presente na tela de login');

      await IntegrationTestHelpers.tap(tester, signupLink);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verifica que está na tela de cadastro simples
      final signupTitle = find.text('Crie sua conta');
      expect(signupTitle, findsOneWidget, reason: 'Deve estar na tela de cadastro simples');

      // 2) Preenche o cadastro simples (email, senha, confirmar senha)
      final emailFields = find.byType(TextFormField);
      expect(
        emailFields,
        findsAtLeastNWidgets(3),
        reason: 'Deve ter pelo menos 3 campos (email, senha, confirmar senha)',
      );

      // Preenche email
      final emailField = emailFields.first;
      await tester.tap(emailField);
      await tester.enterText(emailField, testEmail);
      expect(
        find.text('Crie sua conta'),
        findsOneWidget,
        reason: 'Deve continuar na tela de signup após preencher email',
      );

      // Preenche senha
      final passwordField = emailFields.at(1);
      await tester.tap(passwordField);
      await tester.enterText(passwordField, testPassword);
      expect(
        find.text('Crie sua conta'),
        findsOneWidget,
        reason: 'Deve continuar na tela de signup após preencher senha',
      );

      // Preenche confirmar senha
      final confirmPasswordField = emailFields.at(2);
      await tester.tap(confirmPasswordField);
      await tester.enterText(confirmPasswordField, testPassword);
      expect(
        find.text('Crie sua conta'),
        findsOneWidget,
        reason: 'Deve continuar na tela de signup após preencher confirmar senha',
      );

      // Clica no botão "Criar Conta"
      final createAccountButton = find.widgetWithText(ElevatedButton, 'Criar Conta');
      expect(createAccountButton, findsOneWidget, reason: 'Botão "Criar Conta" deve estar presente');
      await IntegrationTestHelpers.tap(tester, createAccountButton);
      await tester.pump(const Duration(milliseconds: 500));

      // Aguarda o cadastro simples ser processado e navegação para completar perfil
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verifica que navegou para a tela de completar perfil
      expect(
        find.text('Complete seu Perfil'),
        findsOneWidget,
        reason: 'Deve estar na tela de completar perfil após cadastro simples',
      );

      // 3) REINICIA A APLICAÇÃO (simula fechar e reabrir o app)
      await IntegrationTestHelpers.restartApp(tester);

      // Aguarda o splash screen e verificação automática de token
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 4) Faz login novamente com as credenciais que acabou de cadastrar
      // O token temporário não é persistido, então precisa fazer login novamente
      // Verifica que está na tela de login
      final loginButtonAfterRestart = find.widgetWithText(ElevatedButton, 'Entrar');
      expect(loginButtonAfterRestart, findsOneWidget, reason: 'Deve estar na tela de login após reiniciar o app');

      // Preenche email e senha
      final loginFields = find.byType(TextFormField);
      expect(
        loginFields,
        findsAtLeastNWidgets(2),
        reason: 'Deve ter pelo menos 2 campos (email, senha) na tela de login',
      );

      final emailLoginField = loginFields.first;
      final passwordLoginField = loginFields.last;

      await IntegrationTestHelpers.enterText(tester, emailLoginField, testEmail);
      await tester.pump(const Duration(milliseconds: 200));

      await IntegrationTestHelpers.enterText(tester, passwordLoginField, testPassword);
      await tester.pump(const Duration(milliseconds: 200));

      // Clica no botão "Entrar"
      await IntegrationTestHelpers.tap(tester, loginButtonAfterRestart);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 5) Verifica que redirecionou para completar perfil (accountId ainda é null)
      expect(
        find.text('Complete seu Perfil'),
        findsOneWidget,
        reason: 'Deve estar na tela de completar perfil após login (accountId ainda é null)',
      );

      // 5) Preenche Step 1 - Dados Pessoais
      final step1Fields = find.byType(TextFormField);
      expect(step1Fields, findsAtLeastNWidgets(5), reason: 'Step 1 deve ter pelo menos 5 campos');

      // Preenche Nome Completo
      await IntegrationTestHelpers.enterText(tester, step1Fields.at(0), 'João Silva');
      await tester.pump(const Duration(milliseconds: 200));

      // Preenche Apelido
      await IntegrationTestHelpers.enterText(tester, step1Fields.at(1), 'João');
      await tester.pump(const Duration(milliseconds: 200));

      // Preenche CPF/CNPJ
      await IntegrationTestHelpers.enterText(tester, step1Fields.at(2), '12345678900');
      await tester.pump(const Duration(milliseconds: 200));

      // Email já está preenchido (readonly)
      final emailFieldStep1 = tester.widget<TextFormField>(step1Fields.at(3));
      expect(
        emailFieldStep1.controller?.text,
        testEmail,
        reason: 'Email deve estar preenchido com o email do cadastro simples',
      );

      // Preenche Telefone
      await IntegrationTestHelpers.enterText(tester, step1Fields.at(4), '11987654321');
      await tester.pump(const Duration(milliseconds: 200));

      // Clica no botão "Próximo"
      final nextButton = find.widgetWithText(ElevatedButton, 'Próximo');
      expect(nextButton, findsOneWidget, reason: 'Botão "Próximo" deve estar presente no Step 1');
      await IntegrationTestHelpers.tap(tester, nextButton);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 6) Preenche Step 2 - Dados Profissionais
      final step2Fields = find.byType(TextFormField);

      // Adiciona Especialidade
      final specialtyField = step2Fields.at(0);
      await IntegrationTestHelpers.enterText(tester, specialtyField, 'Psicologia Clínica');
      await tester.pump(const Duration(milliseconds: 200));

      final addSpecialtyButtons = find.byIcon(Icons.add_circle);
      expect(
        addSpecialtyButtons,
        findsAtLeastNWidgets(1),
        reason: 'Botão de adicionar especialidade deve estar presente',
      );
      await IntegrationTestHelpers.tap(tester, addSpecialtyButtons.first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Psicologia Clínica'), findsOneWidget, reason: 'Especialidade deve ter sido adicionada');

      // Adiciona Registro Profissional
      final registrationField = step2Fields.at(1);
      await IntegrationTestHelpers.enterText(tester, registrationField, 'CRP 06/123456');
      await tester.pump(const Duration(milliseconds: 200));

      final addRegistrationButtons = find.byIcon(Icons.add_circle);
      expect(
        addRegistrationButtons,
        findsAtLeastNWidgets(2),
        reason: 'Botão de adicionar registro deve estar presente',
      );
      await IntegrationTestHelpers.tap(tester, addRegistrationButtons.at(1));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('CRP 06/123456'), findsOneWidget, reason: 'Registro profissional deve ter sido adicionado');

      // Preenche Apresentação Profissional
      final presentationField = step2Fields.at(2);
      await IntegrationTestHelpers.enterText(
        tester,
        presentationField,
        'Terapeuta especializado em terapia cognitivo-comportamental com 10 anos de experiência.',
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Preenche Endereço
      final addressField = step2Fields.at(3);
      await IntegrationTestHelpers.enterText(tester, addressField, 'Rua das Flores, 123 - São Paulo, SP');
      await tester.pump(const Duration(milliseconds: 200));

      // Clica no botão "Finalizar"
      final finishButton = find.widgetWithText(ElevatedButton, 'Finalizar');
      expect(finishButton, findsOneWidget, reason: 'Botão "Finalizar" deve estar presente no Step 2');
      await IntegrationTestHelpers.tap(tester, finishButton);
      await tester.pump(const Duration(milliseconds: 500));

      // Aguarda o processamento do cadastro completo
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // 7) Verifica que navegou para a home após cadastro completo
      final bottomNav = find.byType(BottomNavigationBar);
      expect(
        bottomNav,
        findsOneWidget,
        reason: 'Deve estar na home após cadastro completo (BottomNavigationBar deve estar presente)',
      );

      // Verifica que não está mais na tela de cadastro
      expect(find.text('Complete seu Perfil'), findsNothing, reason: 'Não deve estar mais na tela de completar perfil');
      expect(find.text('Crie sua conta'), findsNothing, reason: 'Não deve estar mais na tela de cadastro simples');
    });
  });
}
