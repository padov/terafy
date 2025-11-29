import 'package:flutter/material.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/patients/registration/bloc/patient_registration_models.dart';

class Step3ProfessionalSocial extends StatefulWidget {
  final ProfessionalSocialData? initialData;
  final Function(ProfessionalSocialData) onDataChanged;

  const Step3ProfessionalSocial({
    super.key,
    this.initialData,
    required this.onDataChanged,
  });

  @override
  State<Step3ProfessionalSocial> createState() =>
      _Step3ProfessionalSocialState();
}

class _Step3ProfessionalSocialState extends State<Step3ProfessionalSocial> {
  late TextEditingController _professionController;
  late TextEditingController _educationController;

  final List<String> _educationLevels = [
    'Fundamental Incompleto',
    'Fundamental Completo',
    'Médio Incompleto',
    'Médio Completo',
    'Superior Incompleto',
    'Superior Completo',
    'Pós-Graduação',
    'Mestrado',
    'Doutorado',
  ];

  @override
  void initState() {
    super.initState();
    _professionController = TextEditingController(
      text: widget.initialData?.profession ?? '',
    );
    _educationController = TextEditingController(
      text: widget.initialData?.education ?? '',
    );

    _professionController.addListener(_notifyDataChanged);
    _educationController.addListener(_notifyDataChanged);
  }

  @override
  void dispose() {
    _professionController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    final data = ProfessionalSocialData(
      profession: _professionController.text.isEmpty
          ? null
          : _professionController.text,
      education: _educationController.text.isEmpty
          ? null
          : _educationController.text,
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
            'Vida Profissional',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Informações sobre trabalho e estudos',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Profissão/Ocupação
          _buildLabel('Profissão/Ocupação'),
          TextFormField(
            controller: _professionController,
            decoration: _buildInputDecoration(
              hintText: 'Ex: Engenheiro, Estudante, Desempregado...',
              icon: Icons.work_outline,
            ),
          ),
          const SizedBox(height: 20),

          // Escolaridade
          _buildLabel('Escolaridade'),
          DropdownButtonFormField<String>(
            initialValue: _educationLevels.contains(_educationController.text)
                ? _educationController.text
                : null,
            decoration: _buildInputDecoration(
              hintText: 'Selecione o nível de escolaridade',
              icon: Icons.school,
            ),
            items: _educationLevels.map((level) {
              return DropdownMenuItem(value: level, child: Text(level));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _educationController.text = value ?? '';
                _notifyDataChanged();
              });
            },
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
                Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Todos os campos desta etapa são opcionais. Você pode preencher mais tarde.',
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
