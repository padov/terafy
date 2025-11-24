import 'package:flutter/material.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/agenda/models/appointment.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  const AppointmentCard({super.key, required this.appointment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSession = appointment.type == AppointmentType.session;

    final colors = _getStatusColors(appointment.status);
    final patientLabel = (appointment.patientName ?? appointment.patientId)
        ?.trim();
    final timeRange =
        '${appointment.dateTime.hour.toString().padLeft(2, '0')}:${appointment.dateTime.minute.toString().padLeft(2, '0')}'
        ' - '
        '${appointment.endTime.hour.toString().padLeft(2, '0')}:${appointment.endTime.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: isSession
          ? _sessionAppointmentCard(patientLabel: patientLabel, colors: colors)
          : _blockedAppointmentCard(timeRange: timeRange),
    );
  }

  Widget _sessionAppointmentCard({
    required String? patientLabel,
    required Map<String, Color> colors,
  }) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors['border']!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(appointment.status),
            size: 10,
            color: colors['border'],
          ),
          if (patientLabel != null && patientLabel.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              patientLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: colors['text'],
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _blockedAppointmentCard({required String timeRange}) {
    final isBlock = appointment.type == AppointmentType.block;
    final icon = isBlock ? Icons.lock : Icons.lock_person;

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isBlock ? const Color(0xFFE8E8E8) : const Color(0xFFF2F2F2),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16, color: Colors.grey.shade500)],
      ),
    );
  }

  Map<String, Color> _getStatusColors(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.reserved:
        return {
          'background': AppColors.primary.withOpacity(0.1),
          'border': AppColors.primary,
          'text': AppColors.primary,
        };
      case AppointmentStatus.confirmed:
        return {
          'background': Colors.blue.withOpacity(0.1),
          'border': Colors.blue,
          'text': Colors.blue.shade700,
        };
      case AppointmentStatus.completed:
        return {
          'background': Colors.green.withOpacity(0.1),
          'border': Colors.green,
          'text': Colors.green.shade700,
        };
      case AppointmentStatus.cancelled:
        return {
          'background': Colors.red.withOpacity(0.1),
          'border': Colors.red,
          'text': Colors.red.shade700,
        };
      case AppointmentStatus.noShow:
        return {
          'background': Colors.orange.withOpacity(0.1),
          'border': Colors.orange,
          'text': Colors.orange.shade700,
        };
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.reserved:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
      case AppointmentStatus.noShow:
        return Icons.person_off_outlined;
    }
  }
}
