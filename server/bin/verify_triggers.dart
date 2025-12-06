import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/core/config/env_config.dart';
import 'package:common/common.dart';

void main() async {
  print('Iniciando verificação de triggers...');
  EnvConfig.load(filename: 'server/.env');
  AppLogger.config(isDebugMode: true);

  final dbConnection = DBConnection();
  await dbConnection.initialize();

  try {
    await dbConnection.withConnection((conn) async {
      // 1. Create a Therapist & Patient (if needed, or reuse existing)
      // Simplified: Assuming ID 1 exists for simplicity or creating temp ones
      // Actually safer to create temp data.

      print('Criando dados de teste...');
      // Therapist
      final therapistResult = await conn.execute(
        Sql.named(
          'INSERT INTO users (email, password_hash, role) VALUES (@email, \'hash\', \'therapist\') RETURNING id',
        ),
        parameters: {'email': 'trigger_test_${DateTime.now().millisecondsSinceEpoch}@test.com'},
      );
      final therapistId = therapistResult.first[0] as int;

      await conn.execute(
        Sql.named('INSERT INTO therapists (id, user_id, name, email) VALUES (@id, @id, @name, @email)'),
        parameters: {
          'id': therapistId,
          'name': 'TriggerTest Therapist',
          'email': 'trigger_test_${DateTime.now().millisecondsSinceEpoch}@test.com',
        },
      );

      // Patient
      final patientResult = await conn.execute(
        Sql.named('INSERT INTO patients (full_name, therapist_id) VALUES (@name, @tid) RETURNING id'),
        parameters: {'name': 'TriggerTest Patient', 'tid': therapistId},
      );
      final patientId = patientResult.first[0] as int;

      // 2. Create Appointment (Reserved/Scheduled)
      print('Criando agendamento...');
      final now = DateTime.now().toUtc();
      final end = now.add(Duration(hours: 1));

      final apptResult = await conn.execute(
        Sql.named('''
         INSERT INTO appointments (therapist_id, patient_id, start_time, end_time, status, type) 
         VALUES (@tid, @pid, @start, @end, 'reserved', 'session') RETURNING id
       '''),
        parameters: {'tid': therapistId, 'pid': patientId, 'start': now, 'end': end},
      );
      final apptId = apptResult.first[0] as int;

      // 3. Create Session linked to Appointment (Status: scheduled)
      print('Criando sessão vinculada...');
      final sessionResult = await conn.execute(
        Sql.named('''
         INSERT INTO sessions (patient_id, therapist_id, appointment_id, scheduled_start_time, duration_minutes, session_number, status)
         VALUES (@pid, @tid, @aid, @start, 60, 1, 'scheduled') RETURNING id
       '''),
        parameters: {'pid': patientId, 'tid': therapistId, 'aid': apptId, 'start': now},
      );
      final sessionId = sessionResult.first[0] as int;

      // 4. Test Case A: scheduled -> inProgress (Should be completed)
      print('Teste A: scheduled -> inProgress');
      await conn.execute(
        Sql.named('''
         UPDATE sessions SET status = 'inProgress' WHERE id = @sid
       '''),
        parameters: {'sid': sessionId},
      );

      var apptCheck = await conn.execute(
        Sql.named('SELECT status FROM appointments WHERE id = @aid'),
        parameters: {'aid': apptId},
      );
      var statusBytes = apptCheck.first[0] as UndecodedBytes;
      var status = utf8.decode(statusBytes.bytes);
      print('  Status do agendamento: $status (Esperado: completed)');
      if (status != 'completed') throw Exception('Falha Teste A');

      // Reset
      await conn.execute(
        Sql.named("UPDATE appointments SET status = 'reserved' WHERE id = @aid"),
        parameters: {'aid': apptId},
      );
      await conn.execute(
        Sql.named("UPDATE sessions SET status = 'scheduled' WHERE id = @sid"),
        parameters: {'sid': sessionId},
      );

      // 5. Test Case B: scheduled -> cancelledByPatient (Should be cancelled)
      print('Teste B: scheduled -> cancelledByPatient');
      await conn.execute(
        Sql.named('''
         UPDATE sessions SET status = 'cancelledByPatient' WHERE id = @sid
       '''),
        parameters: {'sid': sessionId},
      );

      apptCheck = await conn.execute(
        Sql.named('SELECT status FROM appointments WHERE id = @aid'),
        parameters: {'aid': apptId},
      );
      status = apptCheck.first[0].toString();
      print('  Status do agendamento: $status (Esperado: cancelled)');
      if (status != 'cancelled') throw Exception('Falha Teste B');

      // Cleanup
      print('Limpando dados...');
      await conn.execute(
        Sql.named('DELETE FROM users WHERE id = @id'),
        parameters: {'id': therapistId},
      ); // Cascade should clean up
    });
    print('Verificação concluída com sucesso!');
  } catch (e) {
    print('Erro na verificação: $e');
    exit(1);
  } finally {
    exit(0);
  }
}
