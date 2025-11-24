import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/common/app_colors.dart';

class SignupStep3Plan extends StatefulWidget {
  final int? initialPlanId;
  final Function(int planId) onPlanSelected;

  const SignupStep3Plan({
    super.key,
    this.initialPlanId,
    required this.onPlanSelected,
  });

  @override
  State<SignupStep3Plan> createState() => _SignupStep3PlanState();
}

class _SignupStep3PlanState extends State<SignupStep3Plan> {
  late int? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = widget.initialPlanId;
  }

  void _selectPlan(int planId) {
    setState(() {
      _selectedPlanId = planId;
    });
    widget.onPlanSelected(planId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'signup.step3.title'.tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.offBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'signup.step3.subtitle'.tr(),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),

        // Plano Free
        _buildPlanCard(
          planId: 1,
          title: 'signup.step3.free_plan'.tr(),
          price: 'signup.step3.free_price'.tr(),
          features: [
            'signup.step3.free_feature1'.tr(),
            'signup.step3.free_feature2'.tr(),
            'signup.step3.free_feature3'.tr(),
          ],
          color: Colors.grey,
        ),
        const SizedBox(height: 16),

        // Plano Básico
        _buildPlanCard(
          planId: 2,
          title: 'signup.step3.basic_plan'.tr(),
          price: 'signup.step3.basic_price'.tr(),
          features: [
            'signup.step3.basic_feature1'.tr(),
            'signup.step3.basic_feature2'.tr(),
            'signup.step3.basic_feature3'.tr(),
            'signup.step3.basic_feature4'.tr(),
          ],
          color: AppColors.secondary,
          highlighted: true,
        ),
        const SizedBox(height: 16),

        // Plano Completo
        _buildPlanCard(
          planId: 3,
          title: 'signup.step3.complete_plan'.tr(),
          price: 'signup.step3.complete_price'.tr(),
          features: [
            'signup.step3.complete_feature1'.tr(),
            'signup.step3.complete_feature2'.tr(),
            'signup.step3.complete_feature3'.tr(),
            'signup.step3.complete_feature4'.tr(),
            'signup.step3.complete_feature5'.tr(),
          ],
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required int planId,
    required String title,
    required String price,
    required List<String> features,
    required Color color,
    bool highlighted = false,
  }) {
    final isSelected = _selectedPlanId == planId;

    return GestureDetector(
      onTap: () => _selectPlan(planId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (highlighted || isSelected)
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.offBlack,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),

            // Features
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.offBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
