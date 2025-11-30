import 'dart:async';
import 'package:common/common.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:terafy/core/subscription/subscription_models.dart';

/// Serviço para gerenciar compras do Google Play Billing
class SubscriptionService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final StreamController<List<PurchaseDetails>> _purchaseUpdatedController =
      StreamController<List<PurchaseDetails>>.broadcast();

  Stream<List<PurchaseDetails>> get purchaseUpdated => _purchaseUpdatedController.stream;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  SubscriptionService() {
    _initialize();
  }

  void _initialize() {
    _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () => _purchaseUpdatedController.close(),
      onError: (error) {
        AppLogger.error('Erro no stream de compras: $error', StackTrace.current);
      },
    );
  }

  /// Verifica se o In-App Purchase está disponível
  Future<bool> checkAvailability() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      AppLogger.info('In-App Purchase disponível: $_isAvailable');
      return _isAvailable;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao verificar disponibilidade: $e', stackTrace);
      _isAvailable = false;
      return false;
    }
  }

  /// Busca produtos disponíveis no Play Store
  Future<List<ProductDetails>> getAvailableProducts({required Set<String> productIds}) async {
    try {
      if (!_isAvailable) {
        await checkAvailability();
      }

      if (!_isAvailable) {
        throw Exception('In-App Purchase não está disponível');
      }

      final response = await _inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        throw Exception('Erro ao buscar produtos: ${response.error!.message}');
      }

      AppLogger.info('Produtos encontrados: ${response.productDetails.length}');

      return response.productDetails;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao buscar produtos: $e', stackTrace);
      rethrow;
    }
  }

  /// Inicia a compra de uma assinatura
  Future<PurchaseResult> purchaseSubscription({required ProductDetails productDetails}) async {
    try {
      if (!_isAvailable) {
        await checkAvailability();
        if (!_isAvailable) {
          return const PurchaseResult(success: false, errorMessage: 'In-App Purchase não está disponível');
        }
      }

      final purchaseParam = PurchaseParam(productDetails: productDetails);

      final success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      if (!success) {
        return const PurchaseResult(success: false, errorMessage: 'Falha ao iniciar compra');
      }

      // A compra será processada no stream de purchaseUpdated
      return const PurchaseResult(success: true);
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao comprar assinatura: $e', stackTrace);
      return PurchaseResult(success: false, errorMessage: e.toString());
    }
  }

  /// Restaura compras anteriores
  Future<bool> restorePurchases() async {
    try {
      if (!_isAvailable) {
        await checkAvailability();
        if (!_isAvailable) {
          return false;
        }
      }

      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao restaurar compras: $e', stackTrace);
      return false;
    }
  }

  /// Processa atualizações de compras
  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      AppLogger.info('Compra atualizada: ${purchaseDetails.productID} - Status: ${purchaseDetails.status}');

      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Compra pendente - aguardar confirmação
        AppLogger.info('Compra pendente: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Compra bem-sucedida - processar
        _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Erro na compra
        AppLogger.error('Erro na compra: ${purchaseDetails.error?.message}', StackTrace.current);
      }

      // Finalizar compra se necessário
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }

    _purchaseUpdatedController.add(purchaseDetailsList);
  }

  /// Processa compra bem-sucedida
  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    AppLogger.info('Compra bem-sucedida: ${purchaseDetails.productID}');
    AppLogger.info('Purchase ID: ${purchaseDetails.purchaseID}');
    AppLogger.info('Verification Data: ${purchaseDetails.verificationData.source}');

    // A verificação com o backend será feita pelo bloc
  }

  /// Extrai informações da compra para verificação no backend
  Map<String, dynamic>? extractPurchaseInfo(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.status != PurchaseStatus.purchased && purchaseDetails.status != PurchaseStatus.restored) {
      return null;
    }

    final verificationData = purchaseDetails.verificationData;

    return {
      'purchase_token': verificationData.serverVerificationData,
      'order_id': purchaseDetails.purchaseID,
      'product_id': purchaseDetails.productID,
      'auto_renewing': purchaseDetails.status == PurchaseStatus.purchased,
    };
  }

  void dispose() {
    _purchaseUpdatedController.close();
  }
}
