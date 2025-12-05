import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terafy/features/signup/widgets/simple_signup_form.dart';

void main() {
  group('SimpleSignupForm', () {
    testWidgets('renderiza campos de email, senha e confirmação de senha', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SimpleSignupForm(onSignup: ({required String email, required String password}) {})),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se os campos estão presentes
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(3)); // Email, senha, confirmação

      // Verifica se há um botão de cadastro
      final signupButton = find.textContaining('Criar conta');
      expect(signupButton, findsOneWidget);
    });

    testWidgets('valida email obrigatório', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SimpleSignupForm(onSignup: ({required String email, required String password}) {})),
        ),
      );
      await tester.pumpAndSettle();

      final signupButton = find.textContaining('Criar conta');

      // Tenta submeter sem preencher email
      await tester.tap(signupButton);
      await tester.pumpAndSettle();

      // Verifica se a mensagem de erro aparece
      expect(find.text('Email é obrigatório'), findsOneWidget);
    });

    testWidgets('valida formato de email', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SimpleSignupForm(onSignup: ({required String email, required String password}) {})),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      final signupButton = find.textContaining('Criar conta');

      // Preenche email inválido
      await tester.enterText(textFields.first, 'email-invalido');
      await tester.tap(signupButton);
      await tester.pumpAndSettle();

      // Verifica se a mensagem de erro aparece
      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('valida confirmação de senha', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SimpleSignupForm(onSignup: ({required String email, required String password}) {})),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      final signupButton = find.textContaining('Criar conta');

      // Preenche email válido
      await tester.enterText(textFields.first, 'teste@terafy.app.br');
      // Preenche senha
      await tester.enterText(textFields.at(1), 'senha123');
      // Preenche confirmação diferente
      await tester.enterText(textFields.at(2), 'senha456');
      await tester.tap(signupButton);
      await tester.pumpAndSettle();

      // Verifica se a mensagem de erro aparece
      expect(find.textContaining('senhas'), findsOneWidget);
    });

    testWidgets('chama onSignup quando formulário é válido', (tester) async {
      bool signupCalled = false;
      String? signupEmail;
      String? signupPassword;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleSignupForm(
              onSignup: ({required String email, required String password}) {
                signupCalled = true;
                signupEmail = email;
                signupPassword = password;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      final signupButton = find.textContaining('Criar conta');

      // Preenche todos os campos corretamente
      await tester.enterText(textFields.first, 'teste@terafy.app.br');
      await tester.enterText(textFields.at(1), 'senha123');
      await tester.enterText(textFields.at(2), 'senha123');
      await tester.tap(signupButton);
      await tester.pumpAndSettle();

      // Verifica se onSignup foi chamado
      expect(signupCalled, isTrue);
      expect(signupEmail, 'teste@terafy.app.br');
      expect(signupPassword, 'senha123');
    });
  });
}
