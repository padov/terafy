import 'dart:convert';

import 'package:common/common.dart';
import '../../../core/database/db_connection.dart';
import '../../../core/database/rls_context.dart';
import 'package:postgres/postgres.dart';

class TherapistRepository {
  final DBConnection _dbConnection;

  TherapistRepository(this._dbConnection);

  /// Lista todos os terapeutas
  ///
  /// [userId] - ID do usuário para contexto RLS (opcional)
  /// [userRole] - Role do usuário para contexto RLS (opcional)
  /// [bypassRLS] - Se true, limpa contexto RLS (para admin ver todos)
  Future<List<Therapist>> getAllTherapists({int? userId, String? userRole, bool bypassRLS = false}) async {
    return await _dbConnection.withConnection((conn) async {
      // Configura contexto RLS
      if (bypassRLS) {
        // Admin: limpa contexto para ver todos
        await RLSContext.clearContext(conn);
      } else if (userId != null) {
        // Usuário normal: define contexto RLS
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole);
      }

      // Query normal - RLS filtra automaticamente
      final results = await conn.execute('''
        SELECT 
          id, name, nickname, document, email, phone, birth_date, profile_picture_url,
          professional_registry_type, professional_registry_number,
          specialties, education, professional_presentation, office_address,
          calendar_settings, notification_preferences, bank_details,
          status::text as status,
          created_at, updated_at
        FROM therapists 
        ORDER BY created_at DESC;
      ''');

      final therapists = results.map((row) {
        final map = row.toColumnMap();
        return Therapist.fromMap(map);
      }).toList();

      return therapists;
    });
  }

  /// Busca um terapeuta por ID
  ///
  /// [id] - ID do terapeuta
  /// [userId] - ID do usuário para contexto RLS (opcional)
  /// [userRole] - Role do usuário para contexto RLS (opcional)
  /// [accountId] - ID da conta vinculada para contexto RLS (opcional)
  /// [bypassRLS] - Se true, limpa contexto RLS (para admin)
  Future<Therapist?> getTherapistById(
    int id, {
    int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      // Configura contexto RLS
      if (bypassRLS) {
        // Admin: limpa contexto para ver qualquer um
        await RLSContext.clearContext(conn);
      } else if (userId != null) {
        // Usuário normal: define contexto RLS
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: accountId);
      }

      // Query normal - RLS filtra automaticamente
      final results = await conn.execute(
        Sql.named('''
        SELECT 
          id, name, nickname, document, email, phone, birth_date, profile_picture_url,
          professional_registry_type, professional_registry_number,
          specialties, education, professional_presentation, office_address,
          calendar_settings, notification_preferences, bank_details,
          status::text as status,
          created_at, updated_at
        FROM therapists 
        WHERE id = @id;
      '''),
        parameters: {'id': id},
      );

      // Se não encontrou, pode ser porque RLS bloqueou ou não existe
      if (results.isEmpty) {
        return null;
      }

      final map = results.first.toColumnMap();
      return Therapist.fromMap(map);
    });
  }

  /// Cria um novo terapeuta
  ///
  /// [therapist] - Dados do terapeuta
  /// [userId] - ID do usuário para contexto RLS (opcional, para policy de criação)
  /// [userRole] - Role do usuário para contexto RLS (opcional)
  Future<Therapist> createTherapist(Therapist therapist, {int? userId, String? userRole}) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      // Define contexto RLS se fornecido (para policy de criação)
      if (userId != null) {
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole);
      }

      final result = await conn.execute(
        Sql.named('''
        INSERT INTO therapists (
          name, nickname, document, email, phone, birth_date, profile_picture_url,
          professional_registry_type, professional_registry_number,
          specialties, education, professional_presentation, office_address,
          calendar_settings, notification_preferences, bank_details, status
        ) VALUES (
          @name, @nickname, @document, @email, @phone, @birth_date, @profile_picture_url,
          @professional_registry_type, @professional_registry_number,
          @specialties, @education, @professional_presentation, @office_address,
          @calendar_settings, @notification_preferences, @bank_details, @status
        ) RETURNING 
          id, name, nickname, document, email, phone, birth_date, profile_picture_url,
          professional_registry_type, professional_registry_number,
          specialties, education, professional_presentation, office_address,
          calendar_settings, notification_preferences, bank_details,
          status::text as status,
          created_at, updated_at;
      '''),
        parameters: {
          'name': therapist.name,
          'nickname': therapist.nickname,
          'document': therapist.document,
          'email': therapist.email,
          'phone': therapist.phone,
          'birth_date': therapist.birthDate,
          'profile_picture_url': therapist.profilePictureUrl,
          'professional_registry_type': therapist.professionalRegistryType,
          'professional_registry_number': therapist.professionalRegistryNumber,
          'specialties': therapist.specialties,
          'education': therapist.education,
          'professional_presentation': therapist.professionalPresentation,
          'office_address': therapist.officeAddress,
          'calendar_settings': therapist.calendarSettings != null ? jsonEncode(therapist.calendarSettings) : null,
          'notification_preferences': therapist.notificationPreferences != null
              ? jsonEncode(therapist.notificationPreferences)
              : null,
          'bank_details': therapist.bankDetails != null ? jsonEncode(therapist.bankDetails) : null,
          'status': therapist.status,
        },
      );

      if (result.isEmpty) {
        throw Exception('Erro ao criar terapeuta, nenhum dado retornado.');
      }

      final map = result.first.toColumnMap();
      return Therapist.fromMap(map);
    });
  }

  /// Atualiza um terapeuta
  ///
  /// [id] - ID do terapeuta
  /// [therapist] - Dados atualizados
  /// [userId] - ID do usuário para contexto RLS (obrigatório para RLS funcionar)
  /// [userRole] - Role do usuário para contexto RLS (opcional)
  /// [accountId] - ID da conta vinculada para contexto RLS (opcional)
  /// [bypassRLS] - Se true, limpa contexto RLS (para admin)
  Future<Therapist?> updateTherapist(
    int id,
    Therapist therapist, {
    int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      // Configura contexto RLS
      if (bypassRLS) {
        // Admin: limpa contexto para atualizar qualquer um
        await RLSContext.clearContext(conn);
      } else if (userId != null) {
        // Usuário normal: define contexto RLS
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: accountId);
      }

      final result = await conn.execute(
        Sql.named('''
        UPDATE therapists SET
          name = @name,
          nickname = @nickname,
          document = @document,
          email = @email,
          phone = @phone,
          birth_date = @birth_date,
          profile_picture_url = @profile_picture_url,
          professional_registry_type = @professional_registry_type,
          professional_registry_number = @professional_registry_number,
          specialties = @specialties,
          education = @education,
          professional_presentation = @professional_presentation,
          office_address = @office_address,
          calendar_settings = @calendar_settings,
          notification_preferences = @notification_preferences,
          bank_details = @bank_details,
          status = @status,
          updated_at = NOW()
        WHERE id = @id
        RETURNING 
          id, name, nickname, document, email, phone, birth_date, profile_picture_url,
          professional_registry_type, professional_registry_number,
          specialties, education, professional_presentation, office_address,
          calendar_settings, notification_preferences, bank_details,
          status::text as status,
          created_at, updated_at;
      '''),
        parameters: {
          'id': id,
          'name': therapist.name,
          'nickname': therapist.nickname,
          'document': therapist.document,
          'email': therapist.email,
          'phone': therapist.phone,
          'birth_date': therapist.birthDate,
          'profile_picture_url': therapist.profilePictureUrl,
          'professional_registry_type': therapist.professionalRegistryType,
          'professional_registry_number': therapist.professionalRegistryNumber,
          'specialties': therapist.specialties,
          'education': therapist.education,
          'professional_presentation': therapist.professionalPresentation,
          'office_address': therapist.officeAddress,
          'calendar_settings': therapist.calendarSettings != null ? jsonEncode(therapist.calendarSettings) : null,
          'notification_preferences': therapist.notificationPreferences != null
              ? jsonEncode(therapist.notificationPreferences)
              : null,
          'bank_details': therapist.bankDetails != null ? jsonEncode(therapist.bankDetails) : null,
          'status': therapist.status,
        },
      );

      if (result.isEmpty) {
        return null;
      }

      final map = result.first.toColumnMap();
      return Therapist.fromMap(map);
    });
  }

  /// Deleta um terapeuta
  ///
  /// [id] - ID do terapeuta
  /// [userId] - ID do usuário para contexto RLS (obrigatório para RLS funcionar)
  /// [userRole] - Role do usuário para contexto RLS (opcional)
  /// [accountId] - ID da conta vinculada para contexto RLS (opcional)
  /// [bypassRLS] - Se true, limpa contexto RLS (para admin)
  Future<bool> deleteTherapist(int id, {int? userId, String? userRole, int? accountId, bool bypassRLS = false}) async {
    return await _dbConnection.withConnection((conn) async {
      // Configura contexto RLS
      if (bypassRLS) {
        // Admin: limpa contexto para deletar qualquer um
        await RLSContext.clearContext(conn);
      } else if (userId != null) {
        // Usuário normal: define contexto RLS
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: accountId);
      }

      final result = await conn.execute(Sql.named('DELETE FROM therapists WHERE id = @id;'), parameters: {'id': id});

      return result.affectedRows > 0;
    });
  }

  Future<Therapist> updateTherapistUserId(int therapistId, int userId) async {
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
        UPDATE therapists 
        SET user_id = @user_id, updated_at = NOW()
        WHERE id = @id
        RETURNING 
          id, name, nickname, document, email, phone, birth_date, profile_picture_url,
          professional_registry_type, professional_registry_number,
          specialties, education, professional_presentation, office_address,
          calendar_settings, notification_preferences, bank_details,
          status::text as status,
          created_at, updated_at;
      '''),
        parameters: {'id': therapistId, 'user_id': userId},
      );

      if (result.isEmpty) {
        throw Exception('Erro ao atualizar user_id do terapeuta, nenhum dado retornado.');
      }

      final map = result.first.toColumnMap();
      return Therapist.fromMap(map);
    });
  }

  // Retorna o terapeuta pelo user_id com informações do plano ativo
  Future<Map<String, dynamic>?> getTherapistByUserIdWithPlan(int userId) async {
    return await _dbConnection.withConnection((conn) async {
      final results = await conn.execute(
        Sql.named('''
        SELECT 
          t.id, t.name, t.nickname, t.document, t.email, t.phone, t.birth_date, t.profile_picture_url,
          t.professional_registry_type, t.professional_registry_number,
          t.specialties, t.education, t.professional_presentation, t.office_address,
          t.calendar_settings, t.notification_preferences, t.bank_details,
          t.status::text as status,
          t.created_at, t.updated_at,
          ps.plan_id,
          p.name as plan_name,
          p.price as plan_price,
          p.patient_limit as plan_patient_limit
        FROM therapists t
        LEFT JOIN plan_subscriptions ps ON t.id = ps.therapist_id AND ps.is_active = true
        LEFT JOIN plans p ON ps.plan_id = p.id
        WHERE t.user_id = @user_id
        ORDER BY ps.created_at DESC
        LIMIT 1;
      '''),
        parameters: {'user_id': userId},
      );

      if (results.isEmpty) {
        return null;
      }

      final map = results.first.toColumnMap();
      final therapist = Therapist.fromMap(map);
      final therapistJson = therapist.toJson();

      // Adiciona informações do plano se existir
      if (map['plan_id'] != null) {
        therapistJson['plan'] = {
          'id': map['plan_id'],
          'name': map['plan_name'],
          'price': map['plan_price'],
          'patient_limit': map['plan_patient_limit'],
        };
      } else {
        // Se não houver plano, retorna um plano "free" padrão
        therapistJson['plan'] = {'id': 0, 'name': 'Free', 'price': 0.0, 'patient_limit': 5};
      }

      return therapistJson;
    });
  }

  Future<void> createPlanSubscription({
    required int therapistId,
    required int planId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _dbConnection.withConnection((conn) async {
      // Verifica se o plano existe e está ativo
      final planCheck = await conn.execute(
        Sql.named('''
        SELECT id, name, is_active 
        FROM plans 
        WHERE id = @plan_id
      '''),
        parameters: {'plan_id': planId},
      );

      if (planCheck.isEmpty) {
        throw Exception('Plano com ID $planId não encontrado.');
      }

      final planData = planCheck.first.toColumnMap();
      if (planData['is_active'] != true) {
        throw Exception('Plano selecionado não está ativo.');
      }

      // Se não fornecidas, usa a data atual como início e adiciona 1 mês como fim
      final subscriptionStartDate = startDate ?? DateTime.now();
      final subscriptionEndDate =
          endDate ?? DateTime(subscriptionStartDate.year, subscriptionStartDate.month + 1, subscriptionStartDate.day);

      await conn.execute(
        Sql.named('''
        INSERT INTO plan_subscriptions (
          therapist_id, plan_id, start_date, end_date, payment_method, is_active
        ) VALUES (
          @therapist_id, @plan_id, @start_date, @end_date, @payment_method::payment_method, @is_active
        );
      '''),
        parameters: {
          'therapist_id': therapistId,
          'plan_id': planId,
          'start_date': subscriptionStartDate,
          'end_date': subscriptionEndDate,
          'payment_method': 'credit_card', // Default - pode ser ajustado depois
          'is_active': true,
        },
      );
    });
  }
}
