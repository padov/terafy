import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_repository.dart';
import 'package:server/features/messaging/domain/message_template.dart';
import 'package:server/features/messaging/domain/message_channel.dart';

class MessageRepositoryImpl implements MessageRepository {
  final DBConnection _dbConnection;

  MessageRepositoryImpl(this._dbConnection);

  @override
  Future<Message> create(Message message) async {
    return await _dbConnection.withConnection((conn) async {
      final data = message.toDatabaseMap();
      data['created_at'] = DateTime.now().toUtc().toIso8601String();
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final result = await conn.execute(
        Sql.named('''
        INSERT INTO messages (
          message_type,
          channel,
          recipient_type,
          recipient_id,
          sender_id,
          subject,
          content,
          template_id,
          status,
          priority,
          scheduled_at,
          sent_at,
          delivered_at,
          read_at,
          error_message,
          metadata,
          related_entity_type,
          related_entity_id,
          created_at,
          updated_at
        ) VALUES (
          @message_type::message_type,
          @channel::message_channel,
          @recipient_type::recipient_type,
          @recipient_id,
          @sender_id,
          @subject,
          @content,
          @template_id,
          @status::message_status,
          @priority::message_priority,
          @scheduled_at::TIMESTAMP WITH TIME ZONE,
          @sent_at::TIMESTAMP WITH TIME ZONE,
          @delivered_at::TIMESTAMP WITH TIME ZONE,
          @read_at::TIMESTAMP WITH TIME ZONE,
          @error_message,
          CAST(@metadata AS JSONB),
          @related_entity_type,
          @related_entity_id,
          @created_at::TIMESTAMP WITH TIME ZONE,
          @updated_at::TIMESTAMP WITH TIME ZONE
        )
        RETURNING id,
                  message_type,
                  channel,
                  recipient_type,
                  recipient_id,
                  sender_id,
                  subject,
                  content,
                  template_id,
                  status,
                  priority,
                  scheduled_at,
                  sent_at,
                  delivered_at,
                  read_at,
                  error_message,
                  metadata,
                  related_entity_type,
                  related_entity_id,
                  created_at,
                  updated_at
      '''),
        parameters: {
          'message_type': data['message_type'],
          'channel': data['channel'],
          'recipient_type': data['recipient_type'],
          'recipient_id': data['recipient_id'],
          'sender_id': data['sender_id'],
          'subject': data['subject'],
          'content': data['content'],
          'template_id': data['template_id'],
          'status': data['status'],
          'priority': data['priority'],
          'scheduled_at': data['scheduled_at'],
          'sent_at': data['sent_at'],
          'delivered_at': data['delivered_at'],
          'read_at': data['read_at'],
          'error_message': data['error_message'],
          'metadata': data['metadata'] != null
              ? jsonEncode(data['metadata'])
              : null,
          'related_entity_type': data['related_entity_type'],
          'related_entity_id': data['related_entity_id'],
          'created_at': data['created_at'],
          'updated_at': data['updated_at'],
        },
      );

      if (result.isEmpty) {
        throw Exception('Falha ao criar mensagem');
      }

      return Message.fromMap(result.first.toColumnMap());
    });
  }

