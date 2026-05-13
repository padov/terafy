import 'dart:convert';

import 'package:common/common.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import 'package:server/features/subscription/subscription.controller.dart';
import 'package:server/features/subscription/subscription.routes.dart';

class SubscriptionHandler extends BaseHandler {
  final SubscriptionController _controller;

  SubscriptionHandler(this._controller);

  @override
  Router get router => configureSubscriptionRoutes(this);

  /// GET /api/subscription/status
  Future<Response> handleGetStatus(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      if (userId == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final status = await _controller.getSubscriptionStatus(userId);
      return successResponse(status);
    } on SubscriptionException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao buscar status da assinatura: ${e.toString()}');
    }
  }

  /// GET /api/subscription/plans
  Future<Response> handleGetPlans(Request request) async {
    AppLogger.func();

    try {
      final plans = await _controller.getAvailablePlans();
      return successResponse(plans);
    } on SubscriptionException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao listar planos: ${e.toString()}');
    }
  }

  /// POST /api/subscription/verify
  Future<Response> handleVerifySubscription(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      if (userId == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      final purchaseToken = data['purchase_token'] as String?;
      final orderId = data['order_id'] as String?;
      final productId = data['product_id'] as String?;
      final autoRenewing = data['auto_renewing'] as bool? ?? false;

      if (purchaseToken == null || orderId == null || productId == null) {
        return badRequestResponse('purchase_token, order_id e product_id são obrigatórios');
      }

      DateTime? startDate;
      DateTime? endDate;

      if (data['start_date'] != null) {
        startDate = DateTime.parse(data['start_date'] as String);
      }
      if (data['end_date'] != null) {
        endDate = DateTime.parse(data['end_date'] as String);
      }

      final status = await _controller.verifyPlayStoreSubscription(
        userId: userId,
        purchaseToken: purchaseToken,
        orderId: orderId,
        productId: productId,
        autoRenewing: autoRenewing,
        startDate: startDate,
        endDate: endDate,
      );

      return successResponse(status);
    } on SubscriptionException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao verificar assinatura: ${e.toString()}');
    }
  }

  /// GET /api/subscription/usage
  Future<Response> handleGetUsage(Request request) async {
    AppLogger.func();

    try {
      final userId = getUserId(request);
      if (userId == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final usage = await _controller.getUsageInfo(userId);
      return successResponse(usage);
    } on SubscriptionException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao buscar informações de uso: ${e.toString()}');
    }
  }

  /// POST /api/subscription/checkout
  Future<Response> handleCreateCheckout(Request request) async {
    AppLogger.func();
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return unauthorizedResponse('Autenticação necessária');
      }

      final body = await request.readAsString();
      if (body.trim().isEmpty) {
        return badRequestResponse('Corpo da requisição não pode ser vazio');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final planId = data['plan_id'] as int?;
      final successUrl = data['success_url'] as String?;
      final cancelUrl = data['cancel_url'] as String?;

      if (planId == null || successUrl == null || cancelUrl == null) {
        return badRequestResponse('plan_id, success_url e cancel_url são obrigatórios');
      }

      final url = await _controller.createCheckoutSession(
        userId: userId,
        planId: planId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      return successResponse({'url': url});
    } on SubscriptionException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro ao criar sessão de checkout: ${e.toString()}');
    }
  }

  /// POST /api/subscription/webhook
  Future<Response> handleStripeWebhook(Request request) async {
    AppLogger.func();
    try {
      final signature = request.headers['stripe-signature'];
      if (signature == null) {
        AppLogger.warning('Webhook sem assinatura Stripe');
        return badRequestResponse('Assinatura ausente');
      }

      // IMPORTANTE: precisamos ler o body exato como foi enviado pela Stripe
      // request.readAsString() nos dá o body decodificado em utf-8 normalmente.
      final payload = await request.readAsString();

      await _controller.handleStripeWebhook(payload, signature);

      return successResponse({'received': true});
    } on SubscriptionException catch (e) {
      return errorResponse(e.message, statusCode: e.statusCode);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      return internalServerErrorResponse('Erro no webhook: ${e.toString()}');
    }
  }
}
