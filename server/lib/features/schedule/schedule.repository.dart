import 'package:common/common.dart';
import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/core/database/rls_context.dart';

class ScheduleRepository {
  ScheduleRepository(this._dbConnection);

  final DBConnection _dbConnection;

  Future<TherapistScheduleSettings?> getTherapistSettings({
    required int therapistId,
    required int userId,
    String? userRole,
    bool bypassRLS = false,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: therapistId);
      }

      final result = await conn.execute(
        Sql.named('''
        SELECT therapist_id,
               working_hours,
               session_duration_minutes,
               break_minutes,
               locations,
               days_off,
               holidays,
               custom_blocks,
               reminder_enabled,
               reminder_default_offset::text,
               reminder_default_channel::text,
               cancellation_policy,
               created_at,
               updated_at
        FROM therapist_schedule_settings
        WHERE therapist_id = @therapist_id
      '''),
        parameters: {'therapist_id': therapistId},
      );

      if (result.isEmpty) {
        return null;
      }

      return TherapistScheduleSettings.fromMap(result.first.toColumnMap());
    });
  }

  Future<TherapistScheduleSettings> upsertTherapistSettings({
    required TherapistScheduleSettings settings,
    required int userId,
    String? userRole,
    bool bypassRLS = false,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: settings.therapistId);
      }

      final data = settings.toDatabaseMap();

      final result = await conn.execute(
        Sql.named('''
        INSERT INTO therapist_schedule_settings (
          therapist_id,
          working_hours,
          session_duration_minutes,
          break_minutes,
          locations,
          days_off,
          holidays,
          custom_blocks,
          reminder_enabled,
          reminder_default_offset,
          reminder_default_channel,
          cancellation_policy,
          created_at,
          updated_at
        ) VALUES (
          @therapist_id,
          CAST(@working_hours AS JSONB),
          @session_duration_minutes,
          @break_minutes,
          @locations,
          @days_off,
          @holidays,
          CAST(@custom_blocks AS JSONB),
          @reminder_enabled,
          @reminder_default_offset::reminder_offset,
          @reminder_default_channel::reminder_channel,
          CAST(@cancellation_policy AS JSONB),
          NOW(),
          NOW()
        )
        ON CONFLICT (therapist_id) DO UPDATE
        SET working_hours = CAST(@working_hours AS JSONB),
            session_duration_minutes = @session_duration_minutes,
            break_minutes = @break_minutes,
            locations = @locations,
            days_off = @days_off,
            holidays = @holidays,
            custom_blocks = CAST(@custom_blocks AS JSONB),
            reminder_enabled = @reminder_enabled,
            reminder_default_offset = @reminder_default_offset::reminder_offset,
            reminder_default_channel = @reminder_default_channel::reminder_channel,
            cancellation_policy = CAST(@cancellation_policy AS JSONB),
            updated_at = NOW()
        RETURNING therapist_id,
                  working_hours,
                  session_duration_minutes,
                  break_minutes,
                  locations,
                  days_off,
                  holidays,
                  custom_blocks,
                  reminder_enabled,
                  reminder_default_offset::text,
                  reminder_default_channel::text,
                  cancellation_policy,
                  created_at,
                  updated_at;
      '''),
        parameters: data,
      );

      final map = result.first.toColumnMap();
      return TherapistScheduleSettings.fromMap(map);
    });
  }

  Future<List<Appointment>> listAppointments({
    required int therapistId,
    required DateTime start,
    required DateTime end,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(
          conn: conn,
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? therapistId,
        );
      }

      final result = await conn.execute(
        Sql.named('''
        SELECT a.id,
               a.therapist_id,
               a.patient_id,
               a.parent_appointment_id,
               a.session_id,
               p.full_name AS patient_name,
               a.type::text AS type,
               a.status::text AS status,
               a.title,
               a.description,
               a.start_time,
               a.end_time,
               a.recurrence_rule,
               a.recurrence_end,
               a.recurrence_exceptions,
               a.location,
               a.online_link,
               a.color,
               a.reminders,
               a.reminder_sent_at,
               a.patient_confirmed_at,
               a.patient_arrival_at,
               a.waiting_room_status,
               a.cancellation_reason,
               a.notes,
               a.created_at,
               a.updated_at
        FROM appointments a
        LEFT JOIN patients p ON p.id = a.patient_id
        WHERE a.therapist_id = @therapist_id
          AND a.start_time < @end_time
          AND a.end_time > @start_time
        ORDER BY a.start_time ASC
      '''),
        parameters: {'therapist_id': therapistId, 'start_time': start, 'end_time': end},
      );

      return result.map((row) => Appointment.fromMap(row.toColumnMap())).toList();
    });
  }

  Future<Appointment?> getAppointmentById({
    required int appointmentId,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: accountId);
      }

      final result = await conn.execute(
        Sql.named('''
        SELECT a.id,
               a.therapist_id,
               a.patient_id,
               a.parent_appointment_id,
               a.session_id,
               p.full_name AS patient_name,
               a.type::text AS type,
               a.status::text AS status,
               a.title,
               a.description,
               a.start_time,
               a.end_time,
               a.recurrence_rule,
               a.recurrence_end,
               a.recurrence_exceptions,
               a.location,
               a.online_link,
               a.color,
               a.reminders,
               a.reminder_sent_at,
               a.patient_confirmed_at,
               a.patient_arrival_at,
               a.waiting_room_status,
               a.cancellation_reason,
               a.notes,
               a.created_at,
               a.updated_at
        FROM appointments a
        LEFT JOIN patients p ON p.id = a.patient_id
        WHERE a.id = @id
      '''),
        parameters: {'id': appointmentId},
      );

      if (result.isEmpty) {
        return null;
      }

      return Appointment.fromMap(result.first.toColumnMap());
    });
  }

  Future<Appointment> createAppointment({
    required Appointment appointment,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(
          conn: conn,
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? appointment.therapistId,
        );
      }

      final data = appointment.toDatabaseMap();
      // Remove session_id da criação - ele só é definido quando uma sessão é criada
      data.remove('session_id');

      final result = await conn.execute(
        Sql.named('''
        INSERT INTO appointments (
          therapist_id,
          patient_id,
          parent_appointment_id,
          type,
          status,
          title,
          description,
          start_time,
          end_time,
          recurrence_rule,
          recurrence_end,
          recurrence_exceptions,
          location,
          online_link,
          color,
          reminders,
          reminder_sent_at,
          patient_confirmed_at,
          patient_arrival_at,
          waiting_room_status,
          cancellation_reason,
          notes,
          created_at,
          updated_at
        ) VALUES (
          @therapist_id,
          @patient_id,
          @parent_appointment_id,
          @type::appointment_type,
          @status::appointment_status,
          @title,
          @description,
          @start_time,
          @end_time,
          CAST(@recurrence_rule AS JSONB),
          @recurrence_end,
          @recurrence_exceptions,
          @location,
          @online_link,
          @color,
          CAST(@reminders AS JSONB),
          @reminder_sent_at,
          @patient_confirmed_at,
          @patient_arrival_at,
          @waiting_room_status,
          @cancellation_reason,
          @notes,
          NOW(),
          NOW()
        )
        RETURNING id,
                  therapist_id,
                  patient_id,
                  parent_appointment_id,
                  session_id,
                  (SELECT full_name FROM patients WHERE id = patient_id) AS patient_name,
                  type::text AS type,
                  status::text AS status,
                  title,
                  description,
                  start_time,
                  end_time,
                  recurrence_rule,
                  recurrence_end,
                  recurrence_exceptions,
                  location,
                  online_link,
                  color,
                  reminders,
                  reminder_sent_at,
                  patient_confirmed_at,
                  patient_arrival_at,
                  waiting_room_status,
                  cancellation_reason,
                  notes,
                  created_at,
                  updated_at
      '''),
        parameters: data,
      );

      return Appointment.fromMap(result.first.toColumnMap());
    });
  }

  Future<Appointment?> updateAppointment({
    required int appointmentId,
    required Appointment appointment,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(
          conn: conn,
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? appointment.therapistId,
        );
      }

      final data = appointment.toDatabaseMap();
      // Remove therapist_id pois não deve ser atualizado (é uma chave estrangeira)
      data.remove('therapist_id');

      final result = await conn.execute(
        Sql.named('''
        UPDATE appointments
        SET patient_id = @patient_id,
            parent_appointment_id = @parent_appointment_id,
            session_id = @session_id,
            type = @type::appointment_type,
            status = @status::appointment_status,
            title = @title,
            description = @description,
            start_time = @start_time,
            end_time = @end_time,
            recurrence_rule = CAST(@recurrence_rule AS JSONB),
            recurrence_end = @recurrence_end,
            recurrence_exceptions = @recurrence_exceptions,
            location = @location,
            online_link = @online_link,
            color = @color,
            reminders = CAST(@reminders AS JSONB),
            reminder_sent_at = @reminder_sent_at,
            patient_confirmed_at = @patient_confirmed_at,
            patient_arrival_at = @patient_arrival_at,
            waiting_room_status = @waiting_room_status,
            cancellation_reason = @cancellation_reason,
            notes = @notes,
            updated_at = NOW()
        WHERE id = @id
        RETURNING id,
                  therapist_id,
                  patient_id,
                  parent_appointment_id,
                  session_id,
                  (SELECT full_name FROM patients WHERE id = patient_id) AS patient_name,
                  type::text AS type,
                  status::text AS status,
                  title,
                  description,
                  start_time,
                  end_time,
                  recurrence_rule,
                  recurrence_end,
                  recurrence_exceptions,
                  location,
                  online_link,
                  color,
                  reminders,
                  reminder_sent_at,
                  patient_confirmed_at,
                  patient_arrival_at,
                  waiting_room_status,
                  cancellation_reason,
                  notes,
                  created_at,
                  updated_at
      '''),
        parameters: {...data, 'id': appointmentId},
      );

      if (result.isEmpty) {
        return null;
      }

      return Appointment.fromMap(result.first.toColumnMap());
    });
  }

  Future<bool> deleteAppointment({
    required int appointmentId,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: accountId);
      }

      final result = await conn.execute(
        Sql.named('DELETE FROM appointments WHERE id = @id RETURNING id;'),
        parameters: {'id': appointmentId},
      );

      return result.isNotEmpty;
    });
  }
}
