import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/subscription/subscription_models.dart';

class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final ProductDetails? productDetails;
  final bool isCurrentPlan;
  final bool isPurchasing;
  final VoidCallback? onPurchase;
  final VoidCallback? onSelect;

  const PlanCard({
    super.key,
    required this.plan,
    this.productDetails,
    this.isCurrentPlan = false,
    this.isPurchasing = false,
    this.onPurchase,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCurrentPlan ? AppColors.primary : AppColors.secondary;
    final priceText = _getPriceText();

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isCurrentPlan ? color : Colors.grey[300]!, width: isCurrentPlan ? 3 : 1),
          boxShadow: [
            if (isCurrentPlan) BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          priceText,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.offBlack),
                        ),
                        if (plan.patientLimit >= 999999) const SizedBox(height: 4),
                        if (plan.patientLimit >= 999999)
                          Text('Pacientes ilimitados', style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                        else
                          const SizedBox(height: 4),
                        if (plan.patientLimit < 999999)
                          Text(
                            'Até ${plan.patientLimit} pacientes',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  if (isCurrentPlan)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 24),
                    ),
                ],
              ),
            ),

            // Features
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan.features.isNotEmpty)
                    ...plan.features.map((feature) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: color, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(feature, style: const TextStyle(fontSize: 14, color: AppColors.offBlack)),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  // Botão de ação
                  if (onPurchase != null && !isCurrentPlan)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isPurchasing ? null : onPurchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isPurchasing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Assinar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (isCurrentPlan)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                        child: Text(
                          'Plano Atual',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.offBlack),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriceText() {
    if (plan.price == 0) {
      return 'Gratuito';
    }

    if (productDetails != null) {
      return productDetails!.price;
    }

    return 'R\$ ${plan.price.toStringAsFixed(2)}/mês';
  }
}
