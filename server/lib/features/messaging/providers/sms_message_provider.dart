import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_channel.dart';
import 'package:server/features/messaging/domain/message_provider.dart';
import 'package:server/features/messaging/providers/base_message_provider.dart';
import 'package:common/common.dart';

/// Provider para envio de SMS
/// TODO: Implementar usando Twilio ou outro serviço de SMS
class SMSMessageProvider extends BaseMessageProvider {
  @override
  MessageChannel get channel => MessageChannel.sms;

  @override
  Future<List<String>> validateChannelSpecific(Message message) async {
    final errors = <String>[];

    // Valida se o destinatário tem telefone (deve ser passado via metadata)
    final recipientPhone = message.metadata?['recipient_phone'] as String?;
    if (recipientPhone == null || recipientPhone.isEmpty) {
      errors.add('Telefone do destinatário não fornecido');
    }

    return errors;
  }

  @override
  Future<MessageSendResult> send(Message message) async {
    // TODO: Implementar envio real de SMS usando Twilio ou similar
    AppLogger.info('📱 [TODO] SMS seria enviado:');
    AppLogger.info('   Para: ${message.metadata?['recipient_phone']}');
    AppLogger.info('   Conteúdo: ${message.content.substring(0, message.content.length > 100 ? 100 : message.content.length)}...');

    return MessageSendResult(
      success: false,
      errorMessage: 'SMS não implementado ainda',
    );
  }
}

