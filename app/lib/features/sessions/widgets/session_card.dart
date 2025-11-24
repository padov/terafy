import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/sessions/models/session.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;

  const SessionCard({super.key, required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Data, Status e Número da Sessão
              Row(
                children: [
                  // Ícone de status
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Data e hora
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(session.scheduledStartTime),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.offBlack,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(session.scheduledStartTime),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Número da sessão
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Sessão #${session.sessionNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Indicador de pagamento (apenas para sessões completadas)
                  if (session.status == SessionStatus.completed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pago',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (session.status == SessionStatus.completed)
                    const SizedBox(width: 8),

                  // Tipo de sessão
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(),
                          size: 14,
                          color: AppColors.offBlack,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTypeText(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.offBlack,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Pagamento
                  if (session.status == SessionStatus.completed ||
                      session.status == SessionStatus.scheduled ||
                      session.status == SessionStatus.confirmed)
                    Icon(
                      session.paymentStatus == PaymentStatus.paid
                          ? Icons.check_circle
                          : session.paymentStatus == PaymentStatus.pending
                          ? Icons.schedule
                          : Icons.cancel,
                      size: 20,
                      color: session.paymentStatus == PaymentStatus.paid
                          ? Colors.green
                          : session.paymentStatus == PaymentStatus.pending
                          ? Colors.orange
                          : Colors.grey,
                    ),
                ],
              ),

              // Indicador de rascunho
              if (session.status == SessionStatus.draft) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.lightBorderColor),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.amber[800],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Evolução em rascunho - Toque para continuar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Temas discutidos (apenas se sessão completa ou rascunho)
              if ((session.status == SessionStatus.completed ||
                      session.status == SessionStatus.draft) &&
                  session.topicsDiscussed.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (session.status != SessionStatus.draft)
                  const Divider(color: AppColors.lightBorderColor),
                const SizedBox(height: 8),
                Text(
                  'Temas abordados:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.offBlack,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: session.topicsDiscussed.take(3).map((topic) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Text(
                        topic,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (session.topicsDiscussed.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '+${session.topicsDiscussed.length - 3} mais',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],

              // Motivo de cancelamento
              if (session.status == SessionStatus.cancelledByPatient ||
                  session.status == SessionStatus.cancelledByTherapist) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.lightBorderColor),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        session.cancellationReason ?? 'Sem motivo informado',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.offBlack,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    final difference = sessionDate.difference(today).inDays;

    if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Amanhã';
    } else if (difference == -1) {
      return 'Ontem';
    } else {
      return DateFormat('d \'de\' MMMM \'de\' yyyy', 'pt_BR').format(date);
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm', 'pt_BR').format(time);
  }

  Color _getStatusColor() {
    switch (session.status) {
      case SessionStatus.scheduled:
        return Colors.blue;
      case SessionStatus.confirmed:
        return Colors.green;
      case SessionStatus.inProgress:
        return Colors.purple;
      case SessionStatus.completed:
        return Colors.teal;
      case SessionStatus.draft:
        return Colors.amber;
      case SessionStatus.cancelledByTherapist:
      case SessionStatus.cancelledByPatient:
        return Colors.red;
      case SessionStatus.noShow:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (session.status) {
      case SessionStatus.scheduled:
        return Icons.event;
      case SessionStatus.confirmed:
        return Icons.check_circle;
      case SessionStatus.inProgress:
        return Icons.play_circle_filled;
      case SessionStatus.completed:
        return Icons.done_all;
      case SessionStatus.draft:
        return Icons.edit_note;
      case SessionStatus.cancelledByTherapist:
      case SessionStatus.cancelledByPatient:
        return Icons.cancel;
      case SessionStatus.noShow:
        return Icons.person_off;
    }
  }

  String _getStatusText() {
    switch (session.status) {
      case SessionStatus.scheduled:
        return 'Agendada';
      case SessionStatus.confirmed:
        return 'Confirmada';
      case SessionStatus.inProgress:
        return 'Em andamento';
      case SessionStatus.completed:
        return 'Realizada';
      case SessionStatus.draft:
        return 'Rascunho';
      case SessionStatus.cancelledByTherapist:
        return 'Cancelada (Terapeuta)';
      case SessionStatus.cancelledByPatient:
        return 'Cancelada (Paciente)';
      case SessionStatus.noShow:
        return 'Falta';
    }
  }

  IconData _getTypeIcon() {
    switch (session.type) {
      case SessionType.presential:
        return Icons.location_on;
      case SessionType.onlineVideo:
        return Icons.videocam;
      case SessionType.onlineAudio:
        return Icons.call;
      case SessionType.phone:
        return Icons.phone;
      case SessionType.group:
        return Icons.groups;
    }
  }

  String _getTypeText() {
    switch (session.type) {
      case SessionType.presential:
        return 'Presencial';
      case SessionType.onlineVideo:
        return 'Online (Vídeo)';
      case SessionType.onlineAudio:
        return 'Online (Áudio)';
      case SessionType.phone:
        return 'Telefone';
      case SessionType.group:
        return 'Grupo';
    }
  }
}
