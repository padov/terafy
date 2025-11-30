import 'package:server/core/config/env_config.dart';
import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_channel.dart';
import 'package:server/features/messaging/domain/message_provider.dart';
import 'package:server/features/messaging/providers/base_message_provider.dart';
import 'package:common/common.dart';

/// Provider para envio de emails via SMTP
/// 
/// NOTA: Esta é uma implementação simplificada que loga o email.
/// Em produção, recomenda-se usar um pacote como 'mailer' ou serviço externo
/// como SendGrid, SES, etc.
class EmailMessageProvider extends BaseMessageProvider {
  @override
  MessageChannel get channel => MessageChannel.email;

  final String? _smtpHost;
  final int? _smtpPort;
  final String? _smtpUser;
  final String? _smtpPassword;
  final String? _fromEmail;
  final String? _fromName;
  final bool _useTls;

  EmailMessageProvider({
    String? smtpHost,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    String? fromEmail,
    String? fromName,
    bool? useTls,
  })  : _smtpHost = smtpHost ?? EnvConfig.get('SMTP_HOST'),
        _smtpPort = smtpPort ?? EnvConfig.getInt('SMTP_PORT'),
        _smtpUser = smtpUser ?? EnvConfig.get('SMTP_USER'),
        _smtpPassword = smtpPassword ?? EnvConfig.get('SMTP_PASSWORD'),
        _fromEmail = fromEmail ?? EnvConfig.get('SMTP_FROM_EMAIL'),
        _fromName = fromName ?? EnvConfig.get('SMTP_FROM_NAME'),
        _useTls = useTls ?? EnvConfig.getBoolOrDefault('SMTP_USE_TLS', true);

  @override
  Future<List<String>> validateChannelSpecific(Message message) async {
    final errors = <String>[];

    // Valida se o destinatário tem email (precisa ser obtido externamente)
    // Esta validação será feita no UseCase que tem acesso ao Patient/Therapist

    // Valida configuração SMTP (opcional em desenvolvimento)
    // Em produção, essas validações devem ser obrigatórias
    final isProduction = EnvConfig.getBoolOrDefault('PRODUCTION', false);
    if (isProduction) {
      if (_smtpHost == null || _smtpHost.isEmpty) {
        errors.add('SMTP_HOST não configurado');
      }

      if (_smtpPort == null) {
        errors.add('SMTP_PORT não configurado');
      }

      if (_fromEmail == null || _fromEmail.isEmpty) {
        errors.add('SMTP_FROM_EMAIL não configurado');
      }
    }

    return errors;
  }

  @override
  Future<MessageSendResult> send(Message message) async {
    try {
      // Valida antes de enviar
      final validationErrors = await validate(message);
      if (validationErrors.isNotEmpty) {
        return MessageSendResult(
          success: false,
          errorMessage: validationErrors.join('; '),
        );
      }

      // Obtém o email do destinatário (deve ser passado via metadata)
      final recipientEmail = message.metadata?['recipient_email'] as String?;
      if (recipientEmail == null || recipientEmail.isEmpty) {
        return MessageSendResult(
          success: false,
          errorMessage: 'Email do destinatário não fornecido',
        );
      }

      // Em desenvolvimento, apenas loga o email
      // Em produção, aqui seria feita a conexão SMTP real
      final isProduction = EnvConfig.getBoolOrDefault('PRODUCTION', false);
      
      if (isProduction && _smtpHost != null && _smtpPort != null) {
        // TODO: Implementar envio SMTP real usando pacote 'mailer' ou similar
        // Por enquanto, apenas loga
        AppLogger.info('📧 Email enviado (simulado):');
        AppLogger.info('   Para: $recipientEmail');
        AppLogger.info('   Assunto: ${message.subject}');
        AppLogger.info('   Conteúdo: ${message.content.substring(0, message.content.length > 100 ? 100 : message.content.length)}...');
      } else {
        // Modo desenvolvimento: apenas loga
        AppLogger.info('📧 [DEV] Email seria enviado:');
        AppLogger.info('   Para: $recipientEmail');
        AppLogger.info('   Assunto: ${message.subject}');
        AppLogger.info('   Conteúdo: ${message.content.substring(0, message.content.length > 100 ? 100 : message.content.length)}...');
        AppLogger.info('   ⚠️  SMTP não configurado - email não foi enviado realmente');
      }

      return MessageSendResult(
        success: true,
        metadata: {
          'sent_via': isProduction ? 'smtp' : 'dev_log',
          'recipient_email': recipientEmail,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return MessageSendResult(
        success: false,
        errorMessage: 'Erro ao enviar email: ${e.toString()}',
      );
    }
  }
}

