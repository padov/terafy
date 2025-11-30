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
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

class SubscriptionLoaded extends SubscriptionState {
  final SubscriptionStatus status;

  const SubscriptionLoaded({required this.status});

  @override
  List<Object?> get props => [status];
}

class PlansLoaded extends SubscriptionState {
  final List<SubscriptionPlan> plans;
  final List<ProductDetails>? productDetails;
  final List<({SubscriptionPlan plan, ProductDetails productDetail})>? plansWithProducts;

  const PlansLoaded({required this.plans, this.productDetails, this.plansWithProducts});

  @override
  List<Object?> get props => [plans, productDetails, plansWithProducts];
}

class SubscriptionPurchasing extends SubscriptionState {
  final String planId;

  const SubscriptionPurchasing({required this.planId});

  @override
  List<Object?> get props => [planId];
}

class SubscriptionPurchased extends SubscriptionState {
  final SubscriptionStatus status;

  const SubscriptionPurchased({required this.status});

  @override
  List<Object?> get props => [status];
}

class SubscriptionRestoring extends SubscriptionState {
  const SubscriptionRestoring();
}

class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError({required this.message});

  @override
  List<Object?> get props => [message];
}
