import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terafy/features/agenda/models/appointment.dart';
import 'package:terafy/features/schedule/widgets/appointment_card.dart' as schedule;

void main() {
  group('AppointmentCard', () {
    final appointment = Appointment(
      id: '1',
      therapistId: '1',
      patientId: '1',
      patientName: 'João Silva',
      dateTime: DateTime.now().add(Duration(days: 1, hours: 10)),
      duration: Duration(hours: 1),
      type: AppointmentType.session,
      status: AppointmentStatus.reserved,
      recurrence: RecurrenceType.none,
      reminders: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('renderiza dados do appointment corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: schedule.AppointmentCard(
              appointment: appointment,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se o nome do paciente está presente
      expect(find.textContaining('João'), findsOneWidget);

      // Verifica se há um Container (card)
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('chama onTap quando card é clicado', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: schedule.AppointmentCard(
              appointment: appointment,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clica no card
      await tester.tap(find.byType(schedule.AppointmentCard));
      await tester.pumpAndSettle();

      // Verifica se onTap foi chamado
      expect(tapped, isTrue);
    });

    testWidgets('renderiza ícone de status corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: schedule.AppointmentCard(
              appointment: appointment,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se há um ícone (indicador de status)
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}


