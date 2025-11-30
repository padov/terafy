import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_provider.dart';
import 'package:server/features/messaging/domain/message_channel.dart';

/// Classe base abstrata para provedores de mensagens
abstract class BaseMessageProvider implements MessageProvider {
  @override
  Future<List<String>> validate(Message message) async {
    final errors = <String>[];

    // Validações básicas comuns a todos os provedores
    if (message.subject.isEmpty) {
      errors.add('Assunto não pode estar vazio');
    }

    if (message.content.isEmpty) {
      errors.add('Conteúdo não pode estar vazio');
    }

    // Validações específicas do canal (implementar nas subclasses)
    errors.addAll(await validateChannelSpecific(message));

    return errors;
  }

  /// Validações específicas do canal (implementar nas subclasses)
  Future<List<String>> validateChannelSpecific(Message message);

  @override
  Future<MessageStatus?> getStatus(String externalMessageId) async {
    // Implementação padrão retorna null
    // Provedores específicos podem sobrescrever para suportar verificação de status
    return null;
  }
}

