import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc_models.dart';
import 'package:terafy/features/anamnesis/models/anamnesis.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_template.dart';
import 'package:terafy/features/anamnesis/widgets/anamnesis_section_widget.dart';

class AnamnesisFormPage extends StatefulWidget {
  final String patientId;
  final String therapistId;
  final AnamnesisTemplate? template;
  final Anamnesis? existingAnamnesis;

  const AnamnesisFormPage({
    super.key,
    required this.patientId,
    required this.therapistId,
    this.template,
    this.existingAnamnesis,
  });

  @override
  State<AnamnesisFormPage> createState() => _AnamnesisFormPageState();
}

class _AnamnesisFormPageState extends State<AnamnesisFormPage> {
  AnamnesisTemplate? _selectedTemplate;
  Map<String, dynamic> _formData = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    if (widget.existingAnamnesis != null) {
      _formData = Map<String, dynamic>.from(widget.existingAnamnesis!.data);
      if (widget.existingAnamnesis!.templateId != null) {
        // Carrega template se houver
        try {
          final container = DependencyContainer();
          final template = await container.anamnesisTemplateRepository.fetchTemplateById(
            widget.existingAnamnesis!.templateId!,
          );
          if (mounted) {
            setState(() {
              _selectedTemplate = template;
              _isInitialized = true;
            });
          }
          return;
        } catch (e) {
          // Se não conseguir carregar o template, continua sem template
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }
          return;
        }
      }
    }

    if (widget.template != null) {
      setState(() {
        _selectedTemplate = widget.template;
        _isInitialized = true;
      });
      return;
    }

    // Se não tem template passado, precisa carregar via BLoC
    // O BLoC será gerenciado pelo BlocBuilder abaixo
    setState(() {
      _isInitialized = true;
    });
  }

  void _updateSectionData(Map<String, dynamic> sectionData) {
    setState(() {
      _formData.addAll(sectionData);
    });
  }

  void _saveAnamnesis(BuildContext context) {
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template não selecionado')));
      return;
    }

    final bloc = context.read<AnamnesisBloc>();

    if (widget.existingAnamnesis != null) {
      // Atualiza anamnese existente
      final updated = widget.existingAnamnesis!.copyWith(data: _formData, updatedAt: DateTime.now());

      bloc.add(UpdateAnamnesis(id: widget.existingAnamnesis!.id, anamnesis: updated));
    } else {
      // Cria nova anamnese
      final newAnamnesis = Anamnesis(
        id: '',
        patientId: widget.patientId,
        therapistId: widget.therapistId,
        templateId: _selectedTemplate!.id,
        data: _formData,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bloc.add(CreateAnamnesis(newAnamnesis));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se já tem template definido, não precisa do BLoC para carregar templates
    if (_selectedTemplate != null || widget.template != null || widget.existingAnamnesis != null) {
      return BlocProvider(
        create: (context) => AnamnesisBloc(
          anamnesisRepository: DependencyContainer().anamnesisRepository,
          templateRepository: DependencyContainer().anamnesisTemplateRepository,
        ),
        child: _buildScaffold(),
      );
    }

    // Precisa carregar templates
    return BlocProvider(
      create: (context) => AnamnesisBloc(
        anamnesisRepository: DependencyContainer().anamnesisRepository,
        templateRepository: DependencyContainer().anamnesisTemplateRepository,
      )..add(const LoadTemplates()),
      child: BlocBuilder<AnamnesisBloc, AnamnesisState>(
        builder: (context, state) {
          if (state is AnamnesisLoading) {
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.existingAnamnesis != null ? 'Editar Anamnese' : 'Nova Anamnese'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state is TemplatesLoaded) {
            if (state.templates.isEmpty) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Nova Anamnese'),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum template disponível',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'É necessário criar um template de anamnese antes de criar uma anamnese.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Seleciona o primeiro template disponível
            if (_selectedTemplate == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _selectedTemplate = state.templates.first;
                });
              });
            }
          }

          if (state is AnamnesisError) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Nova Anamnese'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(state.message, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<AnamnesisBloc>().add(const LoadTemplates());
                        },
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return _buildScaffold();
        },
      ),
    );
  }

  Widget _buildScaffold() {
    return BlocListener<AnamnesisBloc, AnamnesisState>(
      listener: (context, state) {
        if (state is AnamnesisSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        } else if (state is AnamnesisError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(widget.existingAnamnesis != null ? 'Editar Anamnese' : 'Nova Anamnese'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: !_isInitialized
              ? const Center(child: CircularProgressIndicator())
              : _selectedTemplate == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum template disponível',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'É necessário criar um template de anamnese antes de criar uma anamnese.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _buildForm(),
          floatingActionButton: _selectedTemplate != null
              ? FloatingActionButton.extended(
                  onPressed: () => _saveAnamnesis(context),
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Salvar', style: TextStyle(color: Colors.white)),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildForm() {
    if (_selectedTemplate == null) return const SizedBox.shrink();

    final sortedSections = List.from(_selectedTemplate!.sections)..sort((a, b) => a.order.compareTo(b.order));

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
                  Text(
                    _selectedTemplate!.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  if (_selectedTemplate!.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _selectedTemplate!.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seções
          ...sortedSections.map((section) {
            return AnamnesisSectionWidget(section: section, data: _formData, onDataChanged: _updateSectionData);
          }).toList(),

          const SizedBox(height: 100), // Espaço para o FAB
        ],
      ),
    );
  }
}
