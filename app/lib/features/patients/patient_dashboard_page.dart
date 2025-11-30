import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc_models.dart';
import 'package:terafy/features/anamnesis/pages/anamnesis_view_page.dart';
import 'package:terafy/features/anamnesis/pages/anamnesis_form_page.dart';
import 'package:terafy/features/patients/bloc/patients_bloc.dart';
import 'package:terafy/features/patients/bloc/patients_bloc_models.dart';
import 'package:terafy/features/patients/models/patient.dart';
import 'package:terafy/features/patients/registration/patient_registration_page.dart';
import 'package:terafy/routes/app_routes.dart';

class PatientDashboardPage extends StatelessWidget {
  final String patientId;
  final PatientsBloc? bloc;

  const PatientDashboardPage({super.key, required this.patientId, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: _PatientDashboardContent(patientId: patientId),
      );
    }

    final container = DependencyContainer();

    return BlocProvider(
      create: (context) => PatientsBloc(
        getPatientsUseCase: container.getPatientsUseCase,
        createPatientUseCase: container.createPatientUseCase,
        getPatientUseCase: container.getPatientUseCase,
        updatePatientUseCase: container.updatePatientUseCase,
        patientsCacheService: container.patientsCacheService,
        subscriptionRepository: container.subscriptionRepository,
      )..add(const LoadPatients()),
      child: _PatientDashboardContent(patientId: patientId),
    );
  }
}

class _PatientDashboardContent extends StatefulWidget {
  final String patientId;

  const _PatientDashboardContent({required this.patientId});

  @override
  State<_PatientDashboardContent> createState() => _PatientDashboardContentState();
}

