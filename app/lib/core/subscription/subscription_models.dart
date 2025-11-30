import 'package:equatable/equatable.dart';

/// Modelo de plano de assinatura
class SubscriptionPlan extends Equatable {
  final int id;
  final String name;
  final String description;
  final double price;
  final int patientLimit;
  final List<String> features;
  final String? playStoreProductId;
  final String billingPeriod; // 'monthly' ou 'annual'

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.patientLimit,
    required this.features,
    this.playStoreProductId,
    required this.billingPeriod,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    // Trata price que pode vir como num ou String (PostgreSQL DECIMAL)
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return SubscriptionPlan(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: parsePrice(json['price']),
      patientLimit: json['patient_limit'] as int? ?? 0,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      playStoreProductId: json['play_store_product_id'] as String?,
      billingPeriod: json['billing_period'] as String? ?? 'monthly',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'patient_limit': patientLimit,
      'features': features,
      'play_store_product_id': playStoreProductId,
      'billing_period': billingPeriod,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        patientLimit,
        features,
        playStoreProductId,
        billingPeriod,
      ];
}

/// Modelo de assinatura ativa
class Subscription extends Equatable {
  final int? id;
  final int therapistId;
  final int planId;
  final DateTime startDate;
  final DateTime endDate;
  final String paymentMethod;
  final bool isActive;
  final String? playStorePurchaseToken;
  final String? playStoreOrderId;
  final bool autoRenewing;
  final DateTime? createdAt;

  const Subscription({
    this.id,
    required this.therapistId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.paymentMethod,
    required this.isActive,
    this.playStorePurchaseToken,
    this.playStoreOrderId,
    required this.autoRenewing,
    this.createdAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int?,
      therapistId: json['therapist_id'] as int? ?? 0,
      planId: json['plan_id'] as int? ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : DateTime.now(),
      paymentMethod: json['payment_method'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      playStorePurchaseToken: json['play_store_purchase_token'] as String?,
      playStoreOrderId: json['play_store_order_id'] as String?,
      autoRenewing: json['auto_renewing'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  bool get isExpired => DateTime.now().isAfter(endDate);

  @override
  List<Object?> get props => [
        id,
        therapistId,
        planId,
        startDate,
        endDate,
        paymentMethod,
        isActive,
        playStorePurchaseToken,
        playStoreOrderId,
        autoRenewing,
        createdAt,
      ];
}

/// Status da assinatura com informações de uso
class SubscriptionStatus extends Equatable {
  final Subscription? subscription;
  final SubscriptionPlan plan;
  final SubscriptionUsage usage;

  const SubscriptionStatus({
    this.subscription,
    required this.plan,
    required this.usage,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'] as Map<String, dynamic>)
          : null,
      plan: SubscriptionPlan.fromJson(
        json['plan'] as Map<String, dynamic>,
      ),
      usage: SubscriptionUsage.fromJson(
        json['usage'] as Map<String, dynamic>,
      ),
    );
  }

  bool get hasActiveSubscription =>
      subscription != null && subscription!.isActive && !subscription!.isExpired;

  @override
  List<Object?> get props => [subscription, plan, usage];
}

/// Informações de uso da assinatura
class SubscriptionUsage extends Equatable {
  final int patientCount;
  final int patientLimit;
  final bool canCreatePatient;
  final int usagePercentage;

  const SubscriptionUsage({
    required this.patientCount,
    required this.patientLimit,
    required this.canCreatePatient,
    required this.usagePercentage,
  });

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) {
    return SubscriptionUsage(
      patientCount: json['patient_count'] as int? ?? 0,
      patientLimit: json['patient_limit'] as int? ?? 0,
      canCreatePatient: json['can_create_patient'] as bool? ?? false,
      usagePercentage: json['usage_percentage'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        patientCount,
        patientLimit,
        canCreatePatient,
        usagePercentage,
      ];
}

/// Resultado de uma compra
class PurchaseResult extends Equatable {
  final bool success;
  final String? errorMessage;
  final String? purchaseToken;
  final String? orderId;
  final String? productId;

  const PurchaseResult({
    required this.success,
    this.errorMessage,
    this.purchaseToken,
    this.orderId,
    this.productId,
  });

  @override
  List<Object?> get props => [
        success,
        errorMessage,
        purchaseToken,
        orderId,
        productId,
      ];
}

