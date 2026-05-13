import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc_models.dart';
import 'package:terafy/features/subscription/bloc/subscription_bloc.dart';
import 'package:terafy/features/subscription/bloc/subscription_bloc_models.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_template.dart';
import 'package:terafy/features/anamnesis/pages/template_editor_page.dart';

class MyTemplatesPage extends StatelessWidget {
  const MyTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AnamnesisBloc(
            anamnesisRepository: DependencyContainer().anamnesisRepository,
            templateRepository: DependencyContainer().anamnesisTemplateRepository,
          )..add(const LoadTemplates(isSystem: false)),
        ),
        BlocProvider(
          create: (context) =>
              SubscriptionBloc(repository: DependencyContainer().subscriptionRepository)
                ..add(const LoadSubscriptionStatus()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Modelos'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const _MyTemplatesContent(),
        floatingActionButton: BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, subscriptionState) {
            final hasReachedLimit = subscriptionState.subscriptionStatus?.usage.canCreateAnamnesis == false;

            return FloatingActionButton.extended(
              onPressed: () {
                if (hasReachedLimit) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Limite do plano atingido. Faça upgrade para criar mais modelos.'),
                      backgroundColor: Colors.amber,
                    ),
                  );
                  return;
                }
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TemplateEditorPage())).then((_) {
                  if (context.mounted) {
                    context.read<AnamnesisBloc>().add(const LoadTemplates(isSystem: false));
                  }
                });
              },
              label: const Text('Novo Modelo'),
              icon: const Icon(Icons.add),
              backgroundColor: hasReachedLimit ? Colors.grey : AppColors.primary,
            );
          },
        ),
      ),
    );
  }
}

class _MyTemplatesContent extends StatelessWidget {
  const _MyTemplatesContent();

  void _showDeleteConfirmation(BuildContext context, AnamnesisTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Modelo'),
        content: Text('Tem certeza que deseja excluir o modelo "${template.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              context.read<AnamnesisBloc>().add(DeleteTemplate(template.id));
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AnamnesisBloc, AnamnesisState>(
      listener: (context, state) {
        if (state is TemplateOperationSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
          // Reload templates
          context.read<AnamnesisBloc>().add(const LoadTemplates(isSystem: false));
        } else if (state is AnamnesisError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: BlocBuilder<AnamnesisBloc, AnamnesisState>(
        builder: (context, state) {
          if (state is AnamnesisLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AnamnesisError) {
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
                      context.read<AnamnesisBloc>().add(const LoadTemplates(isSystem: false));
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (state is TemplatesLoaded) {
            if (state.templates.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Você ainda não criou nenhum modelo.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie modelos personalizados para suas necessidades.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
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
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: const Icon(Icons.edit_document, color: Colors.orange),
                    ),
                    title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      template.description ?? 'Sem descrição',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!template.isSystem)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TemplateEditorPage(templateToEdit: template)),
                              ).then((_) {
                                if (context.mounted) {
                                  context.read<AnamnesisBloc>().add(const LoadTemplates(isSystem: false));
                                }
                              });
                            },
                          ),
                        if (!template.isSystem)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteConfirmation(context, template);
                            },
                          ),
                        if (template.isSystem)
                          const Tooltip(
                            message: 'Modelo padrão do sistema',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
