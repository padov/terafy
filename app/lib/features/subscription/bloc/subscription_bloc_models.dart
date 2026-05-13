import 'package:equatable/equatable.dart';

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

class CheckSubscriptionStatus extends SubscriptionEvent {
  const CheckSubscriptionStatus();
}

class CreateCheckoutSession extends SubscriptionEvent {
  final int planId;
  const CreateCheckoutSession({required this.planId});

  @override
  List<Object?> get props => [planId];
}

// States

// State
enum SubscriptionStatusEnum { initial, loading, loaded, error, purchasing, purchased, restoring, checkoutRedirect }

class SubscriptionState extends Equatable {
  final SubscriptionStatusEnum status;
  final SubscriptionStatus? subscriptionStatus;
  final List<SubscriptionPlan>? plans;
  final String? errorMessage;
  final String? purchasingPlanId;
  final String? checkoutUrl;

  const SubscriptionState({
    this.status = SubscriptionStatusEnum.initial,
    this.subscriptionStatus,
    this.plans,
    this.errorMessage,
    this.purchasingPlanId,
    this.checkoutUrl,
  });

  List<SubscriptionPlan> get visiblePlans {
    if (plans == null) return [];

    final currentPlanName = subscriptionStatus?.plan.name.toLowerCase() ?? '';
    final hasActive = subscriptionStatus?.hasActiveSubscription ?? false;

    return plans!.where((plan) {
      final isFreePlan = plan.name.toLowerCase() == 'free';
      if (isFreePlan) {
        return currentPlanName == 'free' || !hasActive;
      }
      return plan.stripePriceId != null && plan.stripePriceId!.isNotEmpty;
    }).toList();
  }

  SubscriptionState copyWith({
    SubscriptionStatusEnum? status,
    SubscriptionStatus? subscriptionStatus,
    List<SubscriptionPlan>? plans,
    String? errorMessage,
    String? purchasingPlanId,
    String? checkoutUrl,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      plans: plans ?? this.plans,
      errorMessage: errorMessage, // Error message is transient, so we don't keep old one by default unless specified
      purchasingPlanId: purchasingPlanId ?? this.purchasingPlanId,
      checkoutUrl: checkoutUrl, // Checkout Url is transient too
    );
  }

  @override
  List<Object?> get props => [status, subscriptionStatus, plans, errorMessage, purchasingPlanId, checkoutUrl];
}
