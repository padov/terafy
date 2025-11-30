import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/features/whatsapp/domain/whatsapp_conversation.dart';
import 'package:server/features/whatsapp/domain/whatsapp_instance.dart';

class WhatsAppRepository {
  final DBConnection _dbConnection;

  WhatsAppRepository(this._dbConnection);

  /// Busca ou cria uma conversa
  Future<WhatsAppConversation> getOrCreateConversation({
    required String phoneNumber,
    required int therapistId,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      // Tenta buscar conversa existente
      final existing = await conn.execute(
        Sql.named('''
        SELECT id,
               phone_number,
               patient_id,
               therapist_id,
               current_state,
               context_data,
               last_interaction_at,
               created_at,
               updated_at
        FROM whatsapp_conversations
        WHERE phone_number = @phone_number
          AND therapist_id = @therapist_id
      '''),
        parameters: {
          'phone_number': phoneNumber,
          'therapist_id': therapistId,
        },
      );

      if (existing.isNotEmpty) {
        return WhatsAppConversation.fromMap(existing.first.toColumnMap());
      }

      // Cria nova conversa
      final now = DateTime.now();
      final result = await conn.execute(
        Sql.named('''
        INSERT INTO whatsapp_conversations (
          phone_number,
          therapist_id,
          current_state,
          context_data,
          last_interaction_at,
          created_at,
          updated_at
        ) VALUES (
          @phone_number,
          @therapist_id,
          @current_state,
          CAST(@context_data AS JSONB),
          @last_interaction_at::TIMESTAMP WITH TIME ZONE,
          @created_at::TIMESTAMP WITH TIME ZONE,
          @updated_at::TIMESTAMP WITH TIME ZONE
        )
        RETURNING id,
                  phone_number,
                  patient_id,
                  therapist_id,
                  current_state,
                  context_data,
                  last_interaction_at,
                  created_at,
                  updated_at
      '''),
        parameters: {
          'phone_number': phoneNumber,
          'therapist_id': therapistId,
          'current_state': ConversationState.idle.name,
          'context_data': jsonEncode({}),
          'last_interaction_at': now.toUtc().toIso8601String(),
          'created_at': now.toUtc().toIso8601String(),
          'updated_at': now.toUtc().toIso8601String(),
        },
      );

      return WhatsAppConversation.fromMap(result.first.toColumnMap());
    });
  }

  /// Atualiza uma conversa
  Future<WhatsAppConversation> updateConversation(WhatsAppConversation conversation) async {
    return await _dbConnection.withConnection((conn) async {
      final data = conversation.toDatabaseMap();
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final result = await conn.execute(
        Sql.named('''
        UPDATE whatsapp_conversations
        SET phone_number = @phone_number,
            patient_id = @patient_id,
            therapist_id = @therapist_id,
            current_state = @current_state,
            context_data = CAST(@context_data AS JSONB),
            last_interaction_at = @last_interaction_at::TIMESTAMP WITH TIME ZONE,
            updated_at = @updated_at::TIMESTAMP WITH TIME ZONE
        WHERE id = @id
        RETURNING id,
                  phone_number,
                  patient_id,
                  therapist_id,
                  current_state,
                  context_data,
                  last_interaction_at,
                  created_at,
                  updated_at
      '''),
        parameters: {
          'id': conversation.id,
          'phone_number': data['phone_number'],
          'patient_id': data['patient_id'],
          'therapist_id': data['therapist_id'],
          'current_state': data['current_state'],
          'context_data': jsonEncode(data['context_data']),
          'last_interaction_at': data['last_interaction_at'],
          'updated_at': data['updated_at'],
        },
      );

      if (result.isEmpty) {
        throw Exception('Conversa não encontrada');
      }

      return WhatsAppConversation.fromMap(result.first.toColumnMap());
    });
  }

  /// Busca instância WhatsApp do terapeuta
  Future<WhatsAppInstance?> getInstanceByTherapist(int therapistId) async {
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
        SELECT id,
               therapist_id,
               instance_name,
               api_key,
               phone_number,
               status,
               webhook_url,
               created_at,
               updated_at
        FROM whatsapp_instances
        WHERE therapist_id = @therapist_id
      '''),
        parameters: {'therapist_id': therapistId},
      );

      if (result.isEmpty) {
        return null;
      }

      return WhatsAppInstance.fromMap(result.first.toColumnMap());
    });
  }

  /// Cria ou atualiza instância WhatsApp
  Future<WhatsAppInstance> upsertInstance(WhatsAppInstance instance) async {
    return await _dbConnection.withConnection((conn) async {
      final data = instance.toDatabaseMap();
      data['created_at'] = DateTime.now().toUtc().toIso8601String();
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final result = await conn.execute(
        Sql.named('''
        INSERT INTO whatsapp_instances (
          therapist_id,
          instance_name,
          api_key,
          phone_number,
          status,
          webhook_url,
          created_at,
          updated_at
        ) VALUES (
          @therapist_id,
          @instance_name,
          @api_key,
          @phone_number,
          @status,
          @webhook_url,
          @created_at::TIMESTAMP WITH TIME ZONE,
          @updated_at::TIMESTAMP WITH TIME ZONE
        )
        ON CONFLICT (therapist_id) DO UPDATE
        SET instance_name = @instance_name,
            api_key = @api_key,
            phone_number = @phone_number,
            status = @status,
            webhook_url = @webhook_url,
            updated_at = @updated_at::TIMESTAMP WITH TIME ZONE
        RETURNING id,
                  therapist_id,
                  instance_name,
                  api_key,
                  phone_number,
                  status,
                  webhook_url,
                  created_at,
                  updated_at
      '''),
        parameters: {
          'therapist_id': data['therapist_id'],
          'instance_name': data['instance_name'],
          'api_key': data['api_key'],
          'phone_number': data['phone_number'],
          'status': data['status'],
          'webhook_url': data['webhook_url'],
          'created_at': data['created_at'],
          'updated_at': data['updated_at'],
        },
      );

      return WhatsAppInstance.fromMap(result.first.toColumnMap());
    });
  }
}

