import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/home/bloc/home_bloc_models.dart';
import 'package:terafy/routes/app_routes.dart';

class PendingSessions extends StatelessWidget {
  final List<PendingSessionItem> sessions;
  final VoidCallback? onSeeAll;

  const PendingSessions({super.key, required this.sessions, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Sessões Pendentes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.offBlack),
                  ),
                ],
              ),
              if (sessions.isNotEmpty && onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: const Text('Ver todas')),
            ],
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty)
            _buildEmptyState()
          else
            ...sessions
                .take(5)
                .map(
                  (session) =>
                      Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildSessionCard(context, session)),
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
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('Nenhuma sessão pendente', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, PendingSessionItem session) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final statusColor = session.status == 'draft' ? Colors.amber : Colors.orange;
    final statusText = session.status == 'draft' ? 'Rascunho' : 'Sem Registro';

    return InkWell(
      onTap: () {
        // Navegar para detalhes da sessão
        Navigator.of(context).pushNamed(
          AppRouter.sessionDetailsRoute,
          arguments: {'sessionId': session.id.toString(), 'patientName': session.patientName},
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(
                session.status == 'draft' ? Icons.edit_note : Icons.warning_amber,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sessão #${session.sessionNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.offBlack),
                  ),
                  const SizedBox(height: 4),
                  Text(session.patientName, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(session.scheduledStartTime.toLocal()),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        timeFormat.format(session.scheduledStartTime.toLocal()),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(
                statusText,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
