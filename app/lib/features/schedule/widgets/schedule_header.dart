import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:terafy/common/app_colors.dart';

class ScheduleHeader extends StatelessWidget {
  final DateTime currentWeekStart;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onToday;

  const ScheduleHeader({
    super.key,
    required this.currentWeekStart,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final periodEnd = currentWeekStart.add(const Duration(days: 6));
    final isCurrentPeriod = _isCurrentPeriod(currentWeekStart);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPreviousWeek,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.primary,
              ),
              Expanded(
                child: Text(
                  '${_formatPeriodRange(currentWeekStart, periodEnd)}, ${_formatYear(currentWeekStart)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.offBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: onNextWeek,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.primary,
              ),
            ],
          ),
          if (!isCurrentPeriod)
            TextButton.icon(
              onPressed: onToday,
              icon: const Icon(Icons.today, size: 16),
              label: Text('schedule.today_button'.tr()),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  String _formatPeriodRange(DateTime start, DateTime end) {
    final startFormat = DateFormat('d MMM', 'pt_BR');
    final endFormat = DateFormat('d MMM', 'pt_BR');

    return '${startFormat.format(start)} - ${endFormat.format(end)}';
  }

  String _formatYear(DateTime date) {
    return DateFormat('yyyy', 'pt_BR').format(date);
  }

  bool _isCurrentPeriod(DateTime periodStart) {
    final now = DateTime.now();
    final periodEnd = periodStart.add(const Duration(days: 6));

    // Verifica se "hoje" está dentro do período de 4 dias
    return now.isAfter(periodStart.subtract(const Duration(days: 1))) &&
        now.isBefore(periodEnd.add(const Duration(days: 1)));
  }
}