  @override
  Future<Message?> findById(int id) async {
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
        SELECT id,
               message_type,
               channel,
               recipient_type,
               recipient_id,
               sender_id,
               subject,
               content,
               template_id,
               status,
               priority,
               scheduled_at,
               sent_at,
               delivered_at,
               read_at,
               error_message,
               metadata,
               related_entity_type,
               related_entity_id,
               created_at,
               updated_at
        FROM messages
        WHERE id = @id
      '''),
        parameters: {'id': id},
      );

      if (result.isEmpty) {
        return null;
      }

      return Message.fromMap(result.first.toColumnMap());
    });
  }

  @override
  Future<List<Message>> findByRecipient({
    required RecipientType recipientType,
    required int recipientId,
    MessageStatus? status,
    MessageChannel? channel,
    int? limit,
    int? offset,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      final conditions = <String>[
        'recipient_type = @recipient_type',
        'recipient_id = @recipient_id',
      ];
      final params = <String, dynamic>{
        'recipient_type': recipientType.name,
        'recipient_id': recipientId,
      };

      if (status != null) {
        conditions.add('status = @status');
        params['status'] = status.name;
      }

      if (channel != null) {
        conditions.add('channel = @channel');
        params['channel'] = channel.name;
      }

      var query = '''
        SELECT id,
               message_type,
               channel,
               recipient_type,
               recipient_id,
               sender_id,
               subject,
               content,
               template_id,
               status,
               priority,
               scheduled_at,
               sent_at,
               delivered_at,
               read_at,
               error_message,
               metadata,
               related_entity_type,
               related_entity_id,
               created_at,
               updated_at
        FROM messages
        WHERE ${conditions.join(' AND ')}
        ORDER BY created_at DESC
      ''';

      if (limit != null) {
        query += ' LIMIT @limit';
        params['limit'] = limit;
      }

      if (offset != null) {
        query += ' OFFSET @offset';
        params['offset'] = offset;
      }

      final result = await conn.execute(
        Sql.named(query),
        parameters: params,
      );

      return result.map((row) => Message.fromMap(row.toColumnMap())).toList();
    });
  }

  @override
  Future<List<Message>> findByRelatedEntity({
    required String entityType,
    required int entityId,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
        SELECT id,
               message_type,
               channel,
               recipient_type,
               recipient_id,
               sender_id,
               subject,
               content,
               template_id,
               status,
               priority,
               scheduled_at,
               sent_at,
               delivered_at,
               read_at,
               error_message,
               metadata,
               related_entity_type,
               related_entity_id,
               created_at,
               updated_at
        FROM messages
        WHERE related_entity_type = @entity_type
          AND related_entity_id = @entity_id
        ORDER BY created_at DESC
      '''),
        parameters: {
          'entity_type': entityType,
          'entity_id': entityId,
        },
      );

      return result.map((row) => Message.fromMap(row.toColumnMap())).toList();
    });
  }

  @override
  Future<Message> updateStatus(
    int id,
    MessageStatus status, {
    String? errorMessage,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      final updates = <String>['status = @status::message_status'];
      final params = <String, dynamic>{
        'id': id,
        'status': status.name,
      };

      if (errorMessage != null) {
        updates.add('error_message = @error_message');
        params['error_message'] = errorMessage;
      }

      if (sentAt != null) {
        updates.add('sent_at = @sent_at::TIMESTAMP WITH TIME ZONE');
        params['sent_at'] = sentAt.toUtc().toIso8601String();
      }

      if (deliveredAt != null) {
        updates.add('delivered_at = @delivered_at::TIMESTAMP WITH TIME ZONE');
        params['delivered_at'] = deliveredAt.toUtc().toIso8601String();
      }

      if (readAt != null) {
        updates.add('read_at = @read_at::TIMESTAMP WITH TIME ZONE');
        params['read_at'] = readAt.toUtc().toIso8601String();
      }

      updates.add('updated_at = NOW()');

      final result = await conn.execute(
        Sql.named('''
        UPDATE messages
        SET ${updates.join(', ')}
        WHERE id = @id
        RETURNING id,
                  message_type,
                  channel,
                  recipient_type,
                  recipient_id,
                  sender_id,
                  subject,
                  content,
                  template_id,
                  status,
                  priority,
                  scheduled_at,
                  sent_at,
                  delivered_at,
                  read_at,
                  error_message,
                  metadata,
                  related_entity_type,
                  related_entity_id,
                  created_at,
                  updated_at
      '''),
        parameters: params,
      );

      if (result.isEmpty) {
        throw Exception('Mensagem não encontrada');
      }

      return Message.fromMap(result.first.toColumnMap());
    });
  }

  @override
  Future<List<Message>> findScheduledMessages(DateTime before) async {
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
        SELECT id,
               message_type,
               channel,
               recipient_type,
               recipient_id,
               sender_id,
               subject,
               content,
               template_id,
               status,
               priority,
               scheduled_at,
               sent_at,
               delivered_at,
               read_at,
               error_message,
               metadata,
               related_entity_type,
               related_entity_id,
               created_at,
               updated_at
        FROM messages
        WHERE scheduled_at IS NOT NULL
          AND scheduled_at <= @before::TIMESTAMP WITH TIME ZONE
          AND status IN ('pending', 'scheduled')
        ORDER BY scheduled_at ASC
      '''),
        parameters: {'before': before.toUtc().toIso8601String()},
      );

      return result.map((row) => Message.fromMap(row.toColumnMap())).toList();
    });
  }

  @override
  Future<MessageTemplate> createTemplate(MessageTemplate template) async {
    return await _dbConnection.withConnection((conn) async {
      final data = template.toDatabaseMap();
      data['created_at'] = DateTime.now().toUtc().toIso8601String();
      data['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final result = await conn.execute(
        Sql.named('''
        INSERT INTO message_templates (
          name,
          type,
          channel,
          subject_template,
          content_template,
          variables,
          is_active,
          created_at,
          updated_at
        ) VALUES (
          @name,
          @type::message_type,
          @channel::message_channel,
          @subject_template,
          @content_template,
          CAST(@variables AS JSONB),
          @is_active,
          @created_at::TIMESTAMP WITH TIME ZONE,
          @updated_at::TIMESTAMP WITH TIME ZONE
        )
        RETURNING id,
                  name,
                  type,
                  channel,
                  subject_template,
                  content_template,
                  variables,
                  is_active,
                  created_at,
                  updated_at
      '''),
        parameters: {
          'name': data['name'],
          'type': data['type'],
          'channel': data['channel'],
          'subject_template': data['subject_template'],
          'content_template': data['content_template'],
          'variables': jsonEncode(data['variables']),
          'is_active': data['is_active'],
          'created_at': data['created_at'],
          'updated_at': data['updated_at'],
        },
      );

      if (result.isEmpty) {
        throw Exception('Falha ao criar template');
      }

      return MessageTemplate.fromMap(result.first.toColumnMap());
    });
  }

  @override
  Future<MessageTemplate?> findTemplateById(int id) async {
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
        SELECT id,
               name,
               type,
               channel,
               subject_template,
               content_template,
               variables,
               is_active,
               created_at,
               updated_at
        FROM message_templates
        WHERE id = @id
      '''),
        parameters: {'id': id},
      );

      if (result.isEmpty) {
        return null;
      }

      return MessageTemplate.fromMap(result.first.toColumnMap());
    });
  }

  @override
  Future<MessageTemplate?> findTemplateByTypeAndChannel({
    required MessageType type,
    required MessageChannel channel,
  }) async {
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
        SELECT id,
               name,
               type,
               channel,
               subject_template,
               content_template,
               variables,
               is_active,
               created_at,
               updated_at
        FROM message_templates
        WHERE type = @type::message_type
          AND channel = @channel::message_channel
          AND is_active = TRUE
        LIMIT 1
      '''),
        parameters: {
          'type': type.name,
          'channel': channel.name,
        },
      );

      if (result.isEmpty) {
        return null;
      }

      return MessageTemplate.fromMap(result.first.toColumnMap());
    });
  }

  @override
  Future<List<MessageTemplate>> listActiveTemplates() async {
    return await _dbConnection.withConnection((conn) async {
      final result = await conn.execute(
        Sql.named('''
        SELECT id,
               name,
               type,
               channel,
               subject_template,
               content_template,
               variables,
               is_active,
               created_at,
               updated_at
        FROM message_templates
        WHERE is_active = TRUE
        ORDER BY type, channel
      '''),
      );

      return result
          .map((row) => MessageTemplate.fromMap(row.toColumnMap()))
          .toList();
    });
  }
}

