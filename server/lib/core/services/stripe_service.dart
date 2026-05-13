import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:server/core/config/env_config.dart';
import 'package:common/common.dart';

class StripeException implements Exception {
  final String message;
  final int statusCode;

  StripeException(this.message, [this.statusCode = 500]);

  @override
  String toString() => message;
}

class StripeService {
  final String _secretKey;
  final String _webhookSecret;
  final String _baseUrl = 'https://api.stripe.com/v1';

  StripeService()
    : _secretKey = EnvConfig.get('STRIPE_SECRET_KEY') ?? '',
      _webhookSecret = EnvConfig.get('STRIPE_WEBHOOK_SECRET') ?? '' {
    if (_secretKey.isEmpty) {
      AppLogger.warning('STRIPE_SECRET_KEY não está configurada no .env');
    }
    if (_webhookSecret.isEmpty) {
      AppLogger.warning('STRIPE_WEBHOOK_SECRET não está configurada no .env');
    }
  }

  /// Criar uma Checkout Session na Stripe
  Future<String> createCheckoutSession({
    required String customerEmail,
    required String therapistId,
    required String priceId,
    required String planId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/checkout/sessions'),
        headers: {'Authorization': 'Bearer $_secretKey', 'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'payment_method_types[0]': 'card',
          'line_items[0][price]': priceId,
          'line_items[0][quantity]': '1',
          'mode': 'subscription',
          'success_url': successUrl,
          'cancel_url': cancelUrl,
          'customer_email': customerEmail,
          'client_reference_id': therapistId, // Para cruzar os dados depois no webhook
          'metadata[plan_id]': planId,
          'subscription_data[metadata][plan_id]': planId,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data['url'] as String;
      } else {
        AppLogger.error('Erro na Stripe: $data');
        var errorMsg = data['error']?['message'] ?? 'Erro desconhecido na Stripe';
        throw StripeException(errorMsg, response.statusCode);
      }
    } catch (e) {
      if (e is StripeException) rethrow;
      throw StripeException('Erro ao criar sessão de checkout: $e');
    }
  }

  /// Verificar a assinatura do webhook da Stripe
  bool verifyWebhookSignature(String signatureHeader, String payload) {
    if (_webhookSecret.isEmpty) {
      AppLogger.error('STRIPE_WEBHOOK_SECRET não configurada!');
      return false;
    }

    try {
      // Stripe-Signature header formato:
      // t=1614299554,v1=5257a8...c8d,v0=6ffbb...

      final pairs = signatureHeader.split(',');
      String? timestamp;
      String? actualSignature;

      for (var pair in pairs) {
        final parts = pair.split('=');
        if (parts.length == 2) {
          if (parts[0] == 't') timestamp = parts[1];
          if (parts[0] == 'v1') actualSignature = parts[1];
        }
      }

      if (timestamp == null || actualSignature == null) {
        AppLogger.warning('Cabeçalho Stripe-Signature inválido');
        return false;
      }

      // Evita ataques de replay conferindo se o timestamp é muito antigo
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final ts = int.tryParse(timestamp) ?? 0;
      if (now - ts > 300) {
        AppLogger.warning('Stripe webhook com timestamp muito velho: $ts');
        return false;
      }

      // Concatena timestamp com o payload original e gera a assinatura HMAC SHA256
      final signedPayload = '$timestamp.$payload';

      final hmac = Hmac(sha256, utf8.encode(_webhookSecret));
      final digest = hmac.convert(utf8.encode(signedPayload));
      var expectedSignature = digest.toString();

      return expectedSignature == actualSignature;
    } catch (e) {
      AppLogger.error('Erro validando assinatura do webhook Stripe: $e');
      return false;
    }
  }

  /// Cancelar uma Subscription na Stripe
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
        headers: {'Authorization': 'Bearer $_secretKey'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      } else {
        AppLogger.error('Erro na Stripe ao cancelar $subscriptionId: $data');
        var errorMsg = data['error']?['message'] ?? 'Erro desconhecido na Stripe';
        throw StripeException(errorMsg, response.statusCode);
      }
    } catch (e) {
      if (e is StripeException) rethrow;
      throw StripeException('Erro ao cancelar assinatura: $e');
    }
  }
}
