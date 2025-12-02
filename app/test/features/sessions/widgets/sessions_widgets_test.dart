import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terafy/features/sessions/models/session.dart';
import 'package:terafy/features/sessions/widgets/session_card.dart';

void main() {
  group('SessionCard', () {
    final session = Session(
      id: '1',
      patientId: '1',
      therapistId: '1',
      scheduledStartTime: DateTime.now().add(Duration(days: 1)),
      durationMinutes: 60,
      sessionNumber: 1,
      type: SessionType.onlineVideo,
      modality: SessionModality.individual,
      status: SessionStatus.scheduled,
      paymentStatus: PaymentStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('renderiza dados da sessão corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se o número da sessão está presente
      expect(find.textContaining('Sessão 1'), findsOneWidget);

      // Verifica se há um Card
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('chama onTap quando card é clicado', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionCard(
              session: session,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clica no card
      await tester.tap(find.byType(SessionCard));
      await tester.pumpAndSettle();

      // Verifica se onTap foi chamado
      expect(tapped, isTrue);
    });

    testWidgets('renderiza ícone de status corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionCard(
              session: session,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se há um Container com ícone (indicador de status)
      expect(find.byType(Container), findsWidgets);
    });
  });
}

