import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_repository.dart';
import 'package:server/features/messaging/domain/message_channel.dart';

/// UseCase para buscar histórico de mensagens
class GetMessageHistoryUseCase {
  final MessageRepository _repository;

  GetMessageHistoryUseCase(this._repository);

  /// Busca histórico de mensagens por destinatário
  Future<List<Message>> execute({
    required RecipientType recipientType,
    required int recipientId,
    MessageStatus? status,
    MessageChannel? channel,
    int? limit,
    int? offset,
  }) async {
    return await _repository.findByRecipient(
      recipientType: recipientType,
      recipientId: recipientId,
      status: status,
      channel: channel,
      limit: limit ?? 50,
      offset: offset ?? 0,
    );
  }

  /// Busca mensagens relacionadas a uma entidade
  Future<List<Message>> executeByRelatedEntity({
    required String entityType,
    required int entityId,
  }) async {
    return await _repository.findByRelatedEntity(
      entityType: entityType,
      entityId: entityId,
    );
  }
}

