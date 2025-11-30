import 'message.dart';
import 'message_template.dart';
import 'message_channel.dart';

/// Interface para repositório de mensagens
abstract class MessageRepository {
  /// Cria uma nova mensagem
  Future<Message> create(Message message);

  /// Busca uma mensagem por ID
  Future<Message?> findById(int id);

  /// Busca mensagens por destinatário
  Future<List<Message>> findByRecipient({
    required RecipientType recipientType,
    required int recipientId,
    MessageStatus? status,
    MessageChannel? channel,
    int? limit,
    int? offset,
  });

  /// Busca mensagens relacionadas a uma entidade
  Future<List<Message>> findByRelatedEntity({
    required String entityType,
    required int entityId,
  });

  /// Atualiza o status de uma mensagem
  Future<Message> updateStatus(
    int id,
    MessageStatus status, {
    String? errorMessage,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
  });

  /// Busca mensagens agendadas que devem ser enviadas
  Future<List<Message>> findScheduledMessages(DateTime before);

  /// Cria um template
  Future<MessageTemplate> createTemplate(MessageTemplate template);

  /// Busca template por ID
  Future<MessageTemplate?> findTemplateById(int id);

  /// Busca template por tipo e canal
  Future<MessageTemplate?> findTemplateByTypeAndChannel({
    required MessageType type,
    required MessageChannel channel,
  });

  /// Lista todos os templates ativos
  Future<List<MessageTemplate>> listActiveTemplates();
}

