import 'message.dart';
import 'message_channel.dart';

/// Resultado do envio de mensagem
class MessageSendResult {
  final bool success;
  final String? messageId; // ID externo do provedor (se disponível)
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const MessageSendResult({
    required this.success,
    this.messageId,
    this.errorMessage,
    this.metadata,
  });
}

/// Interface para provedores de mensagens
abstract class MessageProvider {
  /// Canal suportado por este provider
  MessageChannel get channel;

  /// Envia uma mensagem
  /// Retorna o resultado do envio com informações sobre sucesso/falha
  Future<MessageSendResult> send(Message message);

  /// Valida se a mensagem pode ser enviada por este canal
  /// Retorna lista de erros (vazia se válida)
  Future<List<String>> validate(Message message);

  /// Obtém o status de uma mensagem enviada (se o provedor suportar)
  /// Retorna null se não for possível obter o status
  Future<MessageStatus?> getStatus(String externalMessageId);
}

