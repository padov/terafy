import 'dart:convert';
import 'package:common/common.dart';
import 'package:server/features/messaging/providers/whatsapp_message_provider.dart';
import 'package:server/features/whatsapp/services/conversation_manager.dart';
import 'package:server/features/whatsapp/whatsapp.repository.dart';

/// Handler para webhooks do Evolution API
class WhatsAppWebhookHandler {
  final ConversationManager _conversationManager;
  final WhatsAppRepository _whatsappRepository;
  final WhatsAppMessageProvider _whatsappProvider;

  WhatsAppWebhookHandler(
    this._conversationManager,
    this._whatsappRepository,
    this._whatsappProvider,
  );

  /// Processa evento recebido do webhook
  Future<void> processWebhookEvent(Map<String, dynamic> event) async {
    AppLogger.func();

    try {
      final eventType = event['event'] as String?;
      final data = event['data'] as Map<String, dynamic>?;

      if (data == null) {
        AppLogger.warning('Webhook sem dados: $event');
        return;
      }

      switch (eventType) {
        case 'messages.upsert':
          await _handleMessageUpsert(data);
          break;
        case 'messages.update':
          await _handleMessageUpdate(data);
          break;
        case 'connection.update':
          await _handleConnectionUpdate(data);
          break;
        default:
          AppLogger.info('Evento não tratado: $eventType');
      }
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
    }
  }

  /// Processa nova mensagem recebida
  Future<void> _handleMessageUpsert(Map<String, dynamic> data) async {
    final message = data['messages']?[0] as Map<String, dynamic>?;
    if (message == null) return;

    final key = message['key'] as Map<String, dynamic>?;
    final messageData = message['message'] as Map<String, dynamic>?;

    if (key == null || messageData == null) return;

    // Verifica se é mensagem recebida (não enviada por nós)
    final fromMe = key['fromMe'] as bool? ?? false;
    if (fromMe) return; // Ignora mensagens que enviamos

    final remoteJid = key['remoteJid'] as String?;
    if (remoteJid == null) return;

    // Extrai número de telefone (remove @s.whatsapp.net)
    final phoneNumber = remoteJid.split('@').first;

    // Busca instância para identificar o terapeuta
    // TODO: Implementar busca de instância pelo número
    // Por enquanto, assume que há apenas uma instância
    final instance = await _whatsappRepository.getInstanceByTherapist(1); // TODO: Buscar corretamente
    if (instance == null) {
      AppLogger.warning('Instância WhatsApp não encontrada para número: $phoneNumber');
      return;
    }

    // Extrai texto da mensagem
    String? messageText;
    String? buttonId;
    String? listItemId;

    // Tenta extrair texto
    if (messageData['conversation'] != null) {
      messageText = messageData['conversation'] as String?;
    } else if (messageData['extendedTextMessage'] != null) {
      final extended = messageData['extendedTextMessage'] as Map<String, dynamic>?;
      messageText = extended?['text'] as String?;
    }

    // Tenta extrair resposta de botão
    if (messageData['buttonsResponseMessage'] != null) {
      final buttonResponse = messageData['buttonsResponseMessage'] as Map<String, dynamic>?;
      buttonId = buttonResponse?['selectedButtonId'] as String?;
      messageText = buttonId; // Usa o ID do botão como texto
    }

    // Tenta extrair resposta de lista
    if (messageData['listResponseMessage'] != null) {
      final listResponse = messageData['listResponseMessage'] as Map<String, dynamic>?;
      listItemId = listResponse?['singleSelectReply']?['selectedRowId'] as String?;
      messageText = listItemId; // Usa o ID do item como texto
    }

    if (messageText == null) {
      AppLogger.info('Mensagem sem texto processável: ${jsonEncode(messageData)}');
      return;
    }

    // Processa mensagem através do ConversationManager
    final response = await _conversationManager.processMessage(
      phoneNumber: phoneNumber,
      therapistId: instance.therapistId,
      messageText: messageText,
      buttonId: buttonId,
      listItemId: listItemId,
    );

    // Atualiza conversa
    await _whatsappRepository.updateConversation(response.conversation);

    // Envia resposta
    await _sendResponse(
      phoneNumber: phoneNumber,
      message: response.message,
      buttons: response.buttons,
      listItems: response.listItems,
    );
  }

  /// Processa atualização de mensagem (status de entrega/leitura)
  Future<void> _handleMessageUpdate(Map<String, dynamic> data) async {
    // TODO: Implementar atualização de status de mensagens
    AppLogger.info('Message update: ${jsonEncode(data)}');
  }

  /// Processa atualização de conexão
  Future<void> _handleConnectionUpdate(Map<String, dynamic> data) async {
    // TODO: Implementar atualização de status da instância
    AppLogger.info('Connection update: ${jsonEncode(data)}');
  }

  /// Envia resposta ao paciente
  Future<void> _sendResponse({
    required String phoneNumber,
    required String message,
    List<Map<String, String>>? buttons,
    List<Map<String, dynamic>>? listItems,
  }) async {
    try {
      if (buttons != null && buttons.isNotEmpty) {
        // Envia mensagem com botões
        final result = await _whatsappProvider.sendButtons(
          phoneNumber,
          message,
          buttons,
        );
        if (!result.success) {
          AppLogger.error('Erro ao enviar mensagem com botões: ${result.errorMessage}');
        }
      } else if (listItems != null && listItems.isNotEmpty) {
        // Envia mensagem com lista
        final result = await _whatsappProvider.sendList(
          phoneNumber,
          'Escolha uma opção',
          message,
          listItems,
        );
        if (!result.success) {
          AppLogger.error('Erro ao enviar mensagem com lista: ${result.errorMessage}');
        }
      } else {
        // Envia mensagem de texto simples
        final result = await _whatsappProvider.sendText(phoneNumber, message);
        if (!result.success) {
          AppLogger.error('Erro ao enviar mensagem: ${result.errorMessage}');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
    }
  }
}

