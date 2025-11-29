import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_objective.dart';

class TherapeuticObjectiveCard extends StatelessWidget {
  final TherapeuticObjective objective;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onUpdateProgress;

  const TherapeuticObjectiveCard({
    super.key,
    required this.objective,
    this.onTap,
    this.onEdit,
    this.onUpdateProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getPriorityColor(objective.priority).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Status, Prioridade e Progresso
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(objective.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(objective.status),
                          size: 14,
                          color: _getStatusColor(objective.status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusLabel(objective.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(objective.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Prioridade Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(objective.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPriorityIcon(objective.priority),
                          size: 14,
                          color: _getPriorityColor(objective.priority),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getPriorityLabel(objective.priority),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getPriorityColor(objective.priority),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Descrição do Objetivo
              Text(
                objective.description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.offBlack,
                ),
              ),

              const SizedBox(height: 12),

              // Campos SMART - Específico e Mensurável
              _buildSMARTField(
                'Específico',
                objective.specificAspect,
                Icons.pin,
              ),
              const SizedBox(height: 8),
              _buildSMARTField(
                'Mensurável',
                objective.measurableCriteria,
                Icons.analytics,
              ),

              if (objective.targetDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Prazo: ${_formatDate(objective.targetDate!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Barra de Progresso
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progresso',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${objective.progressPercentage}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: objective.progressPercentage / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(objective.progressPercentage),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onUpdateProgress != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: AppColors.primary,
                      onPressed: onUpdateProgress,
                      tooltip: 'Atualizar progresso',
                    ),
                  ],
                ],
              ),

              // Ações rápidas
              if (onEdit != null || onTap != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Editar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    if (onTap != null)
                      TextButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('Ver detalhes'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
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

  Widget _buildSMARTField(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.offBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ObjectiveStatus status) {
    switch (status) {
      case ObjectiveStatus.pending:
        return Colors.grey;
      case ObjectiveStatus.inProgress:
        return Colors.blue;
      case ObjectiveStatus.completed:
        return Colors.green;
      case ObjectiveStatus.abandoned:
        return Colors.red;
      case ObjectiveStatus.onHold:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(ObjectiveStatus status) {
    switch (status) {
      case ObjectiveStatus.pending:
        return Icons.pending;
      case ObjectiveStatus.inProgress:
        return Icons.play_circle_outline;
      case ObjectiveStatus.completed:
        return Icons.check_circle;
      case ObjectiveStatus.abandoned:
        return Icons.cancel;
      case ObjectiveStatus.onHold:
        return Icons.pause_circle;
    }
  }

  String _getStatusLabel(ObjectiveStatus status) {
    switch (status) {
      case ObjectiveStatus.pending:
        return 'Pendente';
      case ObjectiveStatus.inProgress:
        return 'Em Andamento';
      case ObjectiveStatus.completed:
        return 'Concluído';
      case ObjectiveStatus.abandoned:
        return 'Abandonado';
      case ObjectiveStatus.onHold:
        return 'Em Pausa';
    }
  }

  Color _getPriorityColor(ObjectivePriority priority) {
    switch (priority) {
      case ObjectivePriority.low:
        return Colors.grey;
      case ObjectivePriority.medium:
        return Colors.blue;
      case ObjectivePriority.high:
        return Colors.orange;
      case ObjectivePriority.urgent:
        return Colors.red;
    }
  }

  IconData _getPriorityIcon(ObjectivePriority priority) {
    switch (priority) {
      case ObjectivePriority.low:
        return Icons.arrow_downward;
      case ObjectivePriority.medium:
        return Icons.remove;
      case ObjectivePriority.high:
        return Icons.arrow_upward;
      case ObjectivePriority.urgent:
        return Icons.priority_high;
    }
  }

  String _getPriorityLabel(ObjectivePriority priority) {
    switch (priority) {
      case ObjectivePriority.low:
        return 'Baixa';
      case ObjectivePriority.medium:
        return 'Média';
      case ObjectivePriority.high:
        return 'Alta';
      case ObjectivePriority.urgent:
        return 'Urgente';
    }
  }

  Color _getProgressColor(int percentage) {
    if (percentage < 30) {
      return Colors.red;
    } else if (percentage < 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

