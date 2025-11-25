import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc_models.dart';
import 'package:terafy/features/anamnesis/models/anamnesis.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_template.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_section.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_field.dart';
import 'anamnesis_form_page.dart';

class AnamnesisViewPage extends StatelessWidget {
  final String patientId;
  final String? anamnesisId;

  const AnamnesisViewPage({
    super.key,
    required this.patientId,
    this.anamnesisId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnamnesisBloc(
        anamnesisRepository: DependencyContainer().anamnesisRepository,
        templateRepository: DependencyContainer().anamnesisTemplateRepository,
      )..add(anamnesisId != null
          ? LoadAnamnesisById(anamnesisId!)
          : LoadAnamnesisByPatientId(patientId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Anamnese'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<AnamnesisBloc, AnamnesisState>(
          builder: (context, state) {
            if (state is AnamnesisLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AnamnesisError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AnamnesisBloc>().add(
                              anamnesisId != null
                                  ? LoadAnamnesisById(anamnesisId!)
                                  : LoadAnamnesisByPatientId(patientId),
                            );
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

            if (state is AnamnesisLoaded) {
              return _buildAnamnesisView(context, state.anamnesis, state.template);
            }

            return const Center(child: Text('Nenhuma anamnese encontrada'));
          },
        ),
      ),
    );
  }

  Widget _buildAnamnesisView(
    BuildContext context,
    Anamnesis anamnesis,
    AnamnesisTemplate? template,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            color: AppColors.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template?.name ?? 'Anamnese',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (anamnesis.completedAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Completa',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (anamnesis.completedAt == null)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            // Navegar para edição
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AnamnesisFormPage(
                                  patientId: anamnesis.patientId,
                                  therapistId: anamnesis.therapistId,
                                  template: template,
                                  existingAnamnesis: anamnesis,
                                ),
                              ),
                            );
                            // Recarrega anamnese após editar
                            if (result == true && context.mounted) {
                              context.read<AnamnesisBloc>().add(
                                    anamnesisId != null
                                        ? LoadAnamnesisById(anamnesisId!)
                                        : LoadAnamnesisByPatientId(patientId),
                                  );
                            }
                          },
                        ),
                    ],
                  ),
                  if (template?.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        template!.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seções
          if (template != null)
            ...template.sections.map((section) {
              return _buildSectionCard(section, anamnesis.data);
            }).toList()
          else
            // Fallback: mostra dados brutos se não houver template
            _buildRawDataCard(anamnesis.data),

          const SizedBox(height: 16),

          // Metadata
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informações',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Criada em', _formatDate(anamnesis.createdAt)),
                  _buildInfoRow('Atualizada em', _formatDate(anamnesis.updatedAt)),
                  if (anamnesis.completedAt != null)
                    _buildInfoRow('Completada em', _formatDate(anamnesis.completedAt!)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(AnamnesisSection section, Map<String, dynamic> data) {
    final sortedFields = List.from(section.fields)
      ..sort((a, b) => a.order.compareTo(b.order));

    final hasData = sortedFields.any((field) => data.containsKey(field.id) && data[field.id] != null);

    if (!hasData) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (section.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(
                  section.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            const Divider(),
            const SizedBox(height: 8),
            ...sortedFields.where((field) {
              return data.containsKey(field.id) && data[field.id] != null;
            }).map((field) {
              return _buildFieldDisplay(field, data[field.id]);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldDisplay(AnamnesisField field, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.offBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatValue(value, field.type),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value, AnamnesisFieldType type) {
    if (value == null) return 'Não informado';

    switch (type) {
      case AnamnesisFieldType.boolean:
        return value == true ? 'Sim' : 'Não';
      case AnamnesisFieldType.date:
        if (value is String) {
          final date = DateTime.tryParse(value);
          if (date != null) {
            return '${date.day}/${date.month}/${date.year}';
          }
        }
        return value.toString();
      case AnamnesisFieldType.slider:
      case AnamnesisFieldType.rating:
        return value.toString();
      case AnamnesisFieldType.checkboxGroup:
        if (value is List) {
          return value.join(', ');
        }
        return value.toString();
      default:
        return value.toString();
    }
  }

  Widget _buildRawDataCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dados da Anamnese',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...data.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.value?.toString() ?? 'Não informado',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

