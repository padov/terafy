import 'package:terafy/core/subscription/subscription_models.dart';

abstract class SubscriptionRepository {
  /// Busca o status atual da assinatura
  Future<SubscriptionStatus> getSubscriptionStatus();

  /// Lista todos os planos disponíveis
  Future<List<SubscriptionPlan>> getAvailablePlans();

  /// Verifica e sincroniza assinatura do Play Store
  Future<SubscriptionStatus> verifyPlayStoreSubscription({
    required String purchaseToken,
    required String orderId,
    required String productId,
    required bool autoRenewing,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Retorna informações de uso (contagem de pacientes)
  Future<SubscriptionUsage> getUsageInfo();
}
