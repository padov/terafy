import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:terafy/core/subscription/subscription_models.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptionStatus extends SubscriptionEvent {
  const LoadSubscriptionStatus();
}

class LoadAvailablePlans extends SubscriptionEvent {
  const LoadAvailablePlans();
}

class PurchasePlan extends SubscriptionEvent {
  final String planId;
  final ProductDetails productDetails;

  const PurchasePlan({required this.planId, required this.productDetails});

  @override
  List<Object?> get props => [planId, productDetails];
}

class RestorePurchases extends SubscriptionEvent {
  const RestorePurchases();
}

class HandlePurchaseUpdate extends SubscriptionEvent {
  final List<PurchaseDetails> purchases;

  const HandlePurchaseUpdate(this.purchases);

  @override
  List<Object?> get props => [purchases];
}

class CheckSubscriptionStatus extends SubscriptionEvent {
  const CheckSubscriptionStatus();
}

// States

// State
enum SubscriptionStatusEnum { initial, loading, loaded, error, purchasing, purchased, restoring }

class SubscriptionState extends Equatable {
  final SubscriptionStatusEnum status;
  final SubscriptionStatus? subscriptionStatus;
  final List<SubscriptionPlan>? plans;
  final List<ProductDetails>? productDetails;
  final List<({SubscriptionPlan plan, ProductDetails productDetail})>? plansWithProducts;
  final String? errorMessage;
  final String? purchasingPlanId;

  const SubscriptionState({
    this.status = SubscriptionStatusEnum.initial,
    this.subscriptionStatus,
    this.plans,
    this.productDetails,
    this.plansWithProducts,
    this.errorMessage,
    this.purchasingPlanId,
  });

  SubscriptionState copyWith({
    SubscriptionStatusEnum? status,
    SubscriptionStatus? subscriptionStatus,
    List<SubscriptionPlan>? plans,
    List<ProductDetails>? productDetails,
    List<({SubscriptionPlan plan, ProductDetails productDetail})>? plansWithProducts,
    String? errorMessage,
    String? purchasingPlanId,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      plans: plans ?? this.plans,
      productDetails: productDetails ?? this.productDetails,
      plansWithProducts: plansWithProducts ?? this.plansWithProducts,
      errorMessage: errorMessage, // Error message is transient, so we don't keep old one by default unless specified
      purchasingPlanId: purchasingPlanId ?? this.purchasingPlanId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    subscriptionStatus,
    plans,
    productDetails,
    plansWithProducts,
    errorMessage,
    purchasingPlanId,
  ];
}
