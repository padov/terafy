import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc_models.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_template.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_section.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_field.dart';

class TemplateEditorPage extends StatefulWidget {
  final AnamnesisTemplate? templateToEdit;

  const TemplateEditorPage({super.key, this.templateToEdit});

  @override
  State<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<TemplateEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<AnamnesisSection> _sections;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.templateToEdit?.name ?? '');
    _descriptionController = TextEditingController(text: widget.templateToEdit?.description ?? '');
    _sections = widget.templateToEdit?.sections != null ? List.from(widget.templateToEdit!.sections) : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTemplate(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (_sections.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Adicione pelo menos uma seção ao modelo.')));
      return;
    }

    final newTemplate = AnamnesisTemplate(
      id: widget.templateToEdit?.id ?? '', // ID vazio para novos
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      sections: _sections,
      isDefault: false,
      isSystem: false,
    );

    final bloc = context.read<AnamnesisBloc>();
    if (widget.templateToEdit != null) {
      bloc.add(UpdateTemplate(id: widget.templateToEdit!.id, template: newTemplate));
    } else {
      bloc.add(CreateTemplate(newTemplate));
    }
  }

  void _addSection() {
    _showSectionDialog();
  }

  void _editSection(int index) {
    _showSectionDialog(section: _sections[index], index: index);
  }

  void _removeSection(int index) {
    setState(() {
      _sections.removeAt(index);
    });
  }

  void _showSectionDialog({AnamnesisSection? section, int? index}) {
    final titleController = TextEditingController(text: section?.title ?? '');
    final descController = TextEditingController(text: section?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(section == null ? 'Nova Seção' : 'Editar Seção'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título da Seção', hintText: 'Ex: Dados Familiares'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descrição (Opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;

              final newSection = AnamnesisSection(
                id: section?.id ?? 'section_${DateTime.now().millisecondsSinceEpoch}',
                title: titleController.text.trim(),
                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                order: section?.order ?? _sections.length + 1,
                fields: section?.fields ?? [],
              );

              setState(() {
                if (index != null) {
                  _sections[index] = newSection;
                } else {
                  _sections.add(newSection);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _addField(int sectionIndex) {
    _showFieldDialog(sectionIndex: sectionIndex);
  }

  void _editField(int sectionIndex, int fieldIndex) {
    _showFieldDialog(
      sectionIndex: sectionIndex,
      fieldIndex: fieldIndex,
      field: _sections[sectionIndex].fields[fieldIndex],
    );
  }

  void _showFieldDialog({AnamnesisField? field, required int sectionIndex, int? fieldIndex}) {
    final labelController = TextEditingController(text: field?.label ?? '');
    AnamnesisFieldType selectedType = field?.type ?? AnamnesisFieldType.text;
    bool isRequired = field?.required ?? false;
    List<String> options = field?.options != null ? field!.options!.map((e) => e['label'] ?? '').toList() : [];
    final optionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(field == null ? 'Novo Campo' : 'Editar Campo'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(labelText: 'Nome do Campo'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AnamnesisFieldType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Tipo de Resposta'),
                      items: AnamnesisFieldType.values
                          .map((type) => DropdownMenuItem(value: type, child: Text(type.name.toUpperCase())))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setStateDialog(() => selectedType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Obrigatório'),
                      value: isRequired,
                      onChanged: (val) => setStateDialog(() => isRequired = val),
                    ),

                    if (selectedType == AnamnesisFieldType.select || selectedType == AnamnesisFieldType.radio) ...[
                      const Divider(),
                      const Text('Opções', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...options.asMap().entries.map(
                        (entry) => ListTile(
                          title: Text(entry.value),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setStateDialog(() => options.removeAt(entry.key)),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: optionController,
                              decoration: const InputDecoration(hintText: 'Nova opção'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (optionController.text.isNotEmpty) {
                                setStateDialog(() {
                                  options.add(optionController.text.trim());
                                  optionController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  if (labelController.text.isEmpty) return;

                  // Create/Update field
                  final newField = AnamnesisField(
                    id: field?.id ?? 'field_${DateTime.now().millisecondsSinceEpoch}',
                    label: labelController.text.trim(),
                    type: selectedType,
                    required: isRequired,
                    options: options.isNotEmpty ? options.map((e) => {'label': e, 'value': e}).toList() : null,
                    order: field?.order ?? _sections[sectionIndex].fields.length + 1,
                  );

                  setState(() {
                    final section = _sections[sectionIndex];
                    final fields = List<AnamnesisField>.from(section.fields);
                    if (fieldIndex != null) {
                      fields[fieldIndex] = newField;
                    } else {
                      fields.add(newField);
                    }
                    _sections[sectionIndex] = section.copyWith(fields: fields);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnamnesisBloc(
        anamnesisRepository: DependencyContainer().anamnesisRepository,
        templateRepository: DependencyContainer().anamnesisTemplateRepository,
      ),
      child: BlocConsumer<AnamnesisBloc, AnamnesisState>(
        listener: (context, state) {
          if (state is TemplateOperationSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
            Navigator.pop(context, true);
          } else if (state is AnamnesisError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          final isLoading = state is AnamnesisLoading;

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.templateToEdit == null ? 'Criar Modelo' : 'Editar Modelo'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              actions: [
                IconButton(icon: const Icon(Icons.check), onPressed: isLoading ? null : () => _saveTemplate(context)),
              ],
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do Modelo',
                              border: OutlineInputBorder(),
                              hintText: 'Ex: Anamnese Infantil',
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Informe o nome' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descrição (Opcional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Seções', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: _addSection,
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Adicionar Seção'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_sections.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text('Nenhuma seção adicionada', style: TextStyle(color: Colors.grey[600])),
                            )
                          else
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _sections.length,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  final item = _sections.removeAt(oldIndex);
                                  _sections.insert(newIndex, item);

                                  // Update order property
                                  for (var i = 0; i < _sections.length; i++) {
                                    _sections[i] = _sections[i].copyWith(order: i + 1);
                                  }
                                });
                              },
                              itemBuilder: (context, index) {
                                final section = _sections[index];
                                return Card(
                                  key: ValueKey(section.id),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ExpansionTile(
                                    title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${section.fields.length} campos'),
                                    leading: const Icon(Icons.drag_handle, color: Colors.grey),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          onPressed: () => _editSection(index),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () => _removeSection(index),
                                        ),
                                        const Icon(Icons.expand_more),
                                      ],
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ReorderableListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: section.fields.length,
                                              onReorder: (oldIndex, newIndex) {
                                                setState(() {
                                                  if (newIndex > oldIndex) newIndex -= 1;
                                                  final fields = List<AnamnesisField>.from(section.fields);
                                                  final item = fields.removeAt(oldIndex);
                                                  fields.insert(newIndex, item);

                                                  // Update order
                                                  final updatedFields = fields.asMap().entries.map((e) {
                                                    return e.value.copyWith(order: e.key + 1);
                                                  }).toList();

                                                  _sections[index] = section.copyWith(fields: updatedFields);
                                                });
                                              },
                                              itemBuilder: (context, fieldIndex) {
                                                final field = section.fields[fieldIndex];
                                                return ListTile(
                                                  key: ValueKey(field.id),
                                                  dense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                  leading: ReorderableDragStartListener(
                                                    index: fieldIndex,
                                                    child: const Padding(
                                                      padding: EdgeInsets.only(right: 8.0, left: 8.0),
                                                      child: Icon(Icons.drag_indicator, size: 20, color: Colors.grey),
                                                    ),
                                                  ),
                                                  title: Text(field.label + (field.required ? ' *' : '')),
                                                  subtitle: Text(field.type.name.toUpperCase()),
                                                  onTap: () => _editField(index, fieldIndex),
                                                  trailing: IconButton(
                                                    icon: const Icon(Icons.close, size: 16),
                                                    onPressed: () {
                                                      setState(() {
                                                        final updatedFields = List<AnamnesisField>.from(section.fields)
                                                          ..remove(field);
                                                        _sections[index] = section.copyWith(fields: updatedFields);
                                                      });
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            TextButton.icon(
                                              onPressed: () => _addField(index),
                                              icon: const Icon(Icons.add),
                                              label: const Text('Adicionar Campo'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
