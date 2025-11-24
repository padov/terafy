import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/common/app_colors.dart';

class StatsCards extends StatelessWidget {
  final int todayPatients;
  final int pendingAppointments;
  final double monthlyRevenue;
  final int completionRate;

  const StatsCards({
    super.key,
    required this.todayPatients,
    required this.pendingAppointments,
    required this.monthlyRevenue,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people_outline,
                  value: todayPatients.toString(),
                  label: 'home.stats.today_patients'.tr(),
                  color: AppColors.primary,
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule_outlined,
                  value: pendingAppointments.toString(),
                  label: 'home.stats.pending'.tr(),
                  color: AppColors.secondary,
                  iconColor: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  value: NumberFormat(
                    '#,##0.00',
                    'pt_BR',
                  ).format(monthlyRevenue),
                  label: 'home.stats.monthly_revenue'.tr(),
                  color: AppColors.success,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  value: '$completionRate%',
                  label: 'home.stats.completion_rate'.tr(),
                  color: AppColors.warning,
                  iconColor: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.offBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone e valor na mesma linha
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.offBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Label abaixo
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
