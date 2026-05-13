import 'dart:convert';
import 'package:common/common.dart';
import 'package:server/features/subscription/subscription.repository.dart';
import 'package:server/features/therapist/therapist.repository.dart';
import 'package:server/core/services/stripe_service.dart';

class SubscriptionException implements Exception {
  final String message;
  final int statusCode;

  SubscriptionException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class SubscriptionController {
  final SubscriptionRepository _repository;
  final TherapistRepository _therapistRepository;
  final StripeService _stripeService;

  SubscriptionController(this._repository, this._therapistRepository, this._stripeService);

  /// Retorna o status da assinatura atual do terapeuta
  Future<Map<String, dynamic>> getSubscriptionStatus(int userId) async {
    try {
      // Busca o terapeuta pelo user_id
      final therapistData = await _therapistRepository.getTherapistByUserIdWithPlan(userId);
      if (therapistData == null) {
        throw SubscriptionException('Terapeuta não encontrado', 404);
      }

      final therapistId = therapistData['id'] as int;
      final subscription = await _repository.getActiveSubscription(therapistId);
      final patientCount = await _repository.countActivePatients(therapistId);

      Map<String, dynamic> planData;
      if (subscription != null) {
        planData = subscription['plan'] as Map<String, dynamic>;
      } else {
        final defaultPlan = await _repository.getDefaultPlan();
        planData = defaultPlan['plan'] as Map<String, dynamic>;
      }

      final patientLimit = planData['patient_limit'] as int? ?? 10;
      final canCreate = patientCount < patientLimit;

      final anamnesisLimit = planData['custom_anamnesis_limit'] as int? ?? 0;
      final anamnesisCount = await _repository.countCustomAnamnesis(therapistId);
      final canCreateAnamnesis = anamnesisCount < anamnesisLimit;

      return {
        'subscription': subscription?['subscription'],
        'plan': planData,
        'usage': {
          'patient_count': patientCount,
          'patient_limit': patientLimit,
          'can_create_patient': canCreate,
          'usage_percentage': patientLimit > 0 ? (patientCount / patientLimit * 100).round() : 0,
          'custom_anamnesis_count': anamnesisCount,
          'custom_anamnesis_limit': anamnesisLimit,
          'can_create_anamnesis': canCreateAnamnesis,
        },
      };
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      AppLogger.error(e, StackTrace.current);
      throw SubscriptionException('Erro ao buscar status da assinatura: ${e.toString()}', 500);
    }
  }

  /// Lista todos os planos disponíveis
  Future<List<Map<String, dynamic>>> getAvailablePlans() async {
    try {
      return await _repository.getAvailablePlans();
    } catch (e) {
      AppLogger.error(e, StackTrace.current);
      throw SubscriptionException('Erro ao listar planos: ${e.toString()}', 500);
    }
  }

  /// Verifica e sincroniza assinatura do Play Store
  Future<Map<String, dynamic>> verifyPlayStoreSubscription({
    required int userId,
    required String purchaseToken,
    required String orderId,
    required String productId,
    required bool autoRenewing,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Busca o terapeuta pelo user_id
      final therapistData = await _therapistRepository.getTherapistByUserIdWithPlan(userId);
      if (therapistData == null) {
        throw SubscriptionException('Terapeuta não encontrado', 404);
      }

      final therapistId = therapistData['id'] as int;

      // Busca o plano pelo product_id
      final plan = await _repository.getPlanByProductId(productId);
      if (plan == null) {
        throw SubscriptionException('Plano não encontrado para product_id: $productId', 404);
      }

      final planId = plan['id'] as int;

      // Verifica se já existe assinatura com este order_id
      final existingSubscription = await _repository.getSubscriptionByOrderId(orderId);
      if (existingSubscription != null) {
        // Retorna a assinatura existente
        return await getSubscriptionStatus(userId);
      }

      // Sincroniza a assinatura
      await _repository.syncPlayStoreSubscription(
        therapistId: therapistId,
        planId: planId,
        purchaseToken: purchaseToken,
        orderId: orderId,
        autoRenewing: autoRenewing,
        startDate: startDate,
        endDate: endDate,
      );

      AppLogger.info('Assinatura do Play Store sincronizada: order_id=$orderId, therapist_id=$therapistId');

      // Retorna o status atualizado
      return await getSubscriptionStatus(userId);
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      AppLogger.error(e, StackTrace.current);
      throw SubscriptionException('Erro ao verificar assinatura: ${e.toString()}', 500);
    }
  }

  /// Verifica se o terapeuta pode criar um novo paciente
  Future<bool> canCreatePatient(int userId) async {
    try {
      final therapistData = await _therapistRepository.getTherapistByUserIdWithPlan(userId);
      if (therapistData == null) {
        throw SubscriptionException('Terapeuta não encontrado', 404);
      }

      final therapistId = therapistData['id'] as int;
      return await _repository.canCreatePatient(therapistId);
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      AppLogger.error(e, StackTrace.current);
      throw SubscriptionException('Erro ao verificar limite: ${e.toString()}', 500);
    }
  }

  /// Retorna informações de uso (contagem de pacientes)
  Future<Map<String, dynamic>> getUsageInfo(int userId) async {
    try {
      final therapistData = await _therapistRepository.getTherapistByUserIdWithPlan(userId);
      if (therapistData == null) {
        throw SubscriptionException('Terapeuta não encontrado', 404);
      }

      final therapistId = therapistData['id'] as int;
      final subscription = await _repository.getActiveSubscription(therapistId);
      final patientCount = await _repository.countActivePatients(therapistId);

      Map<String, dynamic> planData;
      if (subscription != null) {
        planData = subscription['plan'] as Map<String, dynamic>;
      } else {
        final defaultPlan = await _repository.getDefaultPlan();
        planData = defaultPlan['plan'] as Map<String, dynamic>;
      }

      final patientLimit = planData['patient_limit'] as int? ?? 10;

      final anamnesisLimit = planData['custom_anamnesis_limit'] as int? ?? 0;
      final anamnesisCount = await _repository.countCustomAnamnesis(therapistId);
      final canCreateAnamnesis = anamnesisCount < anamnesisLimit;

      return {
        'patient_count': patientCount,
        'patient_limit': patientLimit,
        'can_create_patient': patientCount < patientLimit,
        'usage_percentage': patientLimit > 0 ? (patientCount / patientLimit * 100).round() : 0,
        'custom_anamnesis_count': anamnesisCount,
        'custom_anamnesis_limit': anamnesisLimit,
        'can_create_anamnesis': canCreateAnamnesis,
      };
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      AppLogger.error(e, StackTrace.current);
      throw SubscriptionException('Erro ao buscar informações de uso: ${e.toString()}', 500);
    }
  }

  /// Gera link do Stripe Checkout
  Future<String> createCheckoutSession({
    required int userId,
    required int planId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final therapistData = await _therapistRepository.getTherapistByUserIdWithPlan(userId);
      if (therapistData == null) {
        throw SubscriptionException('Terapeuta não encontrado', 404);
      }

      final planData = await _repository.getPlanById(planId);
      if (planData == null) {
        throw SubscriptionException('Plano não encontrado', 404);
      }

      final stripePriceId = planData['stripe_price_id'] as String?;
      if (stripePriceId == null || stripePriceId.isEmpty) {
        throw SubscriptionException('Plano não possui configuração da Stripe', 400);
      }

      final email = therapistData['email'] as String? ?? '';

      final url = await _stripeService.createCheckoutSession(
        customerEmail: email,
        therapistId: therapistData['id'].toString(),
        priceId: stripePriceId,
        planId: planId.toString(),
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      return url;
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      AppLogger.error(e, StackTrace.current);
      throw SubscriptionException('Erro ao criar checkout: ${e.toString()}', 500);
    }
  }

  /// Processa Webhook da Stripe
  Future<void> handleStripeWebhook(String payload, String signature) async {
    try {
      if (!_stripeService.verifyWebhookSignature(signature, payload)) {
        throw SubscriptionException('Assinatura do webhook inválida', 400);
      }

      final event = jsonDecode(payload);
      final type = event['type'];
      final data = event['data']['object'];

      AppLogger.info('Stripe Webhook recebido: $type');

      if (type == 'checkout.session.completed') {
        final therapistIdStr = data['client_reference_id'] as String?;
        if (therapistIdStr != null) {
          final therapistId = int.tryParse(therapistIdStr);
          if (therapistId != null) {
            final planIdStr = data['metadata']?['plan_id'] ?? data['subscription_details']?['metadata']?['plan_id'];
            int? planId;
            if (planIdStr != null) {
              planId = int.tryParse(planIdStr.toString());
            }

            AppLogger.info('Checkout complete para therapist_id: $therapistId, plan_id: $planId');

            await _repository.syncStripeSubscription(
              therapistId: therapistId,
              planId: planId, // Novo param opcional se existir no webhook
              stripeCustomerId: data['customer']?.toString() ?? '',
              stripeSubscriptionId: data['subscription']?.toString() ?? '',
              status: data['payment_status'] == 'paid' ? 'active' : 'pending',
            );
          }
        }
      } else if (type == 'customer.subscription.deleted') {
        final stripeSubId = data['id'];
        await _repository.cancelStripeSubscription(stripeSubId);
      } else if (type == 'customer.subscription.updated') {
        final stripeSubId = data['id'];
        final status = data['status'];

        final currentPeriodEndTimestamp = data['current_period_end'];
        DateTime? currentPeriodEnd;
        if (currentPeriodEndTimestamp != null) {
          final seconds = currentPeriodEndTimestamp is int
              ? currentPeriodEndTimestamp
              : int.tryParse(currentPeriodEndTimestamp.toString());
          if (seconds != null) {
            currentPeriodEnd = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        }

        await _repository.updateStripeSubscriptionStatus(stripeSubId, status, currentPeriodEnd: currentPeriodEnd);
      }
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      AppLogger.error('Erro processando webhook: $e', StackTrace.current);
      throw SubscriptionException('Erro interno do servidor', 500);
    }
  }
}
