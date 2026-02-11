import 'dart:async';
import 'package:common/common.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:terafy/core/domain/repositories/subscription_repository.dart';
import 'package:terafy/core/subscription/subscription_models.dart';
import 'package:terafy/core/subscription/subscription_service.dart';
import 'subscription_bloc_models.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository _repository;
  final SubscriptionService _subscriptionService;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  SubscriptionBloc({required SubscriptionRepository repository, required SubscriptionService subscriptionService})
    : _repository = repository,
      _subscriptionService = subscriptionService,
      super(const SubscriptionState(status: SubscriptionStatusEnum.initial)) {
    on<LoadSubscriptionStatus>(_onLoadSubscriptionStatus);
    on<LoadAvailablePlans>(_onLoadAvailablePlans);
    on<PurchasePlan>(_onPurchasePlan);
    on<RestorePurchases>(_onRestorePurchases);
    on<HandlePurchaseUpdate>(_onHandlePurchaseUpdate);
    on<CheckSubscriptionStatus>(_onCheckSubscriptionStatus);

    // Escuta atualizações de compras
    _purchaseSubscription = _subscriptionService.purchaseUpdated.listen((purchases) {
      add(HandlePurchaseUpdate(purchases));
    });
  }

  Future<void> _onLoadSubscriptionStatus(LoadSubscriptionStatus event, Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(status: SubscriptionStatusEnum.loading));
    try {
      final status = await _repository.getSubscriptionStatus();
      emit(state.copyWith(status: SubscriptionStatusEnum.loaded, subscriptionStatus: status));
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao carregar status: $e', stackTrace);
      emit(state.copyWith(status: SubscriptionStatusEnum.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadAvailablePlans(LoadAvailablePlans event, Emitter<SubscriptionState> emit) async {
    try {
      final plans = await _repository.getAvailablePlans();

      // Tenta buscar produtos do Play Store, mas não falha se não conseguir
      List<ProductDetails>? productDetails;
      List<({SubscriptionPlan plan, ProductDetails productDetail})>? plansWithProducts;

      try {
        // Verifica disponibilidade do In-App Purchase
        final isAvailable = await _subscriptionService.checkAvailability();

        if (isAvailable) {
          // Busca produtos do Play Store
          final productIds = plans.where((p) => p.playStoreProductId != null).map((p) => p.playStoreProductId!).toSet();

          if (productIds.isNotEmpty) {
            try {
              productDetails = await _subscriptionService.getAvailableProducts(productIds: productIds);

              // Mapeia produtos do Play Store para planos
              final mappedProducts = <({SubscriptionPlan plan, ProductDetails productDetail})>[];
              for (final plan in plans) {
                if (plan.playStoreProductId == null) continue;
                try {
                  final productDetail = productDetails.firstWhere((pd) => pd.id == plan.playStoreProductId);
                  mappedProducts.add((plan: plan, productDetail: productDetail));
                } catch (e) {
                  // Produto não encontrado no Play Store, ignora
                }
              }
              if (mappedProducts.isNotEmpty) {
                plansWithProducts = mappedProducts;
              }
            } catch (e) {
              // Erro ao buscar produtos do Play Store, mas continua sem eles
              AppLogger.warning('Erro ao buscar produtos do Play Store (continuando sem produtos): $e');
            }
          }
        }
      } catch (e) {
        // Erro ao verificar disponibilidade, mas continua sem produtos
        AppLogger.warning('Erro ao verificar disponibilidade do In-App Purchase (continuando sem produtos): $e');
      }

      // Emite os planos mesmo sem produtos do Play Store, preservando o status atual
      emit(state.copyWith(plans: plans, productDetails: productDetails, plansWithProducts: plansWithProducts));
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao carregar planos: $e', stackTrace);
      emit(state.copyWith(status: SubscriptionStatusEnum.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onPurchasePlan(PurchasePlan event, Emitter<SubscriptionState> emit) async {
    try {
      emit(state.copyWith(status: SubscriptionStatusEnum.purchasing, purchasingPlanId: event.planId));

      final result = await _subscriptionService.purchaseSubscription(productDetails: event.productDetails);

      if (!result.success) {
        emit(
          state.copyWith(
            status: SubscriptionStatusEnum.error,
            errorMessage: result.errorMessage ?? 'Erro ao realizar compra',
            purchasingPlanId: null, // Limpa o ID de compra em caso de erro imediato
          ),
        );
      }
      // A compra será processada no stream de purchaseUpdated
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao comprar plano: $e', stackTrace);
      emit(state.copyWith(status: SubscriptionStatusEnum.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onRestorePurchases(RestorePurchases event, Emitter<SubscriptionState> emit) async {
    try {
      emit(state.copyWith(status: SubscriptionStatusEnum.restoring));
      final success = await _subscriptionService.restorePurchases();

      if (success) {
        // Recarrega status após restaurar
        add(const LoadSubscriptionStatus());
      } else {
        emit(state.copyWith(status: SubscriptionStatusEnum.error, errorMessage: 'Erro ao restaurar compras'));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao restaurar compras: $e', stackTrace);
      emit(state.copyWith(status: SubscriptionStatusEnum.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onHandlePurchaseUpdate(HandlePurchaseUpdate event, Emitter<SubscriptionState> emit) async {
    for (final purchase in event.purchases) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        try {
          final purchaseInfo = _subscriptionService.extractPurchaseInfo(purchase);

          if (purchaseInfo != null) {
            // Verifica assinatura no backend
            final status = await _repository.verifyPlayStoreSubscription(
              purchaseToken: purchaseInfo['purchase_token'] as String,
              orderId: purchaseInfo['order_id'] as String,
              productId: purchaseInfo['product_id'] as String,
              autoRenewing: purchaseInfo['auto_renewing'] as bool,
            );

            emit(
              state.copyWith(
                status: SubscriptionStatusEnum.purchased,
                subscriptionStatus: status,
                purchasingPlanId: null,
              ),
            );

            // Recarrega status
            add(const LoadSubscriptionStatus());
          }
        } catch (e, stackTrace) {
          AppLogger.error('Erro ao processar compra: $e', stackTrace);
          emit(
            state.copyWith(
              status: SubscriptionStatusEnum.error,
              errorMessage: 'Erro ao processar compra: ${e.toString()}',
            ),
          );
        }
      } else if (purchase.status == PurchaseStatus.error) {
        emit(
          state.copyWith(
            status: SubscriptionStatusEnum.error,
            errorMessage: purchase.error?.message ?? 'Erro na compra',
            purchasingPlanId: null,
          ),
        );
      }
    }
  }

  Future<void> _onCheckSubscriptionStatus(CheckSubscriptionStatus event, Emitter<SubscriptionState> emit) async {
    try {
      final status = await _repository.getSubscriptionStatus();
      emit(state.copyWith(status: SubscriptionStatusEnum.loaded, subscriptionStatus: status));
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao verificar status: $e', stackTrace);
      // Não emite erro para não interromper o fluxo
    }
  }

  @override
  Future<void> close() {
    _purchaseSubscription?.cancel();
    return super.close();
  }
}