class _PatientDashboardContentState extends State<_PatientDashboardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientsBloc>()
        ..add(const ResetPatientsView())
        ..add(SelectPatient(widget.patientId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PatientsBloc, PatientsState>(
      listener: (context, state) {
        if (state is AIAnalysisLoaded) {
          _showAIAnalysisDialog(context, state.analysis);
        } else if (state is PatientUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente atualizado com sucesso!'), backgroundColor: Colors.green),
          );
          // Não precisa recarregar - o estado PatientUpdated já contém o paciente atualizado
          // O builder já trata esse estado corretamente
        } else if (state is PatientsError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        if (state is PatientsError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erro')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PatientsBloc>()
                        ..add(const ResetPatientsView())
                        ..add(SelectPatient(widget.patientId));
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! PatientSelected &&
            state is! AIAnalysisLoading &&
            state is! PatientUpdating &&
            state is! PatientUpdated) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final patient = state is PatientSelected
            ? state.patient
            : state is AIAnalysisLoading
            ? state.patient
            : state is PatientUpdating
            ? state.patient
            : (state as PatientUpdated).patient;

        final isAnalyzing = state is AIAnalysisLoading;
        final isUpdating = state is PatientUpdating;

        return WillPopScope(
          onWillPop: () async {
            context.read<PatientsBloc>().add(const ResetPatientsView());
            Navigator.of(context).pop(true);
            return false;
          },
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            body: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(context, patient),
                      const SizedBox(height: 16),
                      _buildSummaryCards(patient),
                      _buildSessionsHistoryCard(context, patient),
                      _buildAIButton(context, patient, isAnalyzing),
                      _buildQuickSummaryCard(context, patient),
                      _buildSectionCard(
                        context,
                        title: 'Anamnese',
                        icon: Icons.assignment,
                        color: Colors.purple,
                        isExpanded: true,
                        child: _buildAnamnesisInfo(patient),
                      ),
                      _buildSectionCard(
                        context,
                        title: 'Identificação',
                        icon: Icons.person,
                        color: Colors.blue,
                        child: _buildIdentificationInfo(patient),
                      ),
                      _buildSectionCard(
                        context,
                        title: 'Contato',
                        icon: Icons.contact_phone,
                        color: Colors.green,
                        child: _buildContactInfo(patient),
                      ),
                      _buildSectionCard(
                        context,
                        title: 'Profissional e Social',
                        icon: Icons.work,
                        color: Colors.orange,
                        child: _buildProfessionalSocialInfo(patient),
                      ),
                      _buildSectionCard(
                        context,
                        title: 'Saúde',
                        icon: Icons.medical_services,
                        color: Colors.red,
                        child: _buildHealthInfo(patient),
                      ),
                      _buildSectionCard(
                        context,
                        title: 'Administrativo',
                        icon: Icons.attach_money,
                        color: Colors.teal,
                        child: _buildAdministrativeInfo(patient),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                if (isUpdating)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Patient patient) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () => _navigateToEditPatient(context, patient),
                                    child: Text(
                                      patient.fullName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(_getStatusIcon(patient.status), size: 14, color: Colors.white),
                                            const SizedBox(width: 6),
                                            Text(
                                              _getStatusText(patient.status),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${patient.age ?? '--'} anos',
                                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Menu de ações
                            _buildActionsMenu(context, patient),
                          ],
                        ),
                        Row(children: [const SizedBox(height: 10)]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context, Patient patient) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: Colors.white,
      onSelected: (value) => _handleMenuAction(context, value, patient),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: AppColors.offBlack),
              SizedBox(width: 12),
              Text('Editar Paciente'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit_notes',
          child: Row(
            children: [
              Icon(Icons.note_add, size: 20, color: AppColors.offBlack),
              SizedBox(width: 12),
              Text('Editar Observações'),
            ],
          ),
        ),
        if (patient.status == PatientStatus.active)
          const PopupMenuItem(
            value: 'inactivate',
            child: Row(
              children: [
                Icon(Icons.pause_circle_outline, size: 20, color: Colors.orange),
                SizedBox(width: 12),
                Text('Inativar'),
              ],
            ),
          ),
        if (patient.status == PatientStatus.inactive)
          const PopupMenuItem(
            value: 'activate',
            child: Row(
              children: [
                Icon(Icons.play_circle_outline, size: 20, color: Colors.green),
                SizedBox(width: 12),
                Text('Ativar'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Excluir', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action, Patient patient) {
    switch (action) {
      case 'edit':
        _navigateToEditPatient(context, patient);
        break;
      case 'edit_notes':
        _showEditNotesDialog(context, patient);
        break;
      case 'inactivate':
        _showInactivateDialog(context, patient);
        break;
      case 'activate':
        _activatePatient(context, patient);
        break;
      case 'delete':
        _showDeleteDialog(context, patient);
        break;
    }
  }

  void _navigateToEditPatient(BuildContext context, Patient patient) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => PatientRegistrationPage(patientToEdit: patient))).then((result) {
      // Recarrega o paciente após edição
      if (result == true && context.mounted) {
        context.read<PatientsBloc>().add(SelectPatient(patient.id));
      }
    });
  }

  void _showEditNotesDialog(BuildContext context, Patient patient) {
    final notesController = TextEditingController(text: patient.notes ?? '');
    final bloc = context.read<PatientsBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Observações'),
        content: TextField(
          controller: notesController,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Digite suas observações sobre o paciente...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final notes = notesController.text.trim();
              bloc.add(UpdatePatientNotes(patientId: patient.id, notes: notes.isEmpty ? null : notes));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showInactivateDialog(BuildContext context, Patient patient) {
    final reasonController = TextEditingController();
    final bloc = context.read<PatientsBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Inativar Paciente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deseja realmente inativar este paciente?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Informe o motivo da inativação...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final updatedPatient = patient.copyWith(
                status: PatientStatus.inactive,
                inactivationReason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
              );
              bloc.add(UpdatePatient(updatedPatient));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Inativar'),
          ),
        ],
      ),
    );
  }

  void _activatePatient(BuildContext context, Patient patient) {
    final updatedPatient = patient.copyWith(status: PatientStatus.active, inactivationReason: null);
    context.read<PatientsBloc>().add(UpdatePatient(updatedPatient));
  }

  void _showDeleteDialog(BuildContext context, Patient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Paciente'),
        content: const Text('Tem certeza que deseja excluir este paciente? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar exclusão quando houver use case
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Funcionalidade de exclusão em breve!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(PatientStatus status) {
    switch (status) {
      case PatientStatus.active:
        return Icons.check_circle;
      case PatientStatus.evaluated:
        return Icons.assignment;
      case PatientStatus.inactive:
        return Icons.pause_circle;
      case PatientStatus.discharged:
        return Icons.arrow_upward;
      case PatientStatus.dischargeCompleted:
        return Icons.done_all;
    }
  }

  Widget _buildSessionsHistoryCard(BuildContext context, Patient patient) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRouter.sessionsHistoryRoute,
              arguments: {'patientId': patient.id, 'patientName': patient.fullName},
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event_note, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Histórico de Sessões',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.offBlack),
                      ),
                      const SizedBox(height: 4),
                      Text('Ver todas as sessões registradas', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIButton(BuildContext context, Patient patient, bool isAnalyzing) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF667eea).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAnalyzing
              ? null
              : () {
                  context.read<PatientsBloc>().add(RequestAIAnalysis(patient.id));
                },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'patients.dashboard.ai_analysis'.tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAnalyzing ? 'patients.dashboard.ai_analyzing'.tr() : 'patients.dashboard.ai_subtitle'.tr(),
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
                if (isAnalyzing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                else
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Patient patient) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildSummaryCard(
            Icons.event_available,
            patient.totalSessions.toString(),
            'patients.dashboard.total_sessions'.tr(),
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            Icons.attach_money,
            patient.sessionValue?.toStringAsFixed(0) ?? '--',
            'patients.dashboard.session_value'.tr(),
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            Icons.check_circle,
            '${patient.completionPercentage.toStringAsFixed(0)}%',
            'patients.dashboard.completion'.tr(),
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppColors.offBlack.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.offBlack),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    bool isExpanded = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.offBlack.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.offBlack),
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _buildQuickSummaryCard(BuildContext context, Patient patient) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.offBlack.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description, color: Colors.indigo, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Resumo Rápido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.offBlack),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    _showEditNotesDialog(context, patient);
                  },
                  color: Colors.grey[600],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags (sem título)
                if (patient.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: patient.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        side: const BorderSide(color: AppColors.primary),
                        labelStyle: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Observações
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorderColor),
                  ),
                  child: Text(
                    patient.notes ?? 'Nenhuma observação registrada ainda.',
                    style: TextStyle(
                      fontSize: 14,
                      color: patient.notes != null ? AppColors.offBlack : Colors.grey[500],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdministrativeInfo(Patient patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem(
          icon: Icons.attach_money,
          label: 'Valor da Sessão',
          value: patient.sessionValue != null ? patient.sessionValue!.toStringAsFixed(2) : 'Não informado',
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.payment,
          label: 'Forma de Pagamento',
          value: patient.preferredPaymentMethod ?? 'Não informado',
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.event,
          label: 'Data de Início',
          value: patient.treatmentStartDate != null
              ? DateFormat('dd/MM/yyyy').format(patient.treatmentStartDate!)
              : 'Não informado',
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.calendar_today,
          label: 'Última Sessão',
          value: patient.lastSessionDate != null
              ? DateFormat('dd/MM/yyyy').format(patient.lastSessionDate!)
              : 'Não informado',
        ),
      ],
    );
  }

  void _showAIAnalysisDialog(BuildContext context, String analysis) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Análise IA do Paciente',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Container(
                constraints: const BoxConstraints(maxHeight: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(analysis, style: const TextStyle(fontSize: 14, height: 1.6, color: AppColors.offBlack)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(PatientStatus status) {
    switch (status) {
      case PatientStatus.active:
        return 'Ativo';
      case PatientStatus.evaluated:
        return 'Avaliado';
      case PatientStatus.inactive:
        return 'Inativo';
      case PatientStatus.discharged:
        return 'Em Alta';
      case PatientStatus.dischargeCompleted:
        return 'Alta Concluída';
    }
  }

  // ========== NOVAS SEÇÕES ==========

  Widget _buildAnamnesisInfo(Patient patient) {
    return BlocProvider(
      create: (context) => AnamnesisBloc(
        anamnesisRepository: DependencyContainer().anamnesisRepository,
        templateRepository: DependencyContainer().anamnesisTemplateRepository,
      )..add(LoadAnamnesisByPatientId(patient.id)),
      child: BlocBuilder<AnamnesisBloc, AnamnesisState>(
        builder: (context, state) {
          if (state is AnamnesisLoading) {
            return const Center(
              child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
            );
          }

          if (state is AnamnesisError || state is AnamnesisInitial) {
            // Anamnese não encontrada ou erro - mostra botão para criar
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nenhuma anamnese encontrada', style: TextStyle(fontSize: 14, color: AppColors.offBlack)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AnamnesisFormPage(patientId: patient.id, therapistId: patient.therapistId),
                      ),
                    );
                    if (result == true) {
                      // Recarrega anamnese
                      context.read<AnamnesisBloc>().add(LoadAnamnesisByPatientId(patient.id));
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Criar Anamnese'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ],
            );
          }

          if (state is AnamnesisLoaded) {
            final anamnesis = state.anamnesis;

            // Extrai alguns dados principais para preview
            final data = anamnesis.data;
            final chiefComplaint = data['chief_complaint']?['description'] ?? data['description'] ?? 'Não informado';
            final intensity = data['chief_complaint']?['intensity'] ?? data['intensity'] ?? null;
            final expectations =
                data['expectations']?['treatment_expectations'] ?? data['treatment_expectations'] ?? null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (anamnesis.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Completa',
                          style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                if (anamnesis.isCompleted) const SizedBox(height: 12),
                _buildInfoItem(icon: Icons.comment, label: 'Queixa Principal', value: chiefComplaint.toString()),
                if (intensity != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoItem(icon: Icons.track_changes, label: 'Intensidade', value: 'Nível $intensity/10'),
                ],
                if (expectations != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoItem(icon: Icons.flag, label: 'Expectativas', value: expectations.toString()),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AnamnesisViewPage(patientId: patient.id, anamnesisId: anamnesis.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver Anamnese Completa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildIdentificationInfo(Patient patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem(icon: Icons.badge, label: 'CPF', value: patient.cpf ?? 'Não informado'),
        const SizedBox(height: 16),
        _buildInfoItem(icon: Icons.credit_card, label: 'RG', value: patient.rg ?? 'Não informado'),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.cake,
          label: 'Data de Nascimento',
          value: patient.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(patient.dateOfBirth!) : 'Não informado',
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.person,
          label: 'Gênero',
          value: patient.gender != null ? _getGenderText(patient.gender!) : 'Não informado',
        ),
        const SizedBox(height: 16),
        _buildInfoItem(icon: Icons.favorite, label: 'Estado Civil', value: patient.maritalStatus ?? 'Não informado'),
      ],
    );
  }

  Widget _buildContactInfo(Patient patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem(icon: Icons.phone, label: 'Telefone', value: patient.phone),
        const SizedBox(height: 16),
        _buildInfoItem(icon: Icons.email, label: 'Email', value: patient.email ?? 'Não informado'),
        const SizedBox(height: 16),
        _buildInfoItem(icon: Icons.location_on, label: 'Endereço', value: patient.address ?? 'Não informado'),
        if (patient.emergencyContact != null) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Contato de Emergência',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(icon: Icons.person_outline, label: 'Nome', value: patient.emergencyContact!.name),
          const SizedBox(height: 16),
          _buildInfoItem(icon: Icons.phone_outlined, label: 'Telefone', value: patient.emergencyContact!.phone),
          const SizedBox(height: 16),
          _buildInfoItem(icon: Icons.family_restroom, label: 'Relação', value: patient.emergencyContact!.relationship),
        ],
        if (patient.legalGuardian != null) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Responsável Legal',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(icon: Icons.person_outline, label: 'Nome', value: patient.legalGuardian!.name),
          const SizedBox(height: 16),
          _buildInfoItem(icon: Icons.badge, label: 'CPF', value: patient.legalGuardian!.cpf),
          const SizedBox(height: 16),
          _buildInfoItem(icon: Icons.phone_outlined, label: 'Telefone', value: patient.legalGuardian!.phone),
        ],
      ],
    );
  }

  Widget _buildProfessionalSocialInfo(Patient patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem(icon: Icons.work, label: 'Profissão', value: patient.profession ?? 'Não informado'),
        const SizedBox(height: 16),
        _buildInfoItem(icon: Icons.school, label: 'Escolaridade', value: patient.education ?? 'Não informado'),
      ],
    );
  }

  Widget _buildHealthInfo(Patient patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem(
          icon: Icons.local_hospital,
          label: 'Convênio',
          value: patient.healthInsurance ?? 'Não informado',
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.credit_card,
          label: 'Número da Carteirinha',
          value: patient.insuranceCardNumber ?? 'Não informado',
        ),
      ],
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: AppColors.offBlack),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: AppColors.offBlack, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getGenderText(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Masculino';
      case Gender.female:
        return 'Feminino';
      case Gender.other:
        return 'Outro';
      case Gender.preferNotToSay:
        return 'Prefiro não dizer';
    }
  }
}
