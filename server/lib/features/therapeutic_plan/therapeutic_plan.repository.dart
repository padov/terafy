import 'package:common/common.dart';
import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/core/database/rls_context.dart';

class TherapeuticPlanRepository {
  TherapeuticPlanRepository(this._dbConnection);

  final DBConnection _dbConnection;

  // ============ THERAPEUTIC PLAN METHODS ============

  Future<TherapeuticPlan> createPlan({
    required TherapeuticPlan plan,
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
          accountId: accountId ?? plan.therapistId,
        );
      }

      final data = plan.toDatabaseMap();

      // O toDatabaseMap já faz jsonEncode para campos JSONB
      // Arrays TEXT[] são passados diretamente como List - PostgreSQL aceita List<String>

      final result = await conn.execute(
        Sql.named('''
        INSERT INTO therapeutic_plans (
          patient_id,
          therapist_id,
          approach,
          approach_other,
          recommended_frequency,
          session_duration_minutes,
          estimated_duration_months,
          main_techniques,
          intervention_strategies,
          resources_to_use,
          therapeutic_tasks,
          monitoring_indicators,
          assessment_instruments,
          measurement_frequency,
          scheduled_reassessments,
          observations,
          available_resources,
          support_network,
          status,
          reviewed_at
        ) VALUES (
          @patient_id,
          @therapist_id,
          @approach::therapeutic_approach,
          @approach_other,
          @recommended_frequency,
          @session_duration_minutes,
          @estimated_duration_months,
          @main_techniques,
          @intervention_strategies,
          @resources_to_use,
          @therapeutic_tasks,
          CAST(COALESCE(@monitoring_indicators, '{}') AS JSONB),
          @assessment_instruments,
          @measurement_frequency,
          CAST(COALESCE(@scheduled_reassessments, '[]') AS JSONB),
          @observations,
          @available_resources,
          @support_network,
          @status::therapeutic_plan_status,
          @reviewed_at
        )
        RETURNING id,
                  patient_id,
                  therapist_id,
                  approach::text AS approach,
                  approach_other,
                  recommended_frequency,
                  session_duration_minutes,
                  estimated_duration_months,
                  main_techniques,
                  intervention_strategies,
                  resources_to_use,
                  therapeutic_tasks,
                  monitoring_indicators,
                  assessment_instruments,
                  measurement_frequency,
                  scheduled_reassessments,
                  observations,
                  available_resources,
                  support_network,
                  status::text AS status,
                  reviewed_at,
                  created_at,
                  updated_at
      '''),
        parameters: data,
      );

      if (result.isEmpty) {
        throw Exception('Falha ao criar plano terapêutico');
      }

