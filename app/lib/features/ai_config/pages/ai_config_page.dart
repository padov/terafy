import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/ai_config/cubit/ai_config_cubit.dart';
import 'package:terafy/features/ai_config/models/therapist_profile_model.dart';

class AiConfigPage extends StatelessWidget {
  const AiConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AiConfigCubit(therapistRepository: DependencyContainer().therapistRepository)..loadProfile(),
      child: const _AiConfigPageContent(),
    );
  }
}

class _AiConfigPageContent extends StatefulWidget {
  const _AiConfigPageContent();

  @override
  State<_AiConfigPageContent> createState() => _AiConfigPageContentState();
}

class _AiConfigPageContentState extends State<_AiConfigPageContent> {
  int _currentStep = 0;
  // Local state for immediate UI feedback, will be synced with Cubit on load
  TherapistProfileModel _profile = const TherapistProfileModel();
  String? _experienceTime;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AiConfigCubit, AiConfigState>(
      listener: (context, state) {
        if (state.status == AiConfigStatus.loaded) {
          setState(() {
            _profile = state.profile;
            _experienceTime = state.experienceTime;
          });
        } else if (state.status == AiConfigStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil de IA salvo com sucesso!')));
          Navigator.of(context).pop();
        } else if (state.status == AiConfigStatus.error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage ?? 'Erro desconhecido')));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Configuração de IA', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: BlocBuilder<AiConfigCubit, AiConfigState>(
          builder: (context, state) {
            if (state.status == AiConfigStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Os dados fornecidos neste formulário serão utilizados pela IA para personalizar as análises e sugestões de acordo com seu perfil profissional e abordagem terapêutica.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stepper(
                    key: ValueKey(_currentStep),
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    controlsBuilder: (context, details) {
                      final isSaving = state.status == AiConfigStatus.saving;
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSaving ? null : details.onStepContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(_currentStep == 4 ? 'Concluir' : 'Próximo'),
                              ),
                            ),
                            if (_currentStep > 0) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isSaving ? null : details.onStepCancel,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: Colors.grey),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Voltar', style: TextStyle(color: Colors.grey)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    steps: [_buildStep1(), _buildStep2(), _buildStep3(), _buildStep4(), _buildStep5()],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      context.read<AiConfigCubit>().saveProfile(profile: _profile, experienceTime: _experienceTime);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  // --- Step Builders ---

  Step _buildStep1() {
    return Step(
      title: const Text('Abordagem Terapêutica'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildSectionHeader('Identificação Profissional'),
          _buildTextField(
            label: 'Tempo de Experiência',
            hint: 'Ex: 10 anos',
            value: _experienceTime ?? '',
            onChanged: (v) => setState(() => _experienceTime = v),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Abordagem Terapêutica'),
          _buildMultiSelect(
            label: 'Abordagem(ns) Principal(is)',
            options: [
              'Psicanálise',
              'TCC',
              'Psicodrama',
              'Gestalt-terapia',
              'Humanista',
              'Sistêmica',
              'EMDR',
              'ACT',
              'DBT',
              'Terapia Breve',
              'Integrativa',
            ],
            selectedValues: _profile.approaches,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(approaches: v)),
          ),
          _buildTextArea(
            label: 'Descrição da Abordagem',
            hint: 'Descreva sua abordagem com suas próprias palavras...',
            value: _profile.approachDescription,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(approachDescription: v)),
          ),
        ],
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text('Princípios e Crenças'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildSectionHeader('Princípios Terapêuticos'),
          _buildTextArea(
            label: 'Visão sobre mudança terapêutica',
            hint: 'Como você acredita que a mudança acontece?',
            value: _profile.changeVision,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(changeVision: v)),
          ),
          _buildDropdown(
            label: 'Postura Terapêutica',
            options: ['Diretiva', 'Não-diretiva', 'Mista'],
            value: _profile.therapeuticPosture.isNotEmpty ? _profile.therapeuticPosture : null,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(therapeuticPosture: v)),
          ),
          _buildTextArea(
            label: 'Papel do Terapeuta',
            hint: 'Como você se vê no processo?',
            value: _profile.therapistRole,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(therapistRole: v)),
          ),
          _buildDropdown(
            label: 'Importância do Vínculo',
            options: ['Fundamental', 'Importante', 'Contextual'],
            value: _profile.bondImportance.isNotEmpty ? _profile.bondImportance : null,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(bondImportance: v)),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Crenças sobre Saúde Mental'),
          _buildTextArea(
            label: 'Natureza do sofrimento psíquico',
            hint: 'Como você entende o sofrimento humano?',
            value: _profile.sufferingNature,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(sufferingNature: v)),
          ),
          _buildTextArea(
            label: 'Potencial de mudança',
            hint: 'Até onde as pessoas podem mudar?',
            value: _profile.changePotential,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(changePotential: v)),
          ),
          _buildDropdown(
            label: 'Papel da Medicação',
            options: ['Favorável', 'Contextual', 'Conservador', 'Integrada'],
            value: _profile.medicationView.isNotEmpty ? _profile.medicationView : null,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(medicationView: v)),
          ),
          _buildTextArea(
            label: 'Visão sobre "Cura"',
            hint: 'Como você define a cura?',
            value: _profile.cureView,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(cureView: v)),
          ),
        ],
      ),
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text('Prática Clínica'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildSectionHeader('Foco Terapêutico'),
          _buildMultiSelect(
            label: 'Prioridades das Sessões',
            options: [
              'Exploração do inconsciente',
              'Pensamentos automáticos',
              'Emoções no aqui-agora',
              'Mudança comportamental',
              'Insight e autoconhecimento',
              'Resolução de problemas',
              'Habilidades',
              'Traumas',
              'Recursos internos',
              'Relações',
            ],
            selectedValues: _profile.sessionPriorities,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(sessionPriorities: v)),
          ),
          _buildTextArea(
            label: 'Áreas de maior interesse clínico',
            hint: 'Quais temas/queixas você tem mais experiência ou interesse?',
            value: _profile.interestAreas,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(interestAreas: v)),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Metodologia'),
          _buildDropdown(
            label: 'Formato da Sessão',
            options: ['Estruturada', 'Semi-estruturada', 'Livre'],
            value: _profile.sessionFormat.isNotEmpty ? _profile.sessionFormat : null,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(sessionFormat: v)),
          ),
          _buildTextArea(
            label: 'Técnicas Frequentes',
            hint: 'Quais técnicas você usa com mais frequência?',
            value: _profile.frequentTechniques,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(frequentTechniques: v)),
          ),
          _buildDropdown(
            label: 'Frequência Recomendada',
            options: ['Semanal', 'Quinzenal', 'Varia', 'Intensiva'],
            value: _profile.recommendedFrequency.isNotEmpty ? _profile.recommendedFrequency : null,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(recommendedFrequency: v)),
          ),
          _buildTextArea(
            label: 'Duração Típica',
            hint: 'Qual sua expectativa de duração?',
            value: _profile.typicalDuration,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(typicalDuration: v)),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Estilo Comunicacional'),
          _buildDropdown(
            label: 'Tom Predominante',
            options: ['Acolhedor', 'Direto', 'Questionador', 'Educativo', 'Misto'],
            value: _profile.communicationTone.isNotEmpty ? _profile.communicationTone : null,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(communicationTone: v)),
          ),
          _buildDropdown(
            label: 'Uso de Humor',
            options: ['Sim', 'Raramente', 'Evito', 'Depende'],
            value: _profile.humorUsage.isNotEmpty ? _profile.humorUsage : null,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(humorUsage: v)),
          ),
        ],
      ),
    );
  }

  Step _buildStep4() {
    return Step(
      title: const Text('Avaliação e Manejo'),
      isActive: _currentStep >= 3,
      state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildSectionHeader('Avaliação e Diagnóstico'),
          _buildDropdown(
            label: 'Uso de Diagnósticos (CID/DSM)',
            options: ['Sempre', 'Quando necessário', 'Evito rótulos', 'Apenas organização'],
            value: _profile.diagnosisUsage.isNotEmpty ? _profile.diagnosisUsage : null,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(diagnosisUsage: v)),
          ),
          _buildTextArea(
            label: 'Elementos na Avaliação',
            hint: 'O que você observa/investiga prioritariamente?',
            value: _profile.evaluationElements,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(evaluationElements: v)),
          ),
          _buildTextArea(
            label: 'Indicadores de Progresso',
            hint: 'Como você sabe que a terapia está funcionando?',
            value: _profile.progressIndicators,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(progressIndicators: v)),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Manejo de Situações'),
          _buildTextArea(
            label: 'Resistência Terapêutica',
            hint: 'Como você lida com resistência terapêutica?',
            value: _profile.resistanceHandling,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(resistanceHandling: v)),
          ),
          _buildTextArea(
            label: 'Crises e Emergências',
            hint: 'Como você lida com crises e emergências?',
            value: _profile.crisisHandling,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(crisisHandling: v)),
          ),
          _buildTextArea(
            label: 'Estagnação no Processo',
            hint: 'Como você lida com estagnação no processo?',
            value: _profile.stagnationHandling,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(stagnationHandling: v)),
          ),
          _buildTextArea(
            label: 'Término Terapêutico',
            hint: 'Como você planeja o término do processo terapêutico?',
            value: _profile.terminationHandling,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(terminationHandling: v)),
          ),
        ],
      ),
    );
  }

  Step _buildStep5() {
    return Step(
      title: const Text('Configuração da IA'),
      isActive: _currentStep >= 4,
      state: StepState.complete,
      content: Column(
        children: [
          _buildSectionHeader('Instruções para a IA'),
          _buildTextArea(
            label: 'Foco da Análise',
            hint: 'O que você quer que a IA priorize?',
            value: _profile.aiAnalysisFocus,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(aiAnalysisFocus: v)),
          ),
          _buildDropdown(
            label: 'Tom da IA',
            options: ['Colaborativo', 'Objetivo', 'Questionador', 'Educativo'],
            value: _profile.aiTone.isNotEmpty ? _profile.aiTone : null,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(aiTone: v)),
          ),
          _buildTextArea(
            label: 'Alertas Importantes',
            hint: 'Sobre o que você quer ser sempre alertado?',
            value: _profile.aiAlerts,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(aiAlerts: v)),
          ),
          _buildMultiSelect(
            label: 'Sugestões Desejadas',
            options: ['Técnicas', 'Literatura', 'Diagnósticos', 'Questões', 'Encaminhamentos', 'Manejo'],
            selectedValues: _profile.aiSuggestionsDesired,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(aiSuggestionsDesired: v)),
          ),
          _buildDropdown(
            label: 'Formato de Resposta',
            options: ['Resumo executivo', 'Análise detalhada', 'Misto', 'Perguntas reflexivas'],
            value: _profile.aiResponseFormat.isNotEmpty ? _profile.aiResponseFormat : null,
            onChanged: (v) => setState(() => _profile = _profile.copyWith(aiResponseFormat: v)),
          ),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.offBlack),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelect({
    required String label,
    required List<String> options,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: options.map((option) {
                final isSelected = selectedValues.contains(option);
                return CheckboxListTile(
                  title: Text(option),
                  value: isSelected,
                  activeColor: AppColors.primary,
                  onChanged: (checked) {
                    final newValues = List<String>.from(selectedValues);
                    if (checked == true) {
                      newValues.add(option);
                    } else {
                      newValues.remove(option);
                    }
                    onChanged(newValues);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
