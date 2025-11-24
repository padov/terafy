import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/agenda/appointment_details_page.dart';
import 'package:terafy/features/agenda/bloc/agenda_bloc.dart';
import 'package:terafy/features/agenda/bloc/agenda_bloc_models.dart';
import 'package:terafy/features/home/bloc/home_bloc_models.dart';

class TodayAgenda extends StatelessWidget {
  final List<Appointment> appointments;
  final VoidCallback? onSeeAll;

  const TodayAgenda({super.key, required this.appointments, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'home.agenda.title'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.offBlack,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onSeeAll,
                child: Text('home.agenda.see_all'.tr()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (appointments.isEmpty)
            _buildEmptyState()
          else
            ...appointments.map(
              (appointment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAppointmentCard(context, appointment),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'home.agenda.empty'.tr(),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    final statusColor = _getStatusColor(appointment.status);

    return InkWell(
      onTap: () {
        final container = DependencyContainer();
        final weekStart = _getWeekStart(appointment.startTime);
        final weekEnd = weekStart.add(const Duration(days: 7));

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => AgendaBloc(
                getAppointmentsUseCase: container.getAppointmentsUseCase,
                getAppointmentUseCase: container.getAppointmentUseCase,
                createAppointmentUseCase: container.createAppointmentUseCase,
                updateAppointmentUseCase: container.updateAppointmentUseCase,
                createSessionUseCase: container.createSessionUseCase,
                getNextSessionNumberUseCase:
                    container.getNextSessionNumberUseCase,
                getSessionUseCase: container.getSessionUseCase,
                updateSessionUseCase: container.updateSessionUseCase,
              )..add(LoadAgenda(startDate: weekStart, endDate: weekEnd)),
              child: AppointmentDetailsPage(appointmentId: appointment.id),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorderColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.offBlack.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Time indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                appointment.time,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Appointment info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.offBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.serviceType,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Status icon (centralizado verticalmente)
            Icon(
              _getStatusIcon(appointment.status),
              size: 22,
              color: statusColor,
            ),

            // Action button
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.reserved:
        return AppColors.secondary;
      case AppointmentStatus.confirmed:
        return AppColors.primary;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.reserved:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline;
      case AppointmentStatus.completed:
        return Icons.check_circle;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }
}
