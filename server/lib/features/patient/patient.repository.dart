import 'package:common/common.dart';
import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/core/database/rls_context.dart';

class PatientRepository {
  final DBConnection _dbConnection;

  PatientRepository(this._dbConnection);

  Future<List<Patient>> getPatients({
    int? therapistId,
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
          user_id,
          full_name,
          birth_date,
          age,
          cpf,
          rg,
          gender,
          marital_status,
          address,
          email,
          phones,
          profession,
          education,
          emergency_contact,
          legal_guardian,
          health_insurance,
          health_insurance_card,
          preferred_payment_method,
          session_price,
          consent_signed_at,
          lgpd_consent_at,
          status::text AS status,
          inactivation_reason,
          treatment_start_date,
          last_session_date,
          total_sessions,
          tags,
          notes,
          photo_url,
          color,
          created_at,
          updated_at
        FROM patients
        ''');

      final parameters = <String, dynamic>{};
      if (therapistId != null) {
        buffer.write(' WHERE therapist_id = @therapist_id');
        parameters['therapist_id'] = therapistId;
      }

      buffer.write(' ORDER BY created_at DESC;');

      final results = await conn.execute(
        parameters.isEmpty ? buffer.toString() : Sql.named(buffer.toString()),
        parameters: parameters.isEmpty ? null : parameters,
      );

      var patients = results.map((row) {
        final map = row.toColumnMap();
        return Patient.fromMap(map);
      }).toList();

      // Verificação adicional de segurança: therapist só vê seus próprios pacientes
      // (camada adicional caso o RLS não bloqueie corretamente)
      if (!bypassRLS && userRole == 'therapist' && accountId != null) {
        patients = patients.where((p) => p.therapistId == accountId).toList();
      }

      return patients;
    });
  }

  Future<Patient?> getPatientById(
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
            user_id,
            full_name,
            birth_date,
            age,
            cpf,
            rg,
            gender,
            marital_status,
            address,
            email,
            phones,
            profession,
            education,
            emergency_contact,
            legal_guardian,
            health_insurance,
            health_insurance_card,
            preferred_payment_method,
            session_price,
            consent_signed_at,
            lgpd_consent_at,
            status::text AS status,
            inactivation_reason,
            treatment_start_date,
            last_session_date,
            total_sessions,
            tags,
            notes,
            photo_url,
            color,
            created_at,
            updated_at
          FROM patients
          WHERE id = @id;
          '''),
        parameters: {'id': id},
      );

      if (results.isEmpty) {
        return null;
      }

      final patient = Patient.fromMap(results.first.toColumnMap());

      // Verificação adicional de segurança: therapist só acessa seus próprios pacientes
      // (camada adicional caso o RLS não bloqueie corretamente)
      if (!bypassRLS && userRole == 'therapist' && accountId != null && patient.therapistId != accountId) {
        return null;
      }

