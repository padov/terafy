import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/agenda/bloc/agenda_bloc.dart';
import 'package:terafy/features/agenda/bloc/agenda_bloc_models.dart';
import 'package:terafy/features/agenda/models/appointment.dart';
import 'package:terafy/features/agenda/new_appointment_page.dart';
import 'package:terafy/routes/app_routes.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsPage({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  late final AgendaBloc _agendaBloc;
  String? _loadedPatientId;
  int? _patientCompletedSessions;
  DateTime? _patientLastSessionDate;
  Appointment? _previousAppointment; // Para detectar mudanças

  @override
  void initState() {
    super.initState();
    _agendaBloc = context.read<AgendaBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _agendaBloc.add(LoadAppointmentDetails(widget.appointmentId));
    });
  }

  @override
  void dispose() {
    _agendaBloc.add(const ResetAgendaView());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Agendamento', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<AgendaBloc, AgendaState>(
        listener: (context, state) {
          if (state is AppointmentCancelled) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Agendamento cancelado'), backgroundColor: Colors.orange));
            Navigator.of(context).pop();
          } else if (state is AppointmentUpdated) {
            // Mostrar feedback baseado na mudança de status
            final appointment = state.appointment;
            String message;
            Color backgroundColor;

            // Detectar mudanças específicas comparando com o estado anterior
            final wasConfirmed = _previousAppointment?.status == AppointmentStatus.confirmed;
            final isConfirmed = appointment.status == AppointmentStatus.confirmed;
            final wasCompleted = _previousAppointment?.status == AppointmentStatus.completed;
            final isCompleted = appointment.status == AppointmentStatus.completed;

            if (isConfirmed && !wasConfirmed) {
              message = 'Agendamento confirmado com sucesso!';
              backgroundColor = Colors.blue;
            } else if (isCompleted && !wasCompleted) {
              message = 'Agendamento concluído!';
              backgroundColor = Colors.green;
            } else if (appointment.status == AppointmentStatus.noShow) {
              message = 'Falta registrada';
              backgroundColor = Colors.orange;
            } else {
              message = 'Agendamento atualizado';
              backgroundColor = Colors.grey;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)),
            );
          } else if (state is AgendaError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is AgendaLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AgendaError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Voltar')),
                ],
              ),
            );
          }

          final appointment = _resolveAppointment(state);
          if (appointment != null) {
            // Atualizar referência anterior quando o agendamento muda
            if (_previousAppointment == null ||
                _previousAppointment!.id != appointment.id ||
                _previousAppointment!.updatedAt != appointment.updatedAt) {
              _previousAppointment = appointment;
            }
            _maybeFetchPatientStats(appointment);
            return _buildDetails(context, appointment);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Appointment appointment) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status Badge
              _buildStatusBadge(appointment.status),

              const SizedBox(height: 24),

              // Data e Hora
              _buildInfoCard(
                icon: Icons.calendar_today,
                title: 'Data e Horário',
                children: [
                  _buildInfoRow('Data', dateFormat.format(appointment.dateTime)),
                  _buildInfoRow(
                    'Horário',
                    '${timeFormat.format(appointment.dateTime)} - ${timeFormat.format(appointment.endTime)}',
                  ),
                  _buildInfoRow('Duração', '${appointment.duration.inMinutes} minutos'),
                  _buildInfoRow('Tipo', _getTypeLabel(appointment.type)),
                  if (appointment.recurrence != RecurrenceType.none)
                    _buildInfoRow('Recorrência', _getRecurrenceLabel(appointment.recurrence)),
                ],
              ),

              const SizedBox(height: 16),

              // Paciente (se aplicável)
              if (appointment.patientId != null)
                _buildInfoCard(
                  icon: Icons.person,
                  title: 'Paciente',
                  children: [
                    _buildInfoRow('Nome', appointment.patientName ?? 'Paciente não identificado'),
                    if (_patientCompletedSessions != null)
                      _buildInfoRow('Sessões concluídas', _patientCompletedSessions!.toString()),
                    if (_patientLastSessionDate != null)
                      _buildInfoRow(
                        'Última sessão',
                        '${DateFormat('dd/MM/yyyy').format(_patientLastSessionDate!)} às ${DateFormat('HH:mm').format(_patientLastSessionDate!)}',
                      ),
                  ],
                ),

              if (appointment.patientId != null) const SizedBox(height: 16),

              // Local
              if (appointment.room != null || appointment.onlineLink != null)
                _buildInfoCard(
                  icon: Icons.location_on,
                  title: 'Local',
                  children: [
                    if (appointment.room != null) _buildInfoRow('Sala', appointment.room!),
                    if (appointment.onlineLink != null) _buildInfoRow('Link', appointment.onlineLink!, copyable: true),
                  ],
                ),

              if (appointment.room != null || appointment.onlineLink != null) const SizedBox(height: 16),

              // Notas
              if (appointment.notes != null)
                _buildInfoCard(
                  icon: Icons.notes,
                  title: 'Notas',
                  children: [Text(appointment.notes!, style: const TextStyle(fontSize: 14, color: AppColors.offBlack))],
                ),

              if (appointment.notes != null) const SizedBox(height: 16),

              // Sessão vinculada
              if (appointment.sessionId != null)
                _buildInfoCard(
                  icon: Icons.assignment,
                  title: 'Sessão Registrada',
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Uma sessão foi criada e vinculada a este agendamento.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRouter.sessionDetailsRoute,
                            arguments: {
                              'sessionId': appointment.sessionId!,
                              'patientName': appointment.patientName ?? 'Paciente',
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.assignment, color: Colors.white),
                        label: const Text(
                          'Ver Detalhes da Sessão',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),

        // Ações na parte inferior
        _buildBottomActions(context, appointment),
      ],
    );
  }

  Appointment? _resolveAppointment(AgendaState state) {
    if (state is AppointmentDetailsLoaded) {
      return state.appointment;
    }
    if (state is AppointmentUpdated) {
      return state.appointment;
    }
    if (state is AgendaLoaded) {
      try {
        return state.appointments.firstWhere((apt) => apt.id == widget.appointmentId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> _maybeFetchPatientStats(Appointment appointment) async {
    final patientId = appointment.patientId;
    if (patientId == null) return;
    if (_loadedPatientId == patientId) return;

    _loadedPatientId = patientId;

    try {
      final patient = await DependencyContainer().getPatientUseCase(patientId);
      if (!mounted) return;
      setState(() {
        _patientCompletedSessions = patient.totalSessions;
        _patientLastSessionDate = patient.lastSessionDate;
      });
    } catch (_) {
      // silencia erros de carregamento de paciente
    }
  }

  Widget _buildStatusBadge(AppointmentStatus status) {
    final colors = _getStatusColors(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors['border']!, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getStatusIcon(status), color: colors['border'], size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: colors['text'], fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.offBlack),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, Appointment appointment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ações principais
            if (appointment.canBeConfirmed) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AgendaBloc>().add(ConfirmAppointment(appointment.id));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Confirmar Agendamento',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Ações secundárias
            Row(
              children: [
                if (appointment.canBeCancelled) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showCancelDialog(context, appointment);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navega para a página de edição passando o agendamento
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<AgendaBloc>(),
                            child: NewAppointmentPage(appointment: appointment),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Appointment appointment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tem certeza que deseja cancelar este agendamento?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)', hintText: 'Ex: Paciente desmarcou'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Voltar')),
          ElevatedButton(
            onPressed: () {
              context.read<AgendaBloc>().add(
                CancelAppointment(
                  appointmentId: appointment.id,
                  reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                ),
              );
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar Agendamento', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(AppointmentType type) {
    switch (type) {
      case AppointmentType.session:
        return 'Sessão';
      case AppointmentType.personal:
        return 'Compromisso pessoal';
      case AppointmentType.block:
        return 'Bloqueio de horário';
    }
  }

  String _getRecurrenceLabel(RecurrenceType recurrence) {
    switch (recurrence) {
      case RecurrenceType.none:
        return 'Único';
      case RecurrenceType.daily:
        return 'Diário';
      case RecurrenceType.weekly:
        return 'Semanal';
    }
  }

  String _getStatusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.reserved:
        return 'Agendado';
      case AppointmentStatus.confirmed:
        return 'Confirmado';
      case AppointmentStatus.completed:
        return 'Concluído';
      case AppointmentStatus.cancelled:
        return 'Cancelado';
      case AppointmentStatus.noShow:
        return 'Faltou';
    }
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
        return {'background': Colors.blue.withOpacity(0.1), 'border': Colors.blue, 'text': Colors.blue.shade700};
      case AppointmentStatus.completed:
        return {'background': Colors.green.withOpacity(0.1), 'border': Colors.green, 'text': Colors.green.shade700};
      case AppointmentStatus.cancelled:
        return {'background': Colors.red.withOpacity(0.1), 'border': Colors.red, 'text': Colors.red.shade700};
      case AppointmentStatus.noShow:
        return {'background': Colors.orange.withOpacity(0.1), 'border': Colors.orange, 'text': Colors.orange.shade700};
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.reserved:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.noShow:
        return Icons.person_off;
    }
  }
}
