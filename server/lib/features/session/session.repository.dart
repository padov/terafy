import 'dart:convert';

import 'package:common/common.dart';
import 'package:postgres/postgres.dart' hide Session;
import 'package:server/core/database/db_connection.dart';
import 'package:server/core/database/rls_context.dart';

class SessionRepository {
  SessionRepository(this._dbConnection);

  final DBConnection _dbConnection;

  Future<Session> createSession({
    required Session session,
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
        await RLSContext.setContext(
          conn: conn,
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? session.therapistId,
        );
      }

      final data = session.toDatabaseMap();

      // Converter listas para JSON string para campos JSONB
      // O toDatabaseMap já retorna listas, então sempre converter para JSON string
      final topicsDiscussed = data['topics_discussed'];
      if (topicsDiscussed != null && topicsDiscussed is List) {
        data['topics_discussed'] = jsonEncode(topicsDiscussed);
      } else {
        data['topics_discussed'] = '[]';
      }

      final interventionsUsed = data['interventions_used'];
      if (interventionsUsed != null && interventionsUsed is List) {
        data['interventions_used'] = jsonEncode(interventionsUsed);
      } else {
        data['interventions_used'] = '[]';
      }

      final attachments = data['attachments'];
      if (attachments != null && attachments is List) {
        data['attachments'] = jsonEncode(attachments);
      } else {
        data['attachments'] = '[]';
      }

      final result = await conn.execute(
        Sql.named('''
        INSERT INTO sessions (
          patient_id,
          therapist_id,
          appointment_id,
          scheduled_start_time,
          scheduled_end_time,
          duration_minutes,
          session_number,
          type,
          modality,
          location,
          online_room_link,
          status,
          cancellation_reason,
          cancellation_time,
          charged_amount,
          payment_status,
          patient_mood,
          topics_discussed,
          session_notes,
          observed_behavior,
          interventions_used,
          resources_used,
          homework,
          patient_reactions,
          progress_observed,
          difficulties_identified,
          next_steps,
          next_session_goals,
          needs_referral,
          current_risk,
          important_observations,
          presence_confirmation_time,
          reminder_sent,
          reminder_sent_time,
          patient_rating,
          attachments
        ) VALUES (
          @patient_id,
          @therapist_id,
          @appointment_id,
          @scheduled_start_time,
          @scheduled_end_time,
          @duration_minutes,
          @session_number,
          @type::session_type,
          @modality::session_modality,
          @location,
          @online_room_link,
          @status::session_status,
          @cancellation_reason,
          @cancellation_time,
          @charged_amount,
          @payment_status::payment_status,
          @patient_mood,
          CAST(@topics_discussed AS JSONB),
          @session_notes,
          @observed_behavior,
          CAST(@interventions_used AS JSONB),
          @resources_used,
          @homework,
          @patient_reactions,
          @progress_observed,
          @difficulties_identified,
          @next_steps,
          @next_session_goals,
          @needs_referral,
          @current_risk::risk_level,
          @important_observations,
          @presence_confirmation_time,
          @reminder_sent,
          @reminder_sent_time,
          @patient_rating,
          CAST(@attachments AS JSONB)
        )
        RETURNING id,
                  patient_id,
                  therapist_id,
                  appointment_id,
                  scheduled_start_time,
                  scheduled_end_time,
                  duration_minutes,
                  session_number,
                  type::text AS type,
                  modality::text AS modality,
                  location,
                  online_room_link,
                  status::text AS status,
                  cancellation_reason,
                  cancellation_time,
                  charged_amount,
                  payment_status::text AS payment_status,
                  patient_mood,
                  topics_discussed,
                  session_notes,
                  observed_behavior,
                  interventions_used,
                  resources_used,
                  homework,
                  patient_reactions,
                  progress_observed,
                  difficulties_identified,
                  next_steps,
                  next_session_goals,
                  needs_referral,
                  current_risk::text AS current_risk,
                  important_observations,
                  presence_confirmation_time,
                  reminder_sent,
                  reminder_sent_time,
                  patient_rating,
                  attachments,
                  created_at,
                  updated_at
      '''),
        parameters: data,
      );

      if (result.isEmpty) {
        throw Exception('Falha ao criar sessão');
      }

      return Session.fromMap(result.first.toColumnMap());
    });
  }

  Future<Session?> getSessionById({
    required int sessionId,
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
        SELECT id,
               patient_id,
               therapist_id,
               appointment_id,
               scheduled_start_time,
               scheduled_end_time,
               duration_minutes,
               session_number,
               type::text AS type,
               modality::text AS modality,
               location,
               online_room_link,
               status::text AS status,
               cancellation_reason,
               cancellation_time,
               charged_amount,
               payment_status::text AS payment_status,
               patient_mood,
               topics_discussed,
               session_notes,
               observed_behavior,
               interventions_used,
               resources_used,
               homework,
               patient_reactions,
               progress_observed,
               difficulties_identified,
               next_steps,
               next_session_goals,
               needs_referral,
               current_risk::text AS current_risk,
               important_observations,
               presence_confirmation_time,
               reminder_sent,
               reminder_sent_time,
               patient_rating,
               attachments,
               created_at,
               updated_at
        FROM sessions
        WHERE id = @id
      '''),
        parameters: {'id': sessionId},
      );

      if (result.isEmpty) {
        return null;
      }

      return Session.fromMap(result.first.toColumnMap());
    });
  }

  Future<List<Session>> listSessions({
    int? patientId,
    int? therapistId,
    int? appointmentId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
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
        await RLSContext.setContext(
          conn: conn,
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? therapistId,
        );
      }

      final buffer = StringBuffer('''
      SELECT id,
             patient_id,
             therapist_id,
             appointment_id,
             scheduled_start_time,
             scheduled_end_time,
             duration_minutes,
             session_number,
             type::text AS type,
             modality::text AS modality,
             location,
             online_room_link,
             status::text AS status,
             cancellation_reason,
             cancellation_time,
             charged_amount,
             payment_status::text AS payment_status,
             patient_mood,
             topics_discussed,
             session_notes,
             observed_behavior,
             interventions_used,
             resources_used,
             homework,
             patient_reactions,
             progress_observed,
             difficulties_identified,
             next_steps,
             next_session_goals,
             needs_referral,
             current_risk::text AS current_risk,
             important_observations,
             presence_confirmation_time,
             reminder_sent,
             reminder_sent_time,
             patient_rating,
             attachments,
             created_at,
             updated_at
      FROM sessions
      WHERE 1=1
    ''');

      final parameters = <String, dynamic>{};

      if (patientId != null) {
        buffer.write(' AND patient_id = @patient_id');
        parameters['patient_id'] = patientId;
      }

      if (therapistId != null) {
        buffer.write(' AND therapist_id = @therapist_id');
        parameters['therapist_id'] = therapistId;
      }

      if (appointmentId != null) {
        buffer.write(' AND appointment_id = @appointment_id');
        parameters['appointment_id'] = appointmentId;
      }

      if (status != null) {
        buffer.write(' AND status = @status::session_status');
        parameters['status'] = status;
      }

      if (startDate != null) {
        buffer.write(' AND scheduled_start_time >= @start_date');
        parameters['start_date'] = startDate;
      }

      if (endDate != null) {
        buffer.write(' AND scheduled_start_time <= @end_date');
        parameters['end_date'] = endDate;
      }

      buffer.write(' ORDER BY scheduled_start_time DESC');

      final result = await conn.execute(Sql.named(buffer.toString()), parameters: parameters);

      return result.map((row) => Session.fromMap(row.toColumnMap())).toList();
    });
  }

  Future<Session?> updateSession({
    required int sessionId,
    required Session session,
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
        await RLSContext.setContext(
          conn: conn,
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? session.therapistId,
        );
      }

      final data = session.toDatabaseMap();
      // Remove campos que não devem ser atualizados
      data.remove('session_number'); // Não pode ser alterado manualmente

      // Converter listas para JSON string para campos JSONB
      // O toDatabaseMap já retorna listas, então sempre converter para JSON string
      final topicsDiscussed = data['topics_discussed'];
      if (topicsDiscussed != null && topicsDiscussed is List) {
        data['topics_discussed'] = jsonEncode(topicsDiscussed);
      } else {
        data['topics_discussed'] = '[]';
      }

      final interventionsUsed = data['interventions_used'];
      if (interventionsUsed != null && interventionsUsed is List) {
        data['interventions_used'] = jsonEncode(interventionsUsed);
      } else {
        data['interventions_used'] = '[]';
      }

      final attachments = data['attachments'];
      if (attachments != null && attachments is List) {
        data['attachments'] = jsonEncode(attachments);
      } else {
        data['attachments'] = '[]';
      }

      final result = await conn.execute(
        Sql.named('''
        UPDATE sessions
        SET patient_id = @patient_id,
            therapist_id = @therapist_id,
            appointment_id = @appointment_id,
            scheduled_start_time = @scheduled_start_time,
            scheduled_end_time = @scheduled_end_time,
            duration_minutes = @duration_minutes,
            type = @type::session_type,
            modality = @modality::session_modality,
            location = @location,
            online_room_link = @online_room_link,
            status = @status::session_status,
            cancellation_reason = @cancellation_reason,
            cancellation_time = @cancellation_time,
            charged_amount = @charged_amount,
            payment_status = @payment_status::payment_status,
            patient_mood = @patient_mood,
            topics_discussed = CAST(@topics_discussed AS JSONB),
            session_notes = @session_notes,
            observed_behavior = @observed_behavior,
            interventions_used = CAST(@interventions_used AS JSONB),
            resources_used = @resources_used,
            homework = @homework,
            patient_reactions = @patient_reactions,
            progress_observed = @progress_observed,
            difficulties_identified = @difficulties_identified,
            next_steps = @next_steps,
            next_session_goals = @next_session_goals,
            needs_referral = @needs_referral,
            current_risk = @current_risk::risk_level,
            important_observations = @important_observations,
            presence_confirmation_time = @presence_confirmation_time,
            reminder_sent = @reminder_sent,
            reminder_sent_time = @reminder_sent_time,
            patient_rating = @patient_rating,
            attachments = CAST(@attachments AS JSONB),
            updated_at = NOW()
        WHERE id = @id
        RETURNING id,
                  patient_id,
                  therapist_id,
                  appointment_id,
                  scheduled_start_time,
                  scheduled_end_time,
                  duration_minutes,
                  session_number,
                  type::text AS type,
                  modality::text AS modality,
                  location,
                  online_room_link,
                  status::text AS status,
                  cancellation_reason,
                  cancellation_time,
                  charged_amount,
                  payment_status::text AS payment_status,
                  patient_mood,
                  topics_discussed,
                  session_notes,
                  observed_behavior,
                  interventions_used,
                  resources_used,
                  homework,
                  patient_reactions,
                  progress_observed,
                  difficulties_identified,
                  next_steps,
                  next_session_goals,
                  needs_referral,
                  current_risk::text AS current_risk,
                  important_observations,
                  presence_confirmation_time,
                  reminder_sent,
                  reminder_sent_time,
                  patient_rating,
                  attachments,
                  created_at,
                  updated_at
      '''),
        parameters: {...data, 'id': sessionId},
      );

      if (result.isEmpty) {
        return null;
      }

      return Session.fromMap(result.first.toColumnMap());
    });
  }

  Future<bool> deleteSession({
    required int sessionId,
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
        Sql.named('DELETE FROM sessions WHERE id = @id RETURNING id;'),
        parameters: {'id': sessionId},
      );

      return result.isNotEmpty;
    });
  }

  Future<int> getNextSessionNumber({
    required int patientId,
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
          SELECT COALESCE(MAX(session_number), 0) + 1 AS next_number
          FROM sessions
          WHERE patient_id = @patient_id
        '''),
        parameters: {'patient_id': patientId},
      );

      if (result.isEmpty) {
        return 1;
      }

      return (result.first.toColumnMap()['next_number'] as int);
    });
  }
}
