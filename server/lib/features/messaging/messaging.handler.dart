import 'dart:convert';

import 'package:common/common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_channel.dart';
import 'package:server/features/messaging/messaging.controller.dart';
import 'package:server/features/messaging/messaging.routes.dart';

class MessagingHandler extends BaseHandler {
  final MessagingController _controller;

  MessagingHandler(this._controller);

  @override
  Router get router => configureMessagingRoutes(this);

  Future<Response> handleSend(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      // Cria mensagem a partir dos dados
      final message = _messageFromRequestMap(data, senderId: userId);

      final result = await _controller.sendMessage(message);

      return successResponse(_messageToJson(result));
    } on MessagingException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao enviar mensagem: ${e.toString()}');
    }
  }

  Future<Response> handleSendReminder(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      // Valida campos obrigatórios
      final appointmentId = _readInt(data, ['appointmentId', 'appointment_id']);
      final patientId = _readInt(data, ['patientId', 'patient_id']);
      final patientName = _readString(data, ['patientName', 'patient_name']);
      final therapistId = _readInt(data, ['therapistId', 'therapist_id']);
      final therapistName = _readString(data, ['therapistName', 'therapist_name']);
      final appointmentDateTimeStr = _readString(data, ['appointmentDateTime', 'appointment_date_time']);
      final channelStr = _readString(data, ['channel']);

      if (appointmentId == null ||
          patientId == null ||
          patientName == null ||
          therapistId == null ||
          therapistName == null ||
          appointmentDateTimeStr == null ||
          channelStr == null) {
        return badRequestResponse('Campos obrigatórios faltando');
      }

      final appointmentDateTime = DateTime.parse(appointmentDateTimeStr);
      final channel = MessageChannel.values.firstWhere(
        (e) => e.name == channelStr,
        orElse: () => MessageChannel.email,
      );

      final durationMinutes = _readInt(data, ['durationMinutes', 'duration_minutes']) ?? 50;
      final appointmentDuration = Duration(minutes: durationMinutes);

      final result = await _controller.sendAppointmentReminder(
        appointmentId: appointmentId,
        patientId: patientId,
        patientName: patientName,
        patientEmail: _readString(data, ['patientEmail', 'patient_email']),
        patientPhone: _readString(data, ['patientPhone', 'patient_phone']),
        therapistId: therapistId,
        therapistName: therapistName,
        appointmentDateTime: appointmentDateTime,
        appointmentDuration: appointmentDuration,
        channel: channel,
        location: _readString(data, ['location']),
        onlineLink: _readString(data, ['onlineLink', 'online_link']),
      );

      return successResponse(_messageToJson(result));
    } on MessagingException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao enviar lembrete: ${e.toString()}');
    }
  }

  Future<Response> handleHistory(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final recipientTypeStr = request.url.queryParameters['recipientType'] ?? 'patient';
      final recipientIdStr = request.url.queryParameters['recipientId'];
      final statusStr = request.url.queryParameters['status'];
      final channelStr = request.url.queryParameters['channel'];
      final limitStr = request.url.queryParameters['limit'];
      final offsetStr = request.url.queryParameters['offset'];

      if (recipientIdStr == null) {
        return badRequestResponse('recipientId é obrigatório');
      }

      final recipientId = int.tryParse(recipientIdStr);
      if (recipientId == null) {
        return badRequestResponse('recipientId inválido');
      }

      final recipientType = RecipientType.values.firstWhere(
        (e) => e.name == recipientTypeStr,
        orElse: () => RecipientType.patient,
      );

      MessageStatus? status;
      if (statusStr != null) {
        status = MessageStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => MessageStatus.pending,
        );
      }

      MessageChannel? channel;
      if (channelStr != null) {
        channel = MessageChannel.values.firstWhere(
          (e) => e.name == channelStr,
        );
      }

      final limit = limitStr != null ? int.tryParse(limitStr) : null;
      final offset = offsetStr != null ? int.tryParse(offsetStr) : null;

      final messages = await _controller.getMessageHistory(
        recipientType: recipientType,
        recipientId: recipientId,
        status: status,
        channel: channel,
        limit: limit,
        offset: offset,
      );

      return successResponse(messages.map((m) => _messageToJson(m)).toList());
    } on MessagingException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao buscar histórico: ${e.toString()}');
    }
  }

  Future<Response> handleProcessReminders(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      // Apenas admin pode processar lembretes manualmente
      if (userRole != 'admin') {
        return forbiddenResponse('Apenas administradores podem processar lembretes');
      }

      final count = await _controller.processReminders();

      return successResponse({
        'message': 'Lembretes processados com sucesso',
        'processed': count,
      });
    } on MessagingException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao processar lembretes: ${e.toString()}');
    }
  }

  Message _messageFromRequestMap(Map<String, dynamic> data, {required int senderId}) {
    final messageTypeStr = _readString(data, ['messageType', 'message_type']) ?? 'general';
    final channelStr = _readString(data, ['channel']) ?? 'email';
    final recipientTypeStr = _readString(data, ['recipientType', 'recipient_type']) ?? 'patient';
    final recipientId = _readInt(data, ['recipientId', 'recipient_id']);
    final subject = _readString(data, ['subject']) ?? '';
    final content = _readString(data, ['content']) ?? '';

    if (recipientId == null) {
      throw MessagingException('recipientId é obrigatório', 400);
    }

    return Message(
      messageType: MessageType.values.firstWhere(
        (e) => e.name == messageTypeStr,
        orElse: () => MessageType.general,
      ),
      channel: MessageChannel.values.firstWhere(
        (e) => e.name == channelStr,
        orElse: () => MessageChannel.email,
      ),
      recipientType: RecipientType.values.firstWhere(
        (e) => e.name == recipientTypeStr,
        orElse: () => RecipientType.patient,
      ),
      recipientId: recipientId,
      senderId: senderId,
      subject: subject,
      content: content,
      templateId: _readInt(data, ['templateId', 'template_id']),
      metadata: data['metadata'] as Map<String, dynamic>?,
      relatedEntityType: _readString(data, ['relatedEntityType', 'related_entity_type']),
      relatedEntityId: _readInt(data, ['relatedEntityId', 'related_entity_id']),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'messageType': message.messageType.name,
      'channel': message.channel.name,
      'recipientType': message.recipientType.name,
      'recipientId': message.recipientId,
      'senderId': message.senderId,
      'subject': message.subject,
      'content': message.content,
      'templateId': message.templateId,
      'status': message.status.name,
      'priority': message.priority.name,
      'scheduledAt': message.scheduledAt?.toIso8601String(),
      'sentAt': message.sentAt?.toIso8601String(),
      'deliveredAt': message.deliveredAt?.toIso8601String(),
      'readAt': message.readAt?.toIso8601String(),
      'errorMessage': message.errorMessage,
      'metadata': message.metadata,
      'relatedEntityType': message.relatedEntityType,
      'relatedEntityId': message.relatedEntityId,
      'createdAt': message.createdAt.toIso8601String(),
      'updatedAt': message.updatedAt.toIso8601String(),
    };
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value == null) return null;
        return value.toString();
      }
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) {
          return int.tryParse(value);
        }
        if (value is num) {
          return value.toInt();
        }
      }
    }
    return null;
  }
}

