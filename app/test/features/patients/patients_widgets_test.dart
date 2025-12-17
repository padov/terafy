import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terafy/features/patients/models/patient.dart';
import 'package:terafy/features/patients/widgets/patient_card.dart';

void main() {
  group('PatientCard', () {
    final patient = Patient(
      id: '1',
      therapistId: '1',
      fullName: 'João Silva',
      phone: '11999999999',
      status: PatientStatus.active,
      totalSessions: 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('renderiza dados do paciente corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientCard(
              patient: patient,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se o nome do paciente está presente
      expect(find.text('João Silva'), findsOneWidget);

      // Verifica se o telefone está presente
      expect(find.textContaining('11999999999'), findsOneWidget);
    });

    testWidgets('chama onTap quando card é clicado', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientCard(
              patient: patient,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clica no card
      await tester.tap(find.byType(PatientCard));
      await tester.pumpAndSettle();

      // Verifica se onTap foi chamado
      expect(tapped, isTrue);
    });

    testWidgets('renderiza avatar com iniciais quando não há foto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientCard(
              patient: patient,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se há um CircleAvatar
      expect(find.byType(CircleAvatar), findsOneWidget);

      // Verifica se as iniciais estão presentes
      expect(find.text('JS'), findsOneWidget);
    });
  });
}

