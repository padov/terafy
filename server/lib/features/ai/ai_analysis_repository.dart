import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';
import 'models/ai_analysis.dart';
import 'dart:convert';

class AIAnalysisRepository {
  final DBConnection _dbConnection;

  AIAnalysisRepository(this._dbConnection);

  /// Helper to safely decode database values (handles UndecodedBytes)
  String _decodeValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is UndecodedBytes) {
      return utf8.decode(value.bytes);
    }
    return value.toString();
  }

  /// Helper to safely convert cost from database (handles String and num)
  double _parseCost(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Creates a new AI analysis record with pending status
  Future<AIAnalysis> create({
    required int therapistId,
    required int patientId,
    required AIAnalysisType type,
    required String prompt,
    List<int> sessionIds = const [],
  }) async {
    return await _dbConnection.withConnection((conn) async {
      // Insert analysis
      final result = await conn.execute(
        Sql.named('''
          INSERT INTO ai_analyses (therapist_id, patient_id, type, prompt, status)
          VALUES (@therapist_id, @patient_id, @type, @prompt, 'pending')
          RETURNING id, therapist_id, patient_id, type, status, prompt, result, cost, error_message, created_at, updated_at
        '''),
        parameters: {'therapist_id': therapistId, 'patient_id': patientId, 'type': type.value, 'prompt': prompt},
      );

      if (result.isEmpty) {
        throw Exception('Failed to create AI analysis');
      }

      final row = result.first;
      final analysisId = row[0] as int;

      // Link sessions if provided
      if (sessionIds.isNotEmpty) {
        await _linkSessions(conn, analysisId, sessionIds);
      }

      return AIAnalysis(
        id: analysisId,
        therapistId: row[1] as int,
        patientId: row[2] as int,
        type: AIAnalysisType.fromString(_decodeValue(row[3])),
        status: AIAnalysisStatus.fromString(_decodeValue(row[4])),
        prompt: row[5] as String,
        result: row[6] as String?,
        cost: _parseCost(row[7]),
        errorMessage: row[8] as String?,
        sessionIds: sessionIds,
        createdAt: row[9] as DateTime?,
        updatedAt: row[10] as DateTime?,
      );
    });
  }

  /// Updates an analysis with the result and marks it as completed
  Future<void> updateWithResult({required int id, required String result, required double cost}) async {
    await _dbConnection.withConnection((conn) async {
      await conn.execute(
        Sql.named('''
          UPDATE ai_analyses
          SET result = @result,
              cost = @cost,
              status = 'completed',
              updated_at = NOW()
          WHERE id = @id
        '''),
        parameters: {'id': id, 'result': result, 'cost': cost},
      );
    });
  }

  /// Updates an analysis with an error and marks it as failed
  Future<void> updateWithError({required int id, required String errorMessage}) async {
    await _dbConnection.withConnection((conn) async {
      await conn.execute(
        Sql.named('''
          UPDATE ai_analyses
          SET error_message = @error_message,
              status = 'failed',
              updated_at = NOW()
          WHERE id = @id
        '''),
        parameters: {'id': id, 'error_message': errorMessage},
      );
    });
  }

  /// Archives an analysis
  Future<void> archive({required int id}) async {
    await _dbConnection.withConnection((conn) async {
      await conn.execute(
        Sql.named('''
          UPDATE ai_analyses
          SET archived = TRUE,
              updated_at = NOW()
          WHERE id = @id
        '''),
        parameters: {'id': id},
      );
    });
  }

  /// Unarchives an analysis
  Future<void> unarchive({required int id}) async {
    await _dbConnection.withConnection((conn) async {
      await conn.execute(
        Sql.named('''
          UPDATE ai_analyses
          SET archived = FALSE,
              updated_at = NOW()
          WHERE id = @id
        '''),
        parameters: {'id': id},
      );
    });
  }

  /// Gets an analysis by ID
  Future<AIAnalysis?> getById(int id) async {
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          SELECT a.id, a.therapist_id, a.patient_id, a.type, a.status, a.prompt, 
                 a.result, a.cost, a.error_message, a.created_at, a.updated_at, a.archived,
                 COALESCE(array_agg(s.session_id) FILTER (WHERE s.session_id IS NOT NULL), ARRAY[]::integer[]) as session_ids
          FROM ai_analyses a
          LEFT JOIN ai_analysis_sessions s ON a.id = s.analysis_id
          WHERE a.id = @id
          GROUP BY a.id
        '''),
        parameters: {'id': id},
      );

      if (result.isEmpty) {
        return null;
      }

      final row = result.first;
      return AIAnalysis(
        id: row[0] as int,
        therapistId: row[1] as int,
        patientId: row[2] as int,
        type: AIAnalysisType.fromString(_decodeValue(row[3])),
        status: AIAnalysisStatus.fromString(_decodeValue(row[4])),
        prompt: row[5] as String,
        result: row[6] as String?,
        cost: _parseCost(row[7]),
        errorMessage: row[8] as String?,
        createdAt: row[9] as DateTime?,
        updatedAt: row[10] as DateTime?,
        archived: row[11] as bool? ?? false,
        sessionIds: List<int>.from(row[12] as List),
      );
    });
  }

  /// Gets all analyses for a patient
  Future<List<AIAnalysis>> getByPatientId(int patientId) async {
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
          SELECT a.id, a.therapist_id, a.patient_id, a.type, a.status, a.prompt, 
                 a.result, a.cost, a.error_message, a.created_at, a.updated_at, a.archived,
                 COALESCE(array_agg(s.session_id) FILTER (WHERE s.session_id IS NOT NULL), ARRAY[]::integer[]) as session_ids
          FROM ai_analyses a
          LEFT JOIN ai_analysis_sessions s ON a.id = s.analysis_id
          WHERE a.patient_id = @patient_id
          GROUP BY a.id
          ORDER BY a.created_at DESC
        '''),
        parameters: {'patient_id': patientId},
      );

      return result.map((row) {
        return AIAnalysis(
          id: row[0] as int,
          therapistId: row[1] as int,
          patientId: row[2] as int,
          type: AIAnalysisType.fromString(_decodeValue(row[3])),
          status: AIAnalysisStatus.fromString(_decodeValue(row[4])),
          prompt: row[5] as String,
          result: row[6] as String?,
          cost: _parseCost(row[7]),
          errorMessage: row[8] as String?,
          createdAt: row[9] as DateTime?,
          updatedAt: row[10] as DateTime?,
          archived: row[11] as bool? ?? false,
          sessionIds: List<int>.from(row[12] as List),
        );
      }).toList();
    });
  }

  /// Links sessions to an analysis
  Future<void> _linkSessions(Connection conn, int analysisId, List<int> sessionIds) async {
    if (sessionIds.isEmpty) return;

    final values = sessionIds.map((sessionId) => '($analysisId, $sessionId)').join(', ');

    await conn.execute('''
      INSERT INTO ai_analysis_sessions (analysis_id, session_id)
      VALUES $values
      ON CONFLICT DO NOTHING
    ''');
  }
}
