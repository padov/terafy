import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:server/core/config/env_config.dart';
import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_channel.dart';
import 'package:server/features/messaging/domain/message_provider.dart';
import 'package:server/features/messaging/providers/base_message_provider.dart';
import 'package:common/common.dart';

/// Provider para envio de WhatsApp usando Evolution API
class WhatsAppMessageProvider extends BaseMessageProvider {
  @override
  MessageChannel get channel => MessageChannel.whatsapp;

  final String? _apiUrl;
  final String? _apiKey;
  final String? _instanceName;

  WhatsAppMessageProvider({
    String? apiUrl,
    String? apiKey,
    String? instanceName,
  })  : _apiUrl = apiUrl ?? EnvConfig.get('WHATSAPP_API_URL'),
        _apiKey = apiKey ?? EnvConfig.get('WHATSAPP_API_KEY'),
        _instanceName = instanceName ?? EnvConfig.get('WHATSAPP_INSTANCE_NAME');

  @override
  Future<List<String>> validateChannelSpecific(Message message) async {
    final errors = <String>[];

    // Valida se o destinatário tem telefone (deve ser passado via metadata)
    final recipientPhone = message.metadata?['recipient_phone'] as String?;
    if (recipientPhone == null || recipientPhone.isEmpty) {
      errors.add('Telefone do destinatário não fornecido');
    }

    // Valida configuração da API
    final isProduction = EnvConfig.getBoolOrDefault('PRODUCTION', false);
    if (isProduction) {
      if (_apiUrl == null || _apiUrl.isEmpty) {
        errors.add('WHATSAPP_API_URL não configurado');
      }
      if (_apiKey == null || _apiKey.isEmpty) {
        errors.add('WHATSAPP_API_KEY não configurado');
      }
      if (_instanceName == null || _instanceName.isEmpty) {
        errors.add('WHATSAPP_INSTANCE_NAME não configurado');
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

      final recipientPhone = message.metadata?['recipient_phone'] as String;
      final phoneNumber = _normalizePhoneNumber(recipientPhone);

      // Verifica se tem botões no metadata
      final buttons = message.metadata?['buttons'] as List?;
      final listItems = message.metadata?['list_items'] as List?;

      if (buttons != null && buttons.isNotEmpty) {
        return await sendButtons(phoneNumber, message.content, buttons);
      } else if (listItems != null && listItems.isNotEmpty) {
        return await sendList(phoneNumber, message.subject, message.content, listItems);
      } else {
        return await sendText(phoneNumber, message.content);
      }
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return MessageSendResult(
        success: false,
        errorMessage: 'Erro ao enviar WhatsApp: ${e.toString()}',
      );
    }
  }

  /// Envia mensagem de texto simples
  Future<MessageSendResult> sendText(String phoneNumber, String text) async {
    final isProduction = EnvConfig.getBoolOrDefault('PRODUCTION', false);

    if (!isProduction || _apiUrl == null || _apiKey == null || _instanceName == null) {
      // Modo desenvolvimento: apenas loga
      AppLogger.info('💬 [DEV] WhatsApp seria enviado:');
      AppLogger.info('   Para: $phoneNumber');
      AppLogger.info('   Conteúdo: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
      AppLogger.info('   ⚠️  WhatsApp API não configurado - mensagem não foi enviada realmente');

      return MessageSendResult(
        success: true,
        metadata: {'sent_via': 'dev_log', 'recipient_phone': phoneNumber},
      );
    }

    try {
      final url = '$_apiUrl/message/sendText/$_instanceName';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _apiKey ?? '',
        },
        body: jsonEncode({
          'number': phoneNumber,
          'text': text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return MessageSendResult(
          success: true,
          messageId: responseData['key']?['id'] as String?,
          metadata: {
            'sent_via': 'evolution_api',
            'recipient_phone': phoneNumber,
            'response': responseData,
          },
        );
      } else {
        return MessageSendResult(
          success: false,
          errorMessage: 'Erro na API: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return MessageSendResult(
        success: false,
        errorMessage: 'Erro ao enviar WhatsApp: ${e.toString()}',
      );
    }
  }

  /// Envia mensagem com botões interativos
  Future<MessageSendResult> sendButtons(
    String phoneNumber,
    String text,
    List buttons,
  ) async {
    final isProduction = EnvConfig.getBoolOrDefault('PRODUCTION', false);

    if (!isProduction || _apiUrl == null || _apiKey == null || _instanceName == null) {
      AppLogger.info('💬 [DEV] WhatsApp com botões seria enviado:');
      AppLogger.info('   Para: $phoneNumber');
      AppLogger.info('   Conteúdo: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
      AppLogger.info('   Botões: $buttons');

      return MessageSendResult(
        success: true,
        metadata: {'sent_via': 'dev_log', 'recipient_phone': phoneNumber},
      );
    }

    try {
      final url = '$_apiUrl/message/sendButtons/$_instanceName';
      
      // Converte botões para formato Evolution API
      final buttonsData = buttons.map((btn) {
        if (btn is Map) {
          return {
            'buttonId': btn['id'] ?? btn['buttonId'],
            'buttonText': btn['text'] ?? btn['buttonText'],
            'type': btn['type'] ?? 1, // 1 = resposta rápida
          };
        }
        return btn;
      }).toList();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _apiKey ?? '',
        },
        body: jsonEncode({
          'number': phoneNumber,
          'text': text,
          'buttons': buttonsData,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return MessageSendResult(
          success: true,
          messageId: responseData['key']?['id'] as String?,
          metadata: {
            'sent_via': 'evolution_api',
            'recipient_phone': phoneNumber,
            'response': responseData,
          },
        );
      } else {
        return MessageSendResult(
          success: false,
          errorMessage: 'Erro na API: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return MessageSendResult(
        success: false,
        errorMessage: 'Erro ao enviar WhatsApp com botões: ${e.toString()}',
      );
    }
  }

  /// Envia mensagem com lista interativa
  Future<MessageSendResult> sendList(
    String phoneNumber,
    String title,
    String description,
    List listItems,
  ) async {
    final isProduction = EnvConfig.getBoolOrDefault('PRODUCTION', false);

    if (!isProduction || _apiUrl == null || _apiKey == null || _instanceName == null) {
      AppLogger.info('💬 [DEV] WhatsApp com lista seria enviado:');
      AppLogger.info('   Para: $phoneNumber');
      AppLogger.info('   Título: $title');
      AppLogger.info('   Descrição: $description');

      return MessageSendResult(
        success: true,
        metadata: {'sent_via': 'dev_log', 'recipient_phone': phoneNumber},
      );
    }

    try {
      final url = '$_apiUrl/message/sendList/$_instanceName';
      
      // Converte itens da lista para formato Evolution API
      final sections = [
        {
          'title': title,
          'rows': listItems.map((item) {
            if (item is Map) {
              return {
                'id': item['id'] ?? item['rowId'],
                'title': item['title'] ?? item['text'],
                'description': item['description'],
              };
            }
            return item;
          }).toList(),
        }
      ];

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _apiKey ?? '',
        },
        body: jsonEncode({
          'number': phoneNumber,
          'text': description,
          'title': title,
          'buttonText': 'Ver opções',
          'sections': sections,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return MessageSendResult(
          success: true,
          messageId: responseData['key']?['id'] as String?,
          metadata: {
            'sent_via': 'evolution_api',
            'recipient_phone': phoneNumber,
            'response': responseData,
          },
        );
      } else {
        return MessageSendResult(
          success: false,
          errorMessage: 'Erro na API: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return MessageSendResult(
        success: false,
        errorMessage: 'Erro ao enviar WhatsApp com lista: ${e.toString()}',
      );
    }
  }

  /// Normaliza número de telefone para formato internacional
  String _normalizePhoneNumber(String phone) {
    // Remove caracteres não numéricos
    var normalized = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Se não começa com código do país, assume Brasil (55)
    if (!normalized.startsWith('55') && normalized.length <= 11) {
      normalized = '55$normalized';
    }

    // Adiciona @s.whatsapp.net se necessário (formato Evolution API)
    if (!normalized.contains('@')) {
      return '$normalized@s.whatsapp.net';
    }

    return normalized;
  }
}
