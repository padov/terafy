import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_channel.dart';
import 'package:server/features/messaging/domain/message_provider.dart';
import 'package:server/features/messaging/providers/base_message_provider.dart';
import 'package:common/common.dart';

/// Provider para envio de notificações push
/// TODO: Implementar usando Firebase Cloud Messaging ou similar
class PushMessageProvider extends BaseMessageProvider {
  @override
  MessageChannel get channel => MessageChannel.push;

  @override
  Future<List<String>> validateChannelSpecific(Message message) async {
    final errors = <String>[];

    // Valida se o destinatário tem token de push (deve ser passado via metadata)
    final pushToken = message.metadata?['push_token'] as String?;
    if (pushToken == null || pushToken.isEmpty) {
      errors.add('Token de push do destinatário não fornecido');
    }

    return errors;
  }

  @override
  Future<MessageSendResult> send(Message message) async {
    // TODO: Implementar envio real de push usando FCM ou similar
    AppLogger.info('🔔 [TODO] Push seria enviado:');
    AppLogger.info('   Para: ${message.metadata?['push_token']}');
    AppLogger.info('   Título: ${message.subject}');
    AppLogger.info('   Conteúdo: ${message.content.substring(0, message.content.length > 100 ? 100 : message.content.length)}...');

    return MessageSendResult(
      success: false,
      errorMessage: 'Push não implementado ainda',
    );
  }
}

