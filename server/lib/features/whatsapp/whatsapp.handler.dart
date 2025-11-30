import 'dart:convert';

import 'package:common/common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/features/whatsapp/whatsapp.controller.dart';
import 'package:server/features/whatsapp/whatsapp.routes.dart';

class WhatsAppHandler extends BaseHandler {
  final WhatsAppController _controller;

  WhatsAppHandler(this._controller);

  @override
  Router get router => configureWhatsAppRoutes(this);

  /// Handler para webhook do Evolution API
  Future<Response> handleWebhook(Request request) async {
    AppLogger.func();

    try {
      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final event = jsonDecode(body) as Map<String, dynamic>;

      await _controller.processWebhook(event);

      return successResponse({'status': 'processed'});
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao processar webhook: ${e.toString()}');
    }
  }

  /// Handler para enviar confirmações
  Future<Response> handleSendConfirmations(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      final userRole = getUserRole(request);
      final accountId = getAccountId(request);

      if (userId == null || userRole == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final therapistId = _readInt(data, ['therapistId', 'therapist_id']) ?? accountId;
      final daysBefore = _readInt(data, ['daysBefore', 'days_before']) ?? 1;

      if (therapistId == null) {
        return badRequestResponse('therapistId é obrigatório');
      }

      final count = await _controller.sendConfirmations(
        therapistId: therapistId,
        daysBefore: daysBefore,
      );

      return successResponse({
        'message': 'Confirmações enviadas',
        'count': count,
      });
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao enviar confirmações: ${e.toString()}');
    }
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

