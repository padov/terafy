import 'package:server/features/messaging/domain/message_repository.dart';
import 'package:server/features/messaging/usecases/send_message_usecase.dart';
import 'package:server/features/whatsapp/services/whatsapp_confirmation_service.dart';
import 'package:common/common.dart';

/// Serviço para processar lembretes agendados
class ReminderScheduler {
  final MessageRepository _messageRepository;
  final SendMessageUseCase _sendMessageUseCase;
  final WhatsAppConfirmationService? _whatsappConfirmationService;

  ReminderScheduler(
    this._messageRepository,
    this._sendMessageUseCase, {
    WhatsAppConfirmationService? whatsappConfirmationService,
  }) : _whatsappConfirmationService = whatsappConfirmationService;

  /// Processa mensagens agendadas que devem ser enviadas agora
  Future<int> processScheduledMessages() async {
    AppLogger.func();

    final now = DateTime.now();
    final scheduledMessages = await _messageRepository.findScheduledMessages(now);

    if (scheduledMessages.isEmpty) {
      AppLogger.info('Nenhuma mensagem agendada para processar');
      return 0;
    }

    AppLogger.info('Processando ${scheduledMessages.length} mensagem(ns) agendada(s)');

    int processed = 0;
    int failed = 0;

    for (final message in scheduledMessages) {
      try {
        await _sendMessageUseCase.execute(message);
        processed++;
        AppLogger.info('Mensagem ${message.id} enviada com sucesso');
      } catch (e, stackTrace) {
        failed++;
        AppLogger.error(e, stackTrace);
        AppLogger.error('Falha ao enviar mensagem ${message.id}: ${e.toString()}');
      }
    }

    AppLogger.info('Processamento concluído: $processed enviadas, $failed falhas');

    return processed;
  }

  /// Processa confirmações WhatsApp para todos os terapeutas
  Future<int> processWhatsAppConfirmations() async {
    AppLogger.func();

    if (_whatsappConfirmationService == null) {
      AppLogger.info('WhatsAppConfirmationService não configurado');
      return 0;
    }

    // TODO: Buscar todos os terapeutas com WhatsApp habilitado
    // Por enquanto, retorna 0
    // Em produção, deve buscar da tabela whatsapp_instances e processar para cada um
    AppLogger.info('Processamento de confirmações WhatsApp ainda não implementado completamente');

    return 0;
  }
}