      return TherapeuticPlan.fromMap(result.first.toColumnMap());
    });
  }

  Future<TherapeuticPlan?> getPlanById({
    required int planId,
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
               approach::text AS approach,
               approach_other,
               recommended_frequency,
               session_duration_minutes,
               estimated_duration_months,
               main_techniques,
               intervention_strategies,
               resources_to_use,
               therapeutic_tasks,
               monitoring_indicators,
               assessment_instruments,
               measurement_frequency,
               scheduled_reassessments,
               observations,
               available_resources,
               support_network,
               status::text AS status,
               reviewed_at,
               created_at,
               updated_at
        FROM therapeutic_plans
        WHERE id = @id
      '''),
        parameters: {'id': planId},
      );

      if (result.isEmpty) {
        return null;
      }

      return TherapeuticPlan.fromMap(result.first.toColumnMap());
    });
  }

  Future<List<TherapeuticPlan>> listPlans({
    int? patientId,
    int? therapistId,
    String? status,
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
             approach::text AS approach,
             approach_other,
             recommended_frequency,
             session_duration_minutes,
             estimated_duration_months,
             main_techniques,
             intervention_strategies,
             resources_to_use,
             therapeutic_tasks,
             monitoring_indicators,
             assessment_instruments,
             measurement_frequency,
             scheduled_reassessments,
             observations,
             available_resources,
             support_network,
             status::text AS status,
             reviewed_at,
             created_at,
             updated_at
      FROM therapeutic_plans
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

      if (status != null) {
        buffer.write(' AND status = @status::therapeutic_plan_status');
        parameters['status'] = status;
      }

      buffer.write(' ORDER BY created_at DESC');

      final result = await conn.execute(Sql.named(buffer.toString()), parameters: parameters);

      return result.map((row) => TherapeuticPlan.fromMap(row.toColumnMap())).toList();
    });
  }

  Future<TherapeuticPlan?> updatePlan({
    required int planId,
    required TherapeuticPlan plan,
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
          accountId: accountId ?? plan.therapistId,
        );
      }

      final data = plan.toDatabaseMap();

      // O toDatabaseMap já faz jsonEncode para campos JSONB

      final result = await conn.execute(
        Sql.named('''
        UPDATE therapeutic_plans
        SET patient_id = @patient_id,
            therapist_id = @therapist_id,
            approach = @approach::therapeutic_approach,
            approach_other = @approach_other,
            recommended_frequency = @recommended_frequency,
            session_duration_minutes = @session_duration_minutes,
            estimated_duration_months = @estimated_duration_months,
            main_techniques = @main_techniques,
            intervention_strategies = @intervention_strategies,
            resources_to_use = @resources_to_use,
            therapeutic_tasks = @therapeutic_tasks,
            monitoring_indicators = CAST(COALESCE(@monitoring_indicators, '{}') AS JSONB),
            assessment_instruments = @assessment_instruments,
            measurement_frequency = @measurement_frequency,
            scheduled_reassessments = CAST(COALESCE(@scheduled_reassessments, '[]') AS JSONB),
            observations = @observations,
            available_resources = @available_resources,
            support_network = @support_network,
            status = @status::therapeutic_plan_status,
            reviewed_at = @reviewed_at,
            updated_at = NOW()
        WHERE id = @id
        RETURNING id,
                  patient_id,
                  therapist_id,
                  approach::text AS approach,
                  approach_other,
                  recommended_frequency,
                  session_duration_minutes,
                  estimated_duration_months,
                  main_techniques,
                  intervention_strategies,
                  resources_to_use,
                  therapeutic_tasks,
                  monitoring_indicators,
                  assessment_instruments,
                  measurement_frequency,
                  scheduled_reassessments,
                  observations,
                  available_resources,
                  support_network,
                  status::text AS status,
                  reviewed_at,
                  created_at,
                  updated_at
      '''),
        parameters: {...data, 'id': planId},
      );

      if (result.isEmpty) {
        return null;
      }

      return TherapeuticPlan.fromMap(result.first.toColumnMap());
    });
  }

  Future<bool> deletePlan({
    required int planId,
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
        Sql.named('DELETE FROM therapeutic_plans WHERE id = @id RETURNING id;'),
        parameters: {'id': planId},
      );

      return result.isNotEmpty;
    });
  }

  // ============ THERAPEUTIC OBJECTIVE METHODS ============

  Future<TherapeuticObjective> createObjective({
    required TherapeuticObjective objective,
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
          accountId: accountId ?? objective.therapistId,
        );
      }

      final data = objective.toDatabaseMap();

      // O toDatabaseMap já faz jsonEncode para campos JSONB

      final result = await conn.execute(
        Sql.named('''
        INSERT INTO therapeutic_objectives (
          therapeutic_plan_id,
          patient_id,
          therapist_id,
          description,
          specific_aspect,
          measurable_criteria,
          achievable_conditions,
          relevant_justification,
          time_bound_deadline,
          deadline_type,
          priority,
          status,
          progress_percentage,
          progress_indicators,
          success_metric,
          measurable_goals,
          related_interventions,
          target_date,
          started_at,
          completed_at,
          abandoned_at,
          abandoned_reason,
          notes,
          display_order
        ) VALUES (
          @therapeutic_plan_id,
          @patient_id,
          @therapist_id,
          @description,
          @specific_aspect,
          @measurable_criteria,
          @achievable_conditions,
          @relevant_justification,
          @time_bound_deadline,
          @deadline_type::objective_deadline_type,
          @priority::objective_priority,
          @status::objective_status,
          @progress_percentage,
          CAST(COALESCE(@progress_indicators, '{}') AS JSONB),
          @success_metric,
          CAST(COALESCE(@measurable_goals, '[]') AS JSONB),
          CAST(COALESCE(@related_interventions, '[]') AS JSONB),
          @target_date,
          @started_at,
          @completed_at,
          @abandoned_at,
          @abandoned_reason,
          @notes,
          @display_order
        )
        RETURNING id,
                  therapeutic_plan_id,
                  patient_id,
                  therapist_id,
                  description,
                  specific_aspect,
                  measurable_criteria,
                  achievable_conditions,
                  relevant_justification,
                  time_bound_deadline,
                  deadline_type::text AS deadline_type,
                  priority::text AS priority,
                  status::text AS status,
                  progress_percentage,
                  progress_indicators,
                  success_metric,
                  measurable_goals,
                  related_interventions,
                  target_date,
                  started_at,
                  completed_at,
                  abandoned_at,
                  abandoned_reason,
                  notes,
                  display_order,
                  created_at,
                  updated_at
      '''),
        parameters: data,
      );

      if (result.isEmpty) {
        throw Exception('Falha ao criar objetivo terapêutico');
      }

      return TherapeuticObjective.fromMap(result.first.toColumnMap());
    });
  }

  Future<TherapeuticObjective?> getObjectiveById({
    required int objectiveId,
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
               therapeutic_plan_id,
               patient_id,
               therapist_id,
               description,
               specific_aspect,
               measurable_criteria,
               achievable_conditions,
               relevant_justification,
               time_bound_deadline,
               deadline_type::text AS deadline_type,
               priority::text AS priority,
               status::text AS status,
               progress_percentage,
               progress_indicators,
               success_metric,
               measurable_goals,
               related_interventions,
               target_date,
               started_at,
               completed_at,
               abandoned_at,
               abandoned_reason,
               notes,
               display_order,
               created_at,
               updated_at
        FROM therapeutic_objectives
        WHERE id = @id
      '''),
        parameters: {'id': objectiveId},
      );

      if (result.isEmpty) {
        return null;
      }

      return TherapeuticObjective.fromMap(result.first.toColumnMap());
    });
  }

  Future<List<TherapeuticObjective>> listObjectives({
    int? planId,
    int? patientId,
    int? therapistId,
    String? status,
    String? priority,
    String? deadlineType,
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
             therapeutic_plan_id,
             patient_id,
             therapist_id,
             description,
             specific_aspect,
             measurable_criteria,
             achievable_conditions,
             relevant_justification,
             time_bound_deadline,
             deadline_type::text AS deadline_type,
             priority::text AS priority,
             status::text AS status,
             progress_percentage,
             progress_indicators,
             success_metric,
             measurable_goals,
             related_interventions,
             target_date,
             started_at,
             completed_at,
             abandoned_at,
             abandoned_reason,
             notes,
             display_order,
             created_at,
             updated_at
      FROM therapeutic_objectives
      WHERE 1=1
    ''');

      final parameters = <String, dynamic>{};

      if (planId != null) {
        buffer.write(' AND therapeutic_plan_id = @plan_id');
        parameters['plan_id'] = planId;
      }

      if (patientId != null) {
        buffer.write(' AND patient_id = @patient_id');
        parameters['patient_id'] = patientId;
      }

      if (therapistId != null) {
        buffer.write(' AND therapist_id = @therapist_id');
        parameters['therapist_id'] = therapistId;
      }

      if (status != null) {
        buffer.write(' AND status = @status::objective_status');
        parameters['status'] = status;
      }

      if (priority != null) {
        buffer.write(' AND priority = @priority::objective_priority');
        parameters['priority'] = priority;
      }

      if (deadlineType != null) {
        buffer.write(' AND deadline_type = @deadline_type::objective_deadline_type');
        parameters['deadline_type'] = deadlineType;
      }

      buffer.write(' ORDER BY display_order ASC, created_at ASC');

      final result = await conn.execute(Sql.named(buffer.toString()), parameters: parameters);

      return result.map((row) => TherapeuticObjective.fromMap(row.toColumnMap())).toList();
    });
  }

  Future<TherapeuticObjective?> updateObjective({
    required int objectiveId,
    required TherapeuticObjective objective,
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
          accountId: accountId ?? objective.therapistId,
        );
      }

      final data = objective.toDatabaseMap();

      // O toDatabaseMap já faz jsonEncode para campos JSONB

      final result = await conn.execute(
        Sql.named('''
        UPDATE therapeutic_objectives
        SET therapeutic_plan_id = @therapeutic_plan_id,
            patient_id = @patient_id,
            therapist_id = @therapist_id,
            description = @description,
            specific_aspect = @specific_aspect,
            measurable_criteria = @measurable_criteria,
            achievable_conditions = @achievable_conditions,
            relevant_justification = @relevant_justification,
            time_bound_deadline = @time_bound_deadline,
            deadline_type = @deadline_type::objective_deadline_type,
            priority = @priority::objective_priority,
            status = @status::objective_status,
            progress_percentage = @progress_percentage,
            progress_indicators = CAST(COALESCE(@progress_indicators, '{}') AS JSONB),
            success_metric = @success_metric,
            measurable_goals = CAST(COALESCE(@measurable_goals, '[]') AS JSONB),
            related_interventions = CAST(COALESCE(@related_interventions, '[]') AS JSONB),
            target_date = @target_date,
            started_at = @started_at,
            completed_at = @completed_at,
            abandoned_at = @abandoned_at,
            abandoned_reason = @abandoned_reason,
            notes = @notes,
            display_order = @display_order,
            updated_at = NOW()
        WHERE id = @id
        RETURNING id,
                  therapeutic_plan_id,
                  patient_id,
                  therapist_id,
                  description,
                  specific_aspect,
                  measurable_criteria,
                  achievable_conditions,
                  relevant_justification,
                  time_bound_deadline,
                  deadline_type::text AS deadline_type,
                  priority::text AS priority,
                  status::text AS status,
                  progress_percentage,
                  progress_indicators,
                  success_metric,
                  measurable_goals,
                  related_interventions,
                  target_date,
                  started_at,
                  completed_at,
                  abandoned_at,
                  abandoned_reason,
                  notes,
                  display_order,
                  created_at,
                  updated_at
      '''),
        parameters: {...data, 'id': objectiveId},
      );

      if (result.isEmpty) {
        return null;
      }

      return TherapeuticObjective.fromMap(result.first.toColumnMap());
    });
  }

  Future<bool> deleteObjective({
    required int objectiveId,
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
        Sql.named('DELETE FROM therapeutic_objectives WHERE id = @id RETURNING id;'),
        parameters: {'id': objectiveId},
      );

      return result.isNotEmpty;
    });
  }
}
