import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_field.dart';
import 'package:terafy/features/anamnesis/widgets/anamnesis_field_widget.dart';

void main() {
  group('AnamnesisFieldWidget', () {
    testWidgets('renderiza campo de texto corretamente', (tester) async {
      final field = AnamnesisField(
        id: 'test',
        label: 'Campo de Teste',
        type: AnamnesisFieldType.text,
        required: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnamnesisFieldWidget(
              field: field,
              value: '',
              onChanged: (value) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se o label está presente
      expect(find.text('Campo de Teste'), findsOneWidget);

      // Verifica se há um campo de texto
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('exibe asterisco quando campo é obrigatório', (tester) async {
      final field = AnamnesisField(
        id: 'test',
        label: 'Campo Obrigatório',
        type: AnamnesisFieldType.text,
        required: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnamnesisFieldWidget(
              field: field,
              value: '',
              onChanged: (value) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se há um asterisco (indicador de obrigatório)
      expect(find.textContaining('*'), findsOneWidget);
    });

    testWidgets('renderiza campo textarea quando tipo é textarea', (tester) async {
      final field = AnamnesisField(
        id: 'test',
        label: 'Descrição',
        type: AnamnesisFieldType.textarea,
        required: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnamnesisFieldWidget(
              field: field,
              value: '',
              onChanged: (value) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se há um campo de texto (TextFormField com maxLines)
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('chama onChanged quando valor é alterado', (tester) async {
      String? changedValue;

      final field = AnamnesisField(
        id: 'test',
        label: 'Campo de Teste',
        type: AnamnesisFieldType.text,
        required: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnamnesisFieldWidget(
              field: field,
              value: '',
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Digita no campo
      final textField = find.byType(TextFormField);
      await tester.enterText(textField, 'Novo valor');
      await tester.pumpAndSettle();

      // Verifica se onChanged foi chamado
      expect(changedValue, 'Novo valor');
    });
  });
}

