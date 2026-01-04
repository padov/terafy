import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc_models.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_template.dart';
import 'package:terafy/features/anamnesis/pages/anamnesis_form_page.dart';
import 'package:terafy/features/anamnesis/pages/my_templates_page.dart';

class TemplateSelectionPage extends StatelessWidget {
  final bool isInviteMode; // New parameter to control mode
  final String patientId;
  final String therapistId;

  const TemplateSelectionPage({
    super.key,
    required this.patientId,
    required this.therapistId,
    this.isInviteMode = false,
  });

  void _onTemplateSelected(BuildContext context, AnamnesisTemplate template) {
    if (isInviteMode) {
      // In invite mode, we trigger the creation of the invite
      context.read<AnamnesisBloc>().add(CreateInvite(patientId: patientId, templateId: template.id));
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnamnesisFormPage(patientId: patientId, therapistId: therapistId, template: template),
        ),
      );
    }
  }

  void _showInviteDialog(BuildContext context, String link) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Convite Gerado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Envie o link abaixo para o paciente preencher a anamnese:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(link, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              // Buttons using Wrap to avoid infinite width constraints
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Link copiado para a área de transferência!')));
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Share.share('Olá! Por favor preencha sua anamnese através deste link: $link');
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Close only the dialog. If you need to also close the template selection page,
              // do it after the dialog is dismissed (e.g., in the then() callback).
              Navigator.of(context).pop();
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnamnesisBloc(
        anamnesisRepository: DependencyContainer().anamnesisRepository,
        templateRepository: DependencyContainer().anamnesisTemplateRepository,
      )..add(const LoadTemplates()),
      child: BlocListener<AnamnesisBloc, AnamnesisState>(
        listener: (context, state) {
          if (state is InviteCreated) {
            _showInviteDialog(context, state.link);
          } else if (state is AnamnesisError && isInviteMode) {
            // Show error only if we originated it
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(isInviteMode ? 'Enviar Anamnese' : 'Selecionar Modelo'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MyTemplatesPage())).then((_) {
                    // Reload templates after returning from management page
                    if (context.mounted) {
                      context.read<AnamnesisBloc>().add(const LoadTemplates());
                    }
                  });
                },
                icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                label: const Text('Gerenciar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          body: BlocBuilder<AnamnesisBloc, AnamnesisState>(
            builder: (context, state) {
              if (state is AnamnesisLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is AnamnesisError && !isInviteMode) {
                // Avoid masking list with error if it was an invite error (handled in listener)
                // But wait, LoadTemplates error also comes here.
                // Ideally split states, but for now assuming if templates are empty it's a load error or empty.
              }

              if (state is AnamnesisError) {
                // If we have templates loaded but got an error (e.g. invite creation),
                // we might want to still show the list.
                // But Bloc emits new state replacing old state.
                // So if CreateInvite fails, state becomes AnamnesisError and list is lost.
                // We should reload templates or handle error differently.
                // For simplicity: verify if we have templates in previous state or just show error with retry.
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<AnamnesisBloc>().add(const LoadTemplates());
                        },
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                );
              }

              if (state is TemplatesLoaded) {
                if (state.templates.isEmpty) {
                  return const Center(child: Text('Nenhum modelo de anamnese disponível.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.templates.length,
                  itemBuilder: (context, index) {
                    final template = state.templates[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            template.isSystem ? Icons.assignment : Icons.edit_document,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          template.description ?? 'Sem descrição',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _onTemplateSelected(context, template),
                      ),
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
