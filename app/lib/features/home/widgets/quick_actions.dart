import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/common/app_colors.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback? onNewAppointment;
  final VoidCallback? onSearchPatient;
  final VoidCallback? onViewSchedule;
  final VoidCallback? onAddNote;
  final VoidCallback? onViewFinancial;

  const QuickActions({
    super.key,
    this.onNewAppointment,
    this.onSearchPatient,
    this.onViewSchedule,
    this.onAddNote,
    this.onViewFinancial,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'home.quick_actions.title'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.offBlack,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionButton(
                icon: Icons.add_circle_outline,
                label: 'home.quick_actions.new_appointment'.tr(),
                color: AppColors.primary,
                onTap: onNewAppointment,
              ),
              _buildActionButton(
                icon: Icons.search,
                label: 'home.quick_actions.search_patient'.tr(),
                color: AppColors.secondary,
                onTap: onSearchPatient,
              ),
              _buildActionButton(
                icon: Icons.calendar_month,
                label: 'home.quick_actions.view_schedule'.tr(),
                color: AppColors.success,
                onTap: onViewSchedule,
              ),
              _buildActionButton(
                icon: Icons.attach_money,
                label: 'Financeiro',
                color: Colors.green,
                onTap: onViewFinancial,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.offBlack,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
