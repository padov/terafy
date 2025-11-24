import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc_models.dart';
import 'package:terafy/features/sessions/models/session.dart';
import 'package:terafy/features/financial/models/payment.dart' as financial;

class SessionDetailsPage extends StatelessWidget {
  final String sessionId;
  final String patientName;

  const SessionDetailsPage({super.key, required this.sessionId, required this.patientName});

  @override
  Widget build(BuildContext context) {
    final container = DependencyContainer();
    return BlocProvider(
      create: (context) => SessionsBloc(
        getSessionsUseCase: container.getSessionsUseCase,
        getSessionUseCase: container.getSessionUseCase,
        createSessionUseCase: container.createSessionUseCase,
        updateSessionUseCase: container.updateSessionUseCase,
        deleteSessionUseCase: container.deleteSessionUseCase,
        getAppointmentUseCase: container.getAppointmentUseCase,
        updateAppointmentUseCase: container.updateAppointmentUseCase,
      )..add(LoadSessionDetails(sessionId)),
      child: _SessionDetailsContent(patientName: patientName),
    );
  }
}

class _SessionDetailsContent extends StatelessWidget {
  final String patientName;

  const _SessionDetailsContent({required this.patientName});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionsBloc, SessionsState>(
      listener: (context, state) {
        if (state is SessionsError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        } else if (state is SessionUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sessão atualizada com sucesso!'), backgroundColor: Colors.green),
          );
          // Recarregar detalhes
          context.read<SessionsBloc>().add(LoadSessionDetails(state.session.id));
        }
      },
      builder: (context, state) {
        if (state is SessionsLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is SessionDetailsLoaded || state is SessionUpdated) {
          final session = state is SessionDetailsLoaded ? state.session : (state as SessionUpdated).session;

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: _buildAppBar(context, session),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com informações principais
                  _buildHeader(session),

                  // Ações rápidas (para todas exceto canceladas)
                  if (session.status != SessionStatus.cancelledByPatient &&
                      session.status != SessionStatus.cancelledByTherapist &&
                      session.status != SessionStatus.noShow)
                    _buildQuickActions(context, session),

                  // Registro clínico (para sessões completadas e rascunhos)
                  if (session.status == SessionStatus.completed || session.status == SessionStatus.draft) ...[
                    _buildClinicalRecordSection(session),
                  ],

                  // Informações da sessão
                  _buildInfoSection(session),

                  // Informações administrativas
                  _buildAdministrativeSection(session),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }

        return const Scaffold(body: Center(child: Text('Erro ao carregar detalhes da sessão')));
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, Session session) {
    return AppBar(
      backgroundColor: _getStatusColor(session.status),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sessão #${session.sessionNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          Text(patientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
        ],
      ),
      actions: [
        if (session.status != SessionStatus.completed)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(context, value, session),
            itemBuilder: (context) => [
              if (session.status == SessionStatus.scheduled)
                const PopupMenuItem(
                  value: 'confirm',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 12),
                      Text('Confirmar Presença'),
                    ],
                  ),
                ),
              if (session.status == SessionStatus.confirmed || session.status == SessionStatus.scheduled)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [Icon(Icons.cancel_outlined, size: 20), SizedBox(width: 12), Text('Cancelar Sessão')],
                  ),
                ),
              if (session.status == SessionStatus.confirmed)
                const PopupMenuItem(
                  value: 'no_show',
                  child: Row(
                    children: [Icon(Icons.person_off_outlined, size: 20), SizedBox(width: 12), Text('Marcar Falta')],
                  ),
                ),
              if (session.status == SessionStatus.confirmed)
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [Icon(Icons.done_all, size: 20), SizedBox(width: 12), Text('Marcar como Realizada')],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildHeader(Session session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(session.status),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Data e hora
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text(
                  _formatDate(session.scheduledStartTime),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(session.scheduledStartTime)} - ${_formatTime(session.scheduledEndTime ?? session.scheduledStartTime.add(Duration(minutes: session.durationMinutes)))}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.durationMinutes} minutos',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getStatusIcon(session.status), color: _getStatusColor(session.status), size: 20),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(session.status),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _getStatusColor(session.status)),
                ),
                // Ícone de pagamento para sessões completadas
                if (session.status == SessionStatus.completed) ...[
                  const SizedBox(width: 12),
                  if (session.paymentStatus == PaymentStatus.paid)
                    Icon(Icons.check_circle, color: Colors.green, size: 18)
                  else if (session.paymentStatus == PaymentStatus.exempt)
                    Icon(Icons.remove_circle_outline, color: Colors.orange, size: 18)
                  else
                    Icon(Icons.pending_outlined, color: Colors.orange[300], size: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Session session) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Ações para rascunhos
              if (session.status == SessionStatus.draft)
                _buildActionChip(
                  context,
                  'Continuar Rascunho',
                  Icons.edit_note,
                  Colors.amber,
                  () => _navigateToEvolution(context, session),
                ),

              // Ações para sessões agendadas
              if (session.status == SessionStatus.scheduled)
                _buildActionChip(
                  context,
                  'Confirmar',
                  Icons.check_circle_outline,
                  Colors.green,
                  () => _confirmSession(context, session),
                ),

              // Ações para sessões confirmadas
              if (session.status == SessionStatus.confirmed)
                _buildActionChip(
                  context,
                  'Registrar Evolução',
                  Icons.edit_note,
                  AppColors.primary,
                  () => _markAsCompletedAndRegister(context, session),
                ),
              if (session.status == SessionStatus.confirmed)
                _buildActionChip(
                  context,
                  'Falta',
                  Icons.person_off,
                  Colors.orange,
                  () => _markAsNoShow(context, session),
                ),

              // Ação para sessões completadas
              if (session.status == SessionStatus.completed)
                _buildActionChip(
                  context,
                  'Editar Evolução',
                  Icons.edit_note,
                  AppColors.primary,
                  () => _navigateToEvolution(context, session),
                ),
              // Mostrar botão de registrar pagamento apenas se pagamento estiver pendente
              if (session.status == SessionStatus.completed && session.paymentStatus == PaymentStatus.pending)
                _buildActionChip(
                  context,
                  'Registrar Pagamento',
                  Icons.attach_money,
                  Colors.green,
                  () => _showRegisterPaymentDialog(context, session),
                ),

              // Cancelar (para todas exceto completadas)
              if (session.status != SessionStatus.completed)
                _buildActionChip(
                  context,
                  'Cancelar',
                  Icons.cancel_outlined,
                  Colors.red,
                  () => _showCancelDialog(context, session),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(Session session) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações da Sessão',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.offBlack),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Tipo', _getTypeText(session.type), Icons.category),
          _buildInfoRow('Modalidade', _getModalityText(session.modality), Icons.people),
          if (session.location != null) _buildInfoRow('Local', session.location!, Icons.location_on),
          if (session.onlineRoomLink != null) _buildInfoRow('Link Online', session.onlineRoomLink!, Icons.video_call),
          if (session.chargedAmount != null)
            _buildInfoRow('Valor', 'R\$ ${session.chargedAmount!.toStringAsFixed(2)}', Icons.attach_money),
          _buildInfoRow('Pagamento', _getPaymentStatusText(session.paymentStatus), Icons.payment),
        ],
      ),
    );
  }

  Widget _buildClinicalRecordSection(Session session) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Registro Clínico',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.offBlack),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Humor do paciente
          if (session.patientMood != null) ...[
            _buildClinicalField('Humor/Estado Emocional', session.patientMood!),
            const SizedBox(height: 12),
          ],

          // Temas discutidos
          if (session.topicsDiscussed.isNotEmpty) ...[
            Text(
              'Temas Abordados',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.topicsDiscussed.map((topic) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(topic, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Notas da sessão
          if (session.sessionNotes != null) ...[
            _buildClinicalField('Notas da Sessão', session.sessionNotes!),
            const SizedBox(height: 12),
          ],

          // Comportamento observado
          if (session.observedBehavior != null) ...[
            _buildClinicalField('Comportamento Observado', session.observedBehavior!),
            const SizedBox(height: 12),
          ],

          // Intervenções utilizadas
          if (session.interventionsUsed.isNotEmpty) ...[
            Text(
              'Técnicas/Intervenções Utilizadas',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            ...session.interventionsUsed.map((intervention) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.check_circle, size: 16, color: Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(intervention, style: TextStyle(fontSize: 13, color: AppColors.offBlack)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // Recursos utilizados
          if (session.resourcesUsed != null) ...[
            _buildClinicalField('Recursos Utilizados', session.resourcesUsed!),
            const SizedBox(height: 12),
          ],

          // Tarefas/Orientações
          if (session.homework != null) ...[
            _buildClinicalField('Tarefas/Orientações', session.homework!),
            const SizedBox(height: 12),
          ],

          // Reações do paciente
          if (session.patientReactions != null) ...[
            _buildClinicalField('Reações do Paciente', session.patientReactions!),
            const SizedBox(height: 12),
          ],

          // Progresso observado
          if (session.progressObserved != null) ...[
            _buildClinicalField('Progresso Observado', session.progressObserved!),
            const SizedBox(height: 12),
          ],

          // Dificuldades identificadas
          if (session.difficultiesIdentified != null) ...[
            _buildClinicalField('Dificuldades Identificadas', session.difficultiesIdentified!),
            const SizedBox(height: 12),
          ],

          // Próximos passos
          if (session.nextSteps != null) ...[
            _buildClinicalField('Próximos Passos', session.nextSteps!),
            const SizedBox(height: 12),
          ],

          // Objetivos para próxima sessão
          if (session.nextSessionGoals != null) ...[
            _buildClinicalField('Objetivos para Próxima Sessão', session.nextSessionGoals!),
            const SizedBox(height: 12),
          ],

          // Necessidade de encaminhamento
          if (session.needsReferral) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Necessita de Encaminhamento',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Nível de risco
          _buildRiskLevel(session.currentRisk),

          // Observações importantes
          if (session.importantObservations != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Observações Importantes',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange),
                        ),
                        const SizedBox(height: 4),
                        Text(session.importantObservations!, style: TextStyle(fontSize: 13, color: AppColors.offBlack)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdministrativeSection(Session session) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações Administrativas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.offBlack),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Lembrete Enviado', session.reminderSent ? 'Sim' : 'Não', Icons.notifications),
          if (session.reminderSentTime != null)
            _buildInfoRow('Enviado em', _formatDateTime(session.reminderSentTime!), Icons.access_time),
          if (session.presenceConfirmationTime != null)
            _buildInfoRow(
              'Presença Confirmada em',
              _formatDateTime(session.presenceConfirmationTime!),
              Icons.check_circle,
            ),
          if (session.cancellationTime != null) ...[
            _buildInfoRow('Cancelado em', _formatDateTime(session.cancellationTime!), Icons.cancel),
            if (session.cancellationReason != null)
              _buildInfoRow('Motivo', session.cancellationReason!, Icons.info_outline),
          ],
          if (session.patientRating != null)
            _buildInfoRow('Avaliação do Paciente', '${session.patientRating}/5 ⭐', Icons.star),
        ],
      ),
    );
  }

  Widget _buildClinicalField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.offBlack),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(value, style: TextStyle(fontSize: 13, color: AppColors.offBlack)),
        ),
      ],
    );
  }

  Widget _buildRiskLevel(RiskLevel risk) {
    Color color;
    String text;
    IconData icon;

    switch (risk) {
      case RiskLevel.low:
        color = Colors.green;
        text = 'Baixo';
        icon = Icons.check_circle;
        break;
      case RiskLevel.medium:
        color = Colors.orange;
        text = 'Médio';
        icon = Icons.warning_amber;
        break;
      case RiskLevel.high:
        color = Colors.red;
        text = 'Alto';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            'Nível de Risco: ',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.offBlack),
          ),
          Text(
            text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
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

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d/MM/yyyy HH:mm', 'pt_BR').format(dateTime);
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
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

  IconData _getStatusIcon(SessionStatus status) {
    switch (status) {
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

  String _getStatusText(SessionStatus status) {
    switch (status) {
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

  String _getTypeText(SessionType type) {
    switch (type) {
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

  String _getModalityText(SessionModality modality) {
    switch (modality) {
      case SessionModality.individual:
        return 'Individual';
      case SessionModality.couple:
        return 'Casal';
      case SessionModality.family:
        return 'Família';
      case SessionModality.group:
        return 'Grupo';
    }
  }

  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pendente';
      case PaymentStatus.paid:
        return 'Pago';
      case PaymentStatus.exempt:
        return 'Isento';
    }
  }

  void _handleMenuAction(BuildContext context, String action, Session session) {
    switch (action) {
      case 'confirm':
        _confirmSession(context, session);
        break;
      case 'cancel':
        _showCancelDialog(context, session);
        break;
      case 'no_show':
        _markAsNoShow(context, session);
        break;
      case 'complete':
        _markAsCompleted(context, session);
        break;
    }
  }

  void _confirmSession(BuildContext context, Session session) {
    context.read<SessionsBloc>().add(ConfirmSession(session.id));
  }

  void _markAsCompleted(BuildContext context, Session session) {
    context.read<SessionsBloc>().add(MarkAsCompleted(session.id));
  }

  void _markAsCompletedAndRegister(BuildContext context, Session session) async {
    // Primeiro marca como completada
    context.read<SessionsBloc>().add(MarkAsCompleted(session.id));

    // Aguarda um pouco para a atualização do estado
    await Future.delayed(const Duration(milliseconds: 500));

    // Navega para o registro de evolução
    if (context.mounted) {
      final result = await Navigator.of(
        context,
      ).pushNamed('/session/evolution', arguments: {'sessionId': session.id, 'patientName': patientName});

      // Se a evolução foi registrada, recarregar detalhes
      if (result == true && context.mounted) {
        context.read<SessionsBloc>().add(LoadSessionDetails(session.id));
      }
    }
  }

  void _navigateToEvolution(BuildContext context, Session session) async {
    final result = await Navigator.of(
      context,
    ).pushNamed('/session/evolution', arguments: {'sessionId': session.id, 'patientName': patientName});

    // Se a evolução foi atualizada, recarregar detalhes
    if (result == true && context.mounted) {
      context.read<SessionsBloc>().add(LoadSessionDetails(session.id));
    }
  }

  void _markAsNoShow(BuildContext context, Session session) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Falta'),
        content: const Text('Deseja realmente marcar esta sessão como falta do paciente?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<SessionsBloc>().add(MarkAsNoShow(session.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Session session) {
    // Capturar o context original que tem acesso ao BlocProvider
    final parentContext = context;

    final reasonController = TextEditingController();
    bool cancelledByPatient = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cancelar Sessão'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Motivo do cancelamento:'),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Digite o motivo...', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: cancelledByPatient,
                onChanged: (value) => setState(() => cancelledByPatient = value ?? false),
                title: const Text('Cancelado pelo paciente'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Fechar')),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(const SnackBar(content: Text('Por favor, informe o motivo')));
                  return;
                }
                Navigator.of(dialogContext).pop();
                // Usar o parentContext que foi capturado no início da função
                parentContext.read<SessionsBloc>().add(
                  CancelSession(
                    sessionId: session.id,
                    reason: reasonController.text,
                    cancelledByPatient: cancelledByPatient,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Cancelar Sessão', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegisterPaymentDialog(BuildContext context, Session session) {
    // Capturar o context original que tem acesso ao BlocProvider
    final parentContext = context;

    financial.PaymentMethod selectedMethod = financial.PaymentMethod.pix;
    DateTime selectedDate = DateTime.now();
    // Valor padrão de 200.00 (poderia vir do paciente ou configuração)
    final amountController = TextEditingController(text: '200.00');
    final receiptController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrar Pagamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Valor'),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: 'R\$ ', hintText: '0,00'),
                ),
                const SizedBox(height: 16),
                const Text('Método de Pagamento'),
                const SizedBox(height: 8),
                DropdownButtonFormField<financial.PaymentMethod>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: financial.PaymentMethod.values.map((method) {
                    return DropdownMenuItem(value: method, child: Text(_getPaymentMethodLabel(method)));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedMethod = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Data do Pagamento'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: session.scheduledStartTime.subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lightBorderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: receiptController,
                  decoration: const InputDecoration(labelText: 'Nº do Recibo (opcional)', hintText: 'Ex: REC-001'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Valor inválido')));
                  return;
                }

                // Atualizar paymentStatus da sessão para 'paid'
                final updatedSession = session.copyWith(
                  paymentStatus: PaymentStatus.paid,
                  chargedAmount: amount,
                  updatedAt: DateTime.now(),
                );

                // Fechar diálogo primeiro
                Navigator.of(dialogContext).pop();

                // Usar o parentContext que foi capturado no início da função
                // Ele tem acesso ao BlocProvider
                parentContext.read<SessionsBloc>().add(UpdateSession(updatedSession));

                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Pagamento de ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(amount)} registrado!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Registrar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _getPaymentMethodLabel(financial.PaymentMethod method) {
    switch (method) {
      case financial.PaymentMethod.cash:
        return 'Dinheiro';
      case financial.PaymentMethod.creditCard:
        return 'Cartão de Crédito';
      case financial.PaymentMethod.debitCard:
        return 'Cartão de Débito';
      case financial.PaymentMethod.pix:
        return 'PIX';
      case financial.PaymentMethod.bankTransfer:
        return 'Transferência';
      case financial.PaymentMethod.healthInsurance:
        return 'Convênio';
      case financial.PaymentMethod.other:
        return 'Outro';
    }
  }
}
