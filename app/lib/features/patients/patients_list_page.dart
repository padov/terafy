import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/patients/bloc/patients_bloc.dart';
import 'package:terafy/features/patients/bloc/patients_bloc_models.dart';
import 'package:terafy/features/patients/models/patient.dart';
import 'package:terafy/features/patients/patient_dashboard_page.dart';
import 'package:terafy/features/patients/widgets/patient_card.dart';
import 'package:terafy/features/patients/widgets/quick_add_patient_modal.dart';

class PatientsListPage extends StatelessWidget {
  const PatientsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final container = DependencyContainer();
    return BlocProvider(
      create: (context) => PatientsBloc(
        getPatientsUseCase: container.getPatientsUseCase,
        createPatientUseCase: container.createPatientUseCase,
        getPatientUseCase: container.getPatientUseCase,
        patientsCacheService: container.patientsCacheService,
      )..add(const LoadPatients()),
      child: const _PatientsListPageContent(),
    );
  }
}

class _PatientsListPageContent extends StatefulWidget {
  const _PatientsListPageContent();

  @override
  State<_PatientsListPageContent> createState() =>
      _PatientsListPageContentState();
}

class _PatientsListPageContentState extends State<_PatientsListPageContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'patients.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.offBlack,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterOptions(context),
          ),
        ],
      ),
      body: BlocConsumer<PatientsBloc, PatientsState>(
        listener: (context, state) {
          print('state: $state');
          if (state is PatientAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('patients.added_success'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is PatientsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PatientsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PatientAdding) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PatientsError && state is! PatientsLoaded) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PatientsBloc>().add(const LoadPatients());
                    },
                    child: Text('common.retry'.tr()),
                  ),
                ],
              ),
            );
          }

          if (state is PatientsLoaded) {
            return Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'patients.search_hint'.tr(),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context.read<PatientsBloc>().add(
                                  const SearchPatients(''),
                                );
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      context.read<PatientsBloc>().add(SearchPatients(value));
                    },
                  ),
                ),

                // Lista de pacientes
                Expanded(
                  child: state.filteredPatients.isEmpty
                      ? _buildEmptyState(context)
                      : RefreshIndicator(
                          onRefresh: () async {
                            context.read<PatientsBloc>().add(
                              const RefreshPatients(),
                            );
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                          },
                          child: ListView.builder(
                            itemCount: state.filteredPatients.length,
                            itemBuilder: (context, index) {
                              final patient = state.filteredPatients[index];
                              return PatientCard(
                                patient: patient,
                                onTap: () async {
                                  final bloc = context.read<PatientsBloc>();

                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PatientDashboardPage(
                                        patientId: patient.id,
                                        bloc: bloc,
                                      ),
                                    ),
                                  );

                                  if (!context.mounted) return;

                                  bloc
                                    ..add(const ResetPatientsView())
                                    ..add(const LoadPatients());
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickAddModal(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add),
        label: Text(
          'patients.add_button'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'patients.empty_state'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'patients.empty_state_hint'.tr(),
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'patients.empty_state_action'.tr(),
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showQuickAddModal(BuildContext context) {
    // Captura o BLoC ANTES de abrir o modal
    final patientsBloc = context.read<PatientsBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider.value(
        value: patientsBloc,
        child: const QuickAddPatientModal(),
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'patients.filter_title'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFilterOption(context, 'patients.filter_all'.tr(), null),
            _buildFilterOption(
              context,
              'patients.filter_active'.tr(),
              PatientStatus.active,
            ),
            _buildFilterOption(context, 'Avaliado', PatientStatus.evaluated),
            _buildFilterOption(
              context,
              'patients.filter_inactive'.tr(),
              PatientStatus.inactive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    String label,
    PatientStatus? status,
  ) {
    return ListTile(
      title: Text(label),
      onTap: () {
        context.read<PatientsBloc>().add(FilterPatientsByStatus(status));
        Navigator.pop(context);
      },
    );
  }
}
