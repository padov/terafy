import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terafy/features/home/bloc/home_bloc_models.dart';
import 'package:terafy/features/home/widgets/today_agenda.dart';

void main() {
  group('TodayAgenda', () {
    testWidgets('exibe estado vazio quando não há compromissos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TodayAgenda(appointments: const [])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.event_available), findsOneWidget);
    });

    testWidgets('renderiza lista de compromissos', (tester) async {
      final appointments = [
        Appointment(
          id: '1',
          patientName: 'João Silva',
          time: '09:00',
          serviceType: 'Consulta',
          status: AppointmentStatus.confirmed,
          startTime: DateTime.now(),
        ),
        Appointment(
          id: '2',
          patientName: 'Maria Santos',
          time: '10:00',
          serviceType: 'Terapia',
          status: AppointmentStatus.reserved,
          startTime: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TodayAgenda(appointments: appointments)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('Consulta'), findsOneWidget);
      expect(find.text('Terapia'), findsOneWidget);
    });

    testWidgets('exibe ícone correto para status confirmed', (tester) async {
      final appointments = [
        Appointment(
          id: '1',
          patientName: 'João Silva',
          time: '09:00',
          serviceType: 'Consulta',
          status: AppointmentStatus.confirmed,
          startTime: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TodayAgenda(appointments: appointments)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('exibe ícone correto para status reserved', (tester) async {
      final appointments = [
        Appointment(
          id: '1',
          patientName: 'João Silva',
          time: '09:00',
          serviceType: 'Consulta',
          status: AppointmentStatus.reserved,
          startTime: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TodayAgenda(appointments: appointments)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('exibe ícone correto para status completed', (tester) async {
      final appointments = [
        Appointment(
          id: '1',
          patientName: 'João Silva',
          time: '09:00',
          serviceType: 'Consulta',
          status: AppointmentStatus.completed,
          startTime: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TodayAgenda(appointments: appointments)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('exibe ícone correto para status cancelled', (tester) async {
      final appointments = [
        Appointment(
          id: '1',
          patientName: 'João Silva',
          time: '09:00',
          serviceType: 'Consulta',
          status: AppointmentStatus.cancelled,
          startTime: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TodayAgenda(appointments: appointments)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('chama callback ao clicar em Ver todas', (tester) async {
      var seeAllTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayAgenda(
              appointments: const [],
              onSeeAll: () {
                seeAllTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final seeAllButton = find.byType(TextButton);
      await tester.tap(seeAllButton);
      await tester.pumpAndSettle();

      expect(seeAllTapped, true);
    });

    testWidgets('exibe ícone de calendário no título', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TodayAgenda(appointments: const [])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('renderiza múltiplos compromissos corretamente', (tester) async {
      final appointments = List.generate(
        3,
        (index) => Appointment(
          id: '$index',
          patientName: 'Paciente $index',
          time: '${9 + index}:00',
          serviceType: 'Consulta',
          status: AppointmentStatus.confirmed,
          startTime: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TodayAgenda(appointments: appointments)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paciente 0'), findsOneWidget);
      expect(find.text('Paciente 1'), findsOneWidget);
      expect(find.text('Paciente 2'), findsOneWidget);
    });
  });
}
