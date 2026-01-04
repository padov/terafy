import 'package:common/common.dart';
import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';
import 'dart:convert';
import 'dart:math';
import 'package:server/core/database/rls_context.dart';

class AnamnesisRepository {
  final DBConnection _dbConnection;

  AnamnesisRepository(this._dbConnection);

  // ========== ANAMNESIS CRUD ==========

  Future<Anamnesis?> getAnamnesisByPatientId(
    int patientId, {
    required int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else if (userId != null) {
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: accountId);
      }

      final results = await conn.execute(
        Sql.named('''
          SELECT 
            id,
            patient_id,
            therapist_id,
            template_id,
            data,
            completed_at,
            created_at,
            updated_at
          FROM anamnesis
          WHERE patient_id = @patient_id;
        '''),
        parameters: {'patient_id': patientId},
      );

      if (results.isEmpty) {
        return null;
      }

      return Anamnesis.fromMap(results.first.toColumnMap());
    });
  }

  Future<Anamnesis?> getAnamnesisById(
    int id, {
    required int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else if (userId != null) {
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: accountId);
      }

      final results = await conn.execute(
        Sql.named('''
          SELECT 
            id,
            patient_id,
            therapist_id,
            template_id,
            data,
            completed_at,
            created_at,
            updated_at
          FROM anamnesis
          WHERE id = @id;
        '''),
        parameters: {'id': id},
      );

      if (results.isEmpty) {
        return null;
      }

      return Anamnesis.fromMap(results.first.toColumnMap());
    });
  }

  Future<Anamnesis> createAnamnesis(
    Anamnesis anamnesis, {
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
          accountId: accountId ?? anamnesis.therapistId,
        );
      }

      final data = anamnesis.toDatabaseMap();

      final result = await conn.execute(
        Sql.named('''
          INSERT INTO anamnesis (
            patient_id,
            therapist_id,
            template_id,
            data,
            completed_at
          )
          VALUES (
            @patient_id,
            @therapist_id,
            @template_id,
            CAST(@data AS JSONB),
            @completed_at
          )
          RETURNING 
            id,
            patient_id,
            therapist_id,
            template_id,
            data,
            completed_at,
            created_at,
            updated_at;
        '''),
        parameters: {...data, 'data': data['data']},
      );

      return Anamnesis.fromMap(result.first.toColumnMap());
    });
  }

  Future<Anamnesis?> updateAnamnesis(
    int id,
    Anamnesis anamnesis, {
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
          accountId: accountId ?? anamnesis.therapistId,
        );
      }

      final data = anamnesis.toDatabaseMap();

      final result = await conn.execute(
        Sql.named('''
          UPDATE anamnesis
          SET
            template_id = @template_id,
            data = CAST(@data AS JSONB),
            completed_at = @completed_at,
            updated_at = NOW()
          WHERE id = @id
          RETURNING 
            id,
            patient_id,
            therapist_id,
            template_id,
            data,
            completed_at,
            created_at,
            updated_at;
        '''),
        parameters: {
          'id': id,
          'template_id': data['template_id'],
          'data': data['data'],
          'completed_at': data['completed_at'],
        },
      );

      if (result.isEmpty) {
        return null;
      }

      return Anamnesis.fromMap(result.first.toColumnMap());
    });
  }

  Future<bool> deleteAnamnesis(
    int id, {
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
        Sql.named('DELETE FROM anamnesis WHERE id = @id RETURNING id;'),
        parameters: {'id': id},
      );

      return result.isNotEmpty;
    });
  }

  // ========== TEMPLATES CRUD ==========

  Future<List<AnamnesisTemplate>> getTemplates({
    int? therapistId,
    String? category,
    required int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else if (userId != null) {
        await RLSContext.setContext(
          conn: conn,
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? therapistId,
        );
      }

      final buffer = StringBuffer('''
        SELECT 
          id,
          therapist_id,
          name,
          description,
          category,
          is_default,
          is_system,
          structure,
          created_at,
          updated_at
        FROM anamnesis_templates
        WHERE 1=1
      ''');

      final parameters = <String, dynamic>{};

      if (therapistId != null) {
        buffer.write(' AND (therapist_id = @therapist_id OR therapist_id IS NULL)');
        parameters['therapist_id'] = therapistId;
      } else {
        buffer.write(' AND therapist_id IS NULL');
      }

      if (category != null) {
        buffer.write(' AND category = @category');
        parameters['category'] = category;
      }

      buffer.write(' ORDER BY is_system DESC, is_default DESC, name ASC;');

      final results = await conn.execute(
        parameters.isEmpty ? buffer.toString() : Sql.named(buffer.toString()),
        parameters: parameters.isEmpty ? null : parameters,
      );

      return results.map((row) {
        return AnamnesisTemplate.fromMap(row.toColumnMap());
      }).toList();
    });
  }

  Future<AnamnesisTemplate?> getTemplateById(
    int id, {
    required int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else if (userId != null) {
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: accountId);
      }

      final results = await conn.execute(
        Sql.named('''
          SELECT 
            id,
            therapist_id,
            name,
            description,
            category,
            is_default,
            is_system,
            structure,
            created_at,
            updated_at
          FROM anamnesis_templates
          WHERE id = @id;
        '''),
        parameters: {'id': id},
      );

      if (results.isEmpty) {
        return null;
      }

      return AnamnesisTemplate.fromMap(results.first.toColumnMap());
    });
  }

  Future<AnamnesisTemplate> createTemplate(
    AnamnesisTemplate template, {
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
          accountId: accountId ?? template.therapistId,
        );
      }

      // Se está marcando como padrão, remove o padrão anterior
      if (template.isDefault && template.therapistId != null) {
        await conn.execute(
          Sql.named('''
            UPDATE anamnesis_templates
            SET is_default = FALSE
            WHERE therapist_id = @therapist_id AND is_default = TRUE;
          '''),
          parameters: {'therapist_id': template.therapistId},
        );
      }

      final data = template.toDatabaseMap();

      final result = await conn.execute(
        Sql.named('''
          INSERT INTO anamnesis_templates (
            therapist_id,
            name,
            description,
            category,
            is_default,
            is_system,
            structure
          )
          VALUES (
            @therapist_id,
            @name,
            @description,
            @category,
            @is_default,
            @is_system,
            CAST(@structure AS JSONB)
          )
          RETURNING 
            id,
            therapist_id,
            name,
            description,
            category,
            is_default,
            is_system,
            structure,
            created_at,
            updated_at;
        '''),
        parameters: {...data, 'structure': data['structure']},
      );

      return AnamnesisTemplate.fromMap(result.first.toColumnMap());
    });
  }

  Future<AnamnesisTemplate?> updateTemplate(
    int id,
    AnamnesisTemplate template, {
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
          accountId: accountId ?? template.therapistId,
        );
      }

      // Não permite editar templates do sistema
      final existing = await getTemplateById(id, userId: userId, userRole: userRole, accountId: accountId);
      if (existing?.isSystem == true) {
        throw Exception('Não é possível editar templates do sistema');
      }

      // Se está marcando como padrão, remove o padrão anterior
      if (template.isDefault && template.therapistId != null) {
        await conn.execute(
          Sql.named('''
            UPDATE anamnesis_templates
            SET is_default = FALSE
            WHERE therapist_id = @therapist_id 
              AND is_default = TRUE 
              AND id != @current_id;
          '''),
          parameters: {'therapist_id': template.therapistId, 'current_id': id},
        );
      }

      final data = template.toDatabaseMap();

      final result = await conn.execute(
        Sql.named('''
          UPDATE anamnesis_templates
          SET
            name = @name,
            description = @description,
            category = @category,
            is_default = @is_default,
            structure = CAST(@structure AS JSONB),
            updated_at = NOW()
          WHERE id = @id
          RETURNING 
            id,
            therapist_id,
            name,
            description,
            category,
            is_default,
            is_system,
            structure,
            created_at,
            updated_at;
        '''),
        parameters: {
          'id': id,
          'name': data['name'],
          'description': data['description'],
          'category': data['category'],
          'is_default': data['is_default'],
          'structure': data['structure'],
        },
      );

      if (result.isEmpty) {
        return null;
      }

      return AnamnesisTemplate.fromMap(result.first.toColumnMap());
    });
  }

  Future<bool> deleteTemplate(
    int id, {
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

      // Não permite deletar templates do sistema
      final existing = await getTemplateById(id, userId: userId, userRole: userRole, accountId: accountId);
      if (existing?.isSystem == true) {
        throw Exception('Não é possível deletar templates do sistema');
      }

      final result = await conn.execute(
        Sql.named('DELETE FROM anamnesis_templates WHERE id = @id RETURNING id;'),
        parameters: {'id': id},
      );

      return result.isNotEmpty;
    });
  }

  // ========== INVITES ==========

  String _generateToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  Future<String> createInvite({
    required int therapistId,
    required int patientId,
    required int templateId,
    required DateTime expiresAt,
  }) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      // Bypass RLS for invite creation as it's a system action triggered by therapist
      await RLSContext.clearContext(conn);

      final token = _generateToken();

      await conn.execute(
        Sql.named('''
          INSERT INTO anamnesis_invites (
              token, therapist_id, patient_id, template_id, expires_at
          ) VALUES (
              @token, @therapist_id, @patient_id, @template_id, @expires_at
          );
        '''),
        parameters: {
          'token': token,
          'therapist_id': therapistId,
          'patient_id': patientId,
          'template_id': templateId,
          'expires_at': expiresAt,
        },
      );
      return token;
    });
  }

  Future<Map<String, dynamic>?> getInviteByToken(String token) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      await RLSContext.clearContext(conn); // Public access

      final results = await conn.execute(
        Sql.named('''
          SELECT 
            i.id,
            i.token,
            i.status,
            i.expires_at,
            i.patient_id,
            i.template_id,
            i.therapist_id,
            p.full_name as patient_name,
            t.name as therapist_name,
            temp.name as template_name,
            temp.description as template_description,
            temp.structure as template_structure
          FROM anamnesis_invites i
          JOIN patients p ON i.patient_id = p.id
          JOIN therapists t ON i.therapist_id = t.id
          JOIN anamnesis_templates temp ON i.template_id = temp.id
          WHERE i.token = @token;
        '''),
        parameters: {'token': token},
      );

      if (results.isEmpty) return null;

      final row = results.first.toColumnMap();

      // Check validation
      final status = row['status'];
      final expiresAt = row['expires_at'] as DateTime;

      if (status != 'pending') return null; // Already used or expired
      if (DateTime.now().isAfter(expiresAt)) {
        // Optionally update status to expired?
        return null;
      }

      return row;
    });
  }

  Future<void> consumeInvite(int inviteId) async {
    return await _dbConnection.withConnection((conn) async {
      await RLSContext.clearContext(conn);

      await conn.execute(
        Sql.named('''
          UPDATE anamnesis_invites 
          SET status = 'used', used_at = NOW() 
          WHERE id = @id;
        '''),
        parameters: {'id': inviteId},
      );
    });
  }
}
