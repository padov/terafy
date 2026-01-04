import 'package:flutter/material.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_template.dart';
import 'package:terafy/features/anamnesis/widgets/anamnesis_section_widget.dart';

class PublicAnamnesisPage extends StatefulWidget {
  final String token;

  const PublicAnamnesisPage({super.key, required this.token});

  @override
  State<PublicAnamnesisPage> createState() => _PublicAnamnesisPageState();
}

class _PublicAnamnesisPageState extends State<PublicAnamnesisPage> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitted = false;

  AnamnesisTemplate? _template;
  String? _therapistName;
  String? _patientName;
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    try {
      final repository = DependencyContainer().anamnesisRepository;
      final contextData = await repository.getPublicInviteContext(widget.token);

      final templateJson = contextData['template'];
      if (templateJson != null) {
        _template = AnamnesisTemplate.fromJson(templateJson);
      }

      _therapistName = contextData['therapistName'];
      _patientName = contextData['patientName'];

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _submitForm() async {
    // Validate form (basic)
    if (_template == null) return;

    // Check required fields
    for (var section in _template!.sections) {
      for (var field in section.fields) {
        if (field.required &&
            (!_formData.containsKey(field.id) ||
                _formData[field.id] == null ||
                _formData[field.id].toString().isEmpty)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('O campo "${field.label}" é obrigatório.')));
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = DependencyContainer().anamnesisRepository;
      await repository.submitPublicInvite(widget.token, _formData);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSubmitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateSectionData(Map<String, dynamic> sectionData) {
    setState(() {
      _formData.addAll(sectionData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anamnese Online'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Don't show back button if simple page
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'Não foi possível carregar a anamnese.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_isSubmitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                'Anamnese enviada com sucesso!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Obrigado por preencher. Seu terapeuta já recebeu as informações.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_template == null) {
      return const Center(child: Text('Modelo de anamnese inválido.'));
    }

    final sortedSections = List.from(_template!.sections)..sort((a, b) => a.order.compareTo(b.order));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Limit width for web
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _template!.name,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      if (_patientName != null) ...[
                        const SizedBox(height: 8),
                        Text('Paciente: $_patientName', style: const TextStyle(fontSize: 16)),
                      ],
                      if (_therapistName != null) ...[
                        const SizedBox(height: 4),
                        Text('Terapeuta: $_therapistName', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                      if (_template!.description != null) ...[
                        const SizedBox(height: 16),
                        Text(_template!.description!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ...sortedSections.map((section) {
                return AnamnesisSectionWidget(section: section, data: _formData, onDataChanged: _updateSectionData);
              }),

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.send),
                label: const Text('ENVIAR ANAMNESE'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
