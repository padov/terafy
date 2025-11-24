import 'package:flutter/material.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/patients/registration/bloc/patient_registration_models.dart';

class Step5Anamnesis extends StatefulWidget {
  final AnamnesisData? initialData;
  final Function(AnamnesisData) onDataChanged;

  const Step5Anamnesis({
    super.key,
    this.initialData,
    required this.onDataChanged,
  });

  @override
  State<Step5Anamnesis> createState() => _Step5AnamnesisState();
}

class _Step5AnamnesisState extends State<Step5Anamnesis> {
  late TextEditingController _chiefComplaintController;
  late TextEditingController _complaintHistoryController;
  late TextEditingController _expectationsController;
  late TextEditingController _familyHistoryController;
  late TextEditingController _sleepPatternController;
  late TextEditingController _dietController;
  late TextEditingController _physicalActivityController;

  int _complaintIntensity = 5;

  @override
  void initState() {
    super.initState();
    _chiefComplaintController = TextEditingController(
      text: widget.initialData?.chiefComplaint ?? '',
    );
    _complaintHistoryController = TextEditingController(
      text: widget.initialData?.complaintHistory ?? '',
    );
    _expectationsController = TextEditingController(
      text: widget.initialData?.expectations ?? '',
    );
    _familyHistoryController = TextEditingController(
      text: widget.initialData?.familyHistory ?? '',
    );
    _sleepPatternController = TextEditingController(
      text: widget.initialData?.sleepPattern ?? '',
    );
    _dietController = TextEditingController(
      text: widget.initialData?.diet ?? '',
    );
    _physicalActivityController = TextEditingController(
      text: widget.initialData?.physicalActivity ?? '',
    );
    _complaintIntensity = widget.initialData?.complaintIntensity ?? 5;

    _chiefComplaintController.addListener(_notifyDataChanged);
    _complaintHistoryController.addListener(_notifyDataChanged);
    _expectationsController.addListener(_notifyDataChanged);
    _familyHistoryController.addListener(_notifyDataChanged);
    _sleepPatternController.addListener(_notifyDataChanged);
    _dietController.addListener(_notifyDataChanged);
    _physicalActivityController.addListener(_notifyDataChanged);
  }

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _complaintHistoryController.dispose();
    _expectationsController.dispose();
    _familyHistoryController.dispose();
    _sleepPatternController.dispose();
    _dietController.dispose();
    _physicalActivityController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    final data = AnamnesisData(
      chiefComplaint: _chiefComplaintController.text.isEmpty
          ? null
          : _chiefComplaintController.text,
      complaintHistory: _complaintHistoryController.text.isEmpty
          ? null
          : _complaintHistoryController.text,
      complaintIntensity: _complaintIntensity,
      expectations: _expectationsController.text.isEmpty
          ? null
          : _expectationsController.text,
      familyHistory: _familyHistoryController.text.isEmpty
          ? null
          : _familyHistoryController.text,
      sleepPattern: _sleepPatternController.text.isEmpty
          ? null
          : _sleepPatternController.text,
      diet: _dietController.text.isEmpty ? null : _dietController.text,
      physicalActivity: _physicalActivityController.text.isEmpty
          ? null
          : _physicalActivityController.text,
    );
    widget.onDataChanged(data);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Anamnese',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Queixa principal e histórico do paciente',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Queixa Principal
          _buildSectionTitle('Motivo da Consulta'),
          const SizedBox(height: 16),

          _buildLabel('Queixa Principal'),
          Text(
            'Qual o motivo que trouxe o paciente à terapia?',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _chiefComplaintController,
            decoration: _buildInputDecoration(
              hintText:
                  'Ex: Ansiedade, depressão, dificuldades nos relacionamentos...',
              icon: Icons.comment_outlined,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          _buildLabel('História da Queixa'),
          Text(
            'Quando começou? O que desencadeou? Como evoluiu?',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _complaintHistoryController,
            decoration: _buildInputDecoration(
              hintText:
                  'Descreva como a queixa se desenvolveu ao longo do tempo...',
              icon: Icons.history,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          // Intensidade
          _buildLabel('Intensidade do Desconforto'),
          Text(
            'Numa escala de 0 (nenhum) a 10 (máximo)',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _complaintIntensity.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: _complaintIntensity.toString(),
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() => _complaintIntensity = value.toInt());
                    _notifyDataChanged();
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _complaintIntensity.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Expectativas
          _buildSectionTitle('Expectativas'),
          const SizedBox(height: 16),

          _buildLabel('O que espera do tratamento?'),
          TextFormField(
            controller: _expectationsController,
            decoration: _buildInputDecoration(
              hintText: 'Objetivos e expectativas para a terapia...',
              icon: Icons.flag_outlined,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),

          // Histórico Familiar
          _buildSectionTitle('Histórico Familiar'),
          const SizedBox(height: 16),

          _buildLabel('Histórico Familiar'),
          Text(
            'Doenças mentais na família, relacionamentos, dinâmica familiar',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _familyHistoryController,
            decoration: _buildInputDecoration(
              hintText: 'Descreva o histórico familiar relevante...',
              icon: Icons.family_restroom,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),

          // Hábitos de Vida
          _buildSectionTitle('Hábitos de Vida'),
          const SizedBox(height: 16),

          _buildLabel('Padrão de Sono'),
          TextFormField(
            controller: _sleepPatternController,
            decoration: _buildInputDecoration(
              hintText: 'Ex: Dorme 6h por noite, insônia, sono agitado...',
              icon: Icons.bedtime_outlined,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          _buildLabel('Alimentação'),
          TextFormField(
            controller: _dietController,
            decoration: _buildInputDecoration(
              hintText: 'Ex: Alimentação irregular, compulsão alimentar...',
              icon: Icons.restaurant_outlined,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          _buildLabel('Atividade Física'),
          TextFormField(
            controller: _physicalActivityController,
            decoration: _buildInputDecoration(
              hintText: 'Ex: Sedentário, pratica esportes 3x/semana...',
              icon: Icons.directions_run,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          // Nota informativa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estas informações ajudam a compreender melhor o caso e planejar o tratamento.',
                    style: TextStyle(fontSize: 13, color: AppColors.offBlack),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.offBlack,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(icon, color: Colors.grey[600]),
    );
  }
}
