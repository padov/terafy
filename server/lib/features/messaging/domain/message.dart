import 'message_channel.dart';

/// Entidade de mensagem
class Message {
  final int? id;
  final MessageType messageType;
  final MessageChannel channel;
  final RecipientType recipientType;
  final int recipientId;
  final int? senderId;
  final String subject;
  final String content;
  final int? templateId;
  final MessageStatus status;
  final MessagePriority priority;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final String? relatedEntityType; // 'appointment', 'session', etc.
  final int? relatedEntityId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Message({
    this.id,
    required this.messageType,
    required this.channel,
    required this.recipientType,
    required this.recipientId,
    this.senderId,
    required this.subject,
    required this.content,
    this.templateId,
    this.status = MessageStatus.pending,
    this.priority = MessagePriority.normal,
    this.scheduledAt,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.errorMessage,
    this.metadata,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.createdAt,
    required this.updatedAt,
  });

  Message copyWith({
    int? id,
    MessageType? messageType,
    MessageChannel? channel,
    RecipientType? recipientType,
    int? recipientId,
    int? senderId,
    String? subject,
    String? content,
    int? templateId,
    MessageStatus? status,
    MessagePriority? priority,
    DateTime? scheduledAt,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    String? relatedEntityType,
    int? relatedEntityId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Message(
      id: id ?? this.id,
      messageType: messageType ?? this.messageType,
      channel: channel ?? this.channel,
      recipientType: recipientType ?? this.recipientType,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      templateId: templateId ?? this.templateId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converte para mapa para inserção no banco
  Map<String, dynamic> toDatabaseMap() {
    return {
      'message_type': messageType.name,
      'channel': channel.name,
      'recipient_type': recipientType.name,
      'recipient_id': recipientId,
      'sender_id': senderId,
      'subject': subject,
      'content': content,
      'template_id': templateId,
      'status': status.name,
      'priority': priority.name,
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      'sent_at': sentAt?.toUtc().toIso8601String(),
      'delivered_at': deliveredAt?.toUtc().toIso8601String(),
      'read_at': readAt?.toUtc().toIso8601String(),
      'error_message': errorMessage,
      'metadata': metadata != null ? metadata : null,
      'related_entity_type': relatedEntityType,
      'related_entity_id': relatedEntityId,
    };
  }

  /// Cria a partir de um mapa do banco
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as int,
      messageType: MessageType.values.firstWhere(
        (e) => e.name == map['message_type'],
      ),
      channel: MessageChannel.values.firstWhere(
        (e) => e.name == map['channel'],
      ),
      recipientType: RecipientType.values.firstWhere(
        (e) => e.name == map['recipient_type'],
      ),
      recipientId: map['recipient_id'] as int,
      senderId: map['sender_id'] as int?,
      subject: map['subject'] as String,
      content: map['content'] as String,
      templateId: map['template_id'] as int?,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      priority: MessagePriority.values.firstWhere(
        (e) => e.name == map['priority'],
      ),
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.parse(map['scheduled_at'] as String).toLocal()
          : null,
      sentAt: map['sent_at'] != null
          ? DateTime.parse(map['sent_at'] as String).toLocal()
          : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.parse(map['delivered_at'] as String).toLocal()
          : null,
      readAt: map['read_at'] != null
          ? DateTime.parse(map['read_at'] as String).toLocal()
          : null,
      errorMessage: map['error_message'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
      relatedEntityType: map['related_entity_type'] as String?,
      relatedEntityId: map['related_entity_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }
}

