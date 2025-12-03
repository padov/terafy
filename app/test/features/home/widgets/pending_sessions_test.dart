import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terafy/features/home/bloc/home_bloc_models.dart';
import 'package:terafy/features/home/widgets/pending_sessions.dart';

void main() {
  group('PendingSessions', () {
    testWidgets('exibe estado vazio quando não há sessões pendentes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingSessions(sessions: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('Nenhuma sessão pendente'), findsOneWidget);
    });

    testWidgets('renderiza lista de sessões pendentes', (tester) async {
      final sessions = [
        PendingSessionItem(
          id: 1,
          sessionNumber: 5,
          patientId: 100,
          patientName: 'João Silva',
          scheduledStartTime: DateTime(2024, 12, 1, 14, 30),
          status: 'draft',
        ),
        PendingSessionItem(
          id: 2,
          sessionNumber: 3,
          patientId: 200,
          patientName: 'Maria Santos',
          scheduledStartTime: DateTime(2024, 12, 2, 10, 0),
          status: 'completed',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingSessions(sessions: sessions),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sessão #5'), findsOneWidget);
      expect(find.text('Sessão #3'), findsOneWidget);
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Maria Santos'), findsOneWidget);
    });

    testWidgets('exibe ícone e badge corretos para status draft', (tester) async {
      final sessions = [
        PendingSessionItem(
          id: 1,
          sessionNumber: 5,
          patientId: 100,
          patientName: 'João Silva',
          scheduledStartTime: DateTime.now(),
          status: 'draft',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PendingSessions(sessions: sessions),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.text('Rascunho'), findsOneWidget);
    });

    testWidgets('exibe ícone e badge corretos para status completed', (tester) async {
      final sessions = [
        PendingSessionItem(
          id: 1,
          sessionNumber: 5,
          patientId: 100,
          patientName: 'João Silva',
          scheduledStartTime: DateTime.now(),
          status: 'completed',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PendingSessions(sessions: sessions),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      expect(find.text('Sem Registro'), findsOneWidget);
    });

    testWidgets('formata data corretamente', (tester) async {
      final sessions = [
        PendingSessionItem(
          id: 1,
          sessionNumber: 5,
          patientId: 100,
          patientName: 'João Silva',
          scheduledStartTime: DateTime(2024, 12, 15, 14, 30),
          status: 'draft',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingSessions(sessions: sessions),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('15/12/2024'), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('exibe ícones de calendário e relógio', (tester) async {
      final sessions = [
        PendingSessionItem(
          id: 1,
          sessionNumber: 5,
          patientId: 100,
          patientName: 'João Silva',
          scheduledStartTime: DateTime.now(),
          status: 'draft',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingSessions(sessions: sessions),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('limita exibição a 5 sessões', (tester) async {
      final sessions = List.generate(
        10,
        (index) => PendingSessionItem(
          id: index,
          sessionNumber: index + 1,
          patientId: 100 + index,
          patientName: 'Paciente $index',
          scheduledStartTime: DateTime.now(),
          status: 'draft',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PendingSessions(sessions: sessions),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Deve exibir apenas as 5 primeiras
      expect(find.text('Paciente 0'), findsOneWidget);
      expect(find.text('Paciente 4'), findsOneWidget);
      expect(find.text('Paciente 5'), findsNothing);
      expect(find.text('Paciente 9'), findsNothing);
    });

    testWidgets('exibe botão Ver todas quando há sessões', (tester) async {
      final sessions = [
        PendingSessionItem(
          id: 1,
          sessionNumber: 5,
          patientId: 100,
          patientName: 'João Silva',
          scheduledStartTime: DateTime.now(),
          status: 'draft',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingSessions(
              sessions: sessions,
              onSeeAll: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ver todas'), findsOneWidget);
    });

    testWidgets('não exibe botão Ver todas quando não há sessões', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingSessions(
              sessions: const [],
              onSeeAll: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ver todas'), findsNothing);
    });

    testWidgets('chama callback ao clicar em Ver todas', (tester) async {
      var seeAllTapped = false;
      final sessions = [
        PendingSessionItem(
          id: 1,
          sessionNumber: 5,
          patientId: 100,
          patientName: 'João Silva',
          scheduledStartTime: DateTime.now(),
          status: 'draft',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingSessions(
              sessions: sessions,
              onSeeAll: () {
                seeAllTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver todas'));
      await tester.pumpAndSettle();

      expect(seeAllTapped, true);
    });

    testWidgets('exibe título Sessões Pendentes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingSessions(sessions: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sessões Pendentes'), findsOneWidget);
    });

    testWidgets('exibe ícone de nota no título', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PendingSessions(sessions: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_note), findsAtLeastNWidgets(1));
    });
  });
}