      return patient;
    });
  }

  Future<Patient> createPatient(
    Patient patient, {
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
          accountId: accountId ?? patient.therapistId,
        );
      }

      final data = patient.toDatabaseMap();

      final result = await conn.execute(
        Sql.named('''
        INSERT INTO patients (
          therapist_id,
          user_id,
          full_name,
          birth_date,
          age,
          cpf,
          rg,
          gender,
          marital_status,
          address,
          email,
          phones,
          profession,
          education,
          emergency_contact,
          legal_guardian,
          health_insurance,
          health_insurance_card,
          preferred_payment_method,
          session_price,
          consent_signed_at,
          lgpd_consent_at,
          status,
          inactivation_reason,
          treatment_start_date,
          last_session_date,
          tags,
          notes,
          photo_url,
          color
        )
        VALUES (
          @therapist_id,
          @user_id,
          @full_name,
          @birth_date,
          @age,
          @cpf,
          @rg,
          @gender,
          @marital_status,
          @address,
          @email,
          @phones,
          @profession,
          @education,
          CAST(@emergency_contact AS JSONB),
          CAST(@legal_guardian AS JSONB),
          @health_insurance,
          @health_insurance_card,
          @preferred_payment_method,
          @session_price,
          @consent_signed_at,
          @lgpd_consent_at,
          @status::patient_status,
          @inactivation_reason,
          @treatment_start_date,
          @last_session_date,
          @tags,
          @notes,
          @photo_url,
          @color
        )
        RETURNING 
          id,
          therapist_id,
          user_id,
          full_name,
          birth_date,
          age,
          cpf,
          rg,
          gender,
          marital_status,
          address,
          email,
          phones,
          profession,
          education,
          emergency_contact,
          legal_guardian,
          health_insurance,
          health_insurance_card,
          preferred_payment_method,
          session_price,
          consent_signed_at,
          lgpd_consent_at,
          status::text AS status,
          inactivation_reason,
          treatment_start_date,
          last_session_date,
          tags,
          notes,
          photo_url,
          color,
          created_at,
          updated_at;
        '''),
        parameters: {...data, 'emergency_contact': data['emergency_contact'], 'legal_guardian': data['legal_guardian']},
      );

      final map = result.first.toColumnMap();
      return Patient.fromMap(map);
    });
  }

  Future<Patient?> updatePatient(
    int id,
    Patient patient, {
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
          accountId: accountId ?? patient.therapistId,
        );
      }

      // Verificação adicional de segurança: therapist só atualiza seus próprios pacientes
      // (camada adicional caso o RLS não bloqueie corretamente)
      if (!bypassRLS && userRole == 'therapist' && accountId != null) {
        // Busca o paciente atual para verificar se pertence ao therapist
        final currentPatient = await getPatientById(
          id,
          userId: userId,
          userRole: userRole,
          accountId: accountId,
          bypassRLS: false,
        );
        if (currentPatient == null || currentPatient.therapistId != accountId) {
          return null;
        }
      }

      final data = patient.toDatabaseMap();

      final result = await conn.execute(
        Sql.named('''
        UPDATE patients
        SET
          therapist_id = @therapist_id,
          user_id = @user_id,
          full_name = @full_name,
          birth_date = @birth_date,
          age = @age,
          cpf = @cpf,
          rg = @rg,
          gender = @gender,
          marital_status = @marital_status,
          address = @address,
          email = @email,
          phones = @phones,
          profession = @profession,
          education = @education,
          emergency_contact = CAST(@emergency_contact AS JSONB),
          legal_guardian = CAST(@legal_guardian AS JSONB),
          health_insurance = @health_insurance,
          health_insurance_card = @health_insurance_card,
          preferred_payment_method = @preferred_payment_method,
          session_price = @session_price,
          consent_signed_at = @consent_signed_at,
          lgpd_consent_at = @lgpd_consent_at,
          status = @status::patient_status,
          inactivation_reason = @inactivation_reason,
          treatment_start_date = @treatment_start_date,
          last_session_date = @last_session_date,
          tags = @tags,
          notes = @notes,
          photo_url = @photo_url,
          color = @color,
          updated_at = NOW()
        WHERE id = @id
        RETURNING 
          id,
          therapist_id,
          user_id,
          full_name,
          birth_date,
          age,
          cpf,
          rg,
          gender,
          marital_status,
          address,
          email,
          phones,
          profession,
          education,
          emergency_contact,
          legal_guardian,
          health_insurance,
          health_insurance_card,
          preferred_payment_method,
          session_price,
          consent_signed_at,
          lgpd_consent_at,
          status::text AS status,
          inactivation_reason,
          treatment_start_date,
          last_session_date,
          tags,
          notes,
          photo_url,
          color,
          created_at,
          updated_at;
        '''),
        parameters: {
          ...data,
          'id': id,
          'emergency_contact': data['emergency_contact'],
          'legal_guardian': data['legal_guardian'],
        },
      );

      if (result.isEmpty) {
        return null;
      }

      return Patient.fromMap(result.first.toColumnMap());
    });
  }

  Future<bool> deletePatient(
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

      // Verificação adicional de segurança: therapist só remove seus próprios pacientes
      // (camada adicional caso o RLS não bloqueie corretamente)
      if (!bypassRLS && userRole == 'therapist' && accountId != null) {
        // Busca o paciente atual para verificar se pertence ao therapist
        final currentPatient = await getPatientById(
          id,
          userId: userId,
          userRole: userRole,
          accountId: accountId,
          bypassRLS: false,
        );
        if (currentPatient == null || currentPatient.therapistId != accountId) {
          return false;
        }
      }

      final result = await conn.execute(
        Sql.named('DELETE FROM patients WHERE id = @id RETURNING id;'),
        parameters: {'id': id},
      );

      return result.isNotEmpty;
    });
  }
}
