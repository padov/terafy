import 'package:flutter/material.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/patients/registration/bloc/patient_registration_models.dart';

class Step4Health extends StatefulWidget {
  final HealthData? initialData;
  final Function(HealthData) onDataChanged;

  const Step4Health({super.key, this.initialData, required this.onDataChanged});

  @override
  State<Step4Health> createState() => _Step4HealthState();
}

class _Step4HealthState extends State<Step4Health> {
  late TextEditingController _healthInsuranceController;
  late TextEditingController _insuranceNumberController;
  late TextEditingController _medicationsController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _psychiatricHistoryController;

  @override
  void initState() {
    super.initState();
    _healthInsuranceController = TextEditingController(
      text: widget.initialData?.healthInsurance ?? '',
    );
    _insuranceNumberController = TextEditingController(
      text: widget.initialData?.insuranceNumber ?? '',
    );
    _medicationsController = TextEditingController(
      text: widget.initialData?.currentMedications ?? '',
    );
    _allergiesController = TextEditingController(
      text: widget.initialData?.allergies ?? '',
    );
    _medicalHistoryController = TextEditingController(
      text: widget.initialData?.medicalHistory ?? '',
    );
    _psychiatricHistoryController = TextEditingController(
      text: widget.initialData?.psychiatricHistory ?? '',
    );

    _healthInsuranceController.addListener(_notifyDataChanged);
    _insuranceNumberController.addListener(_notifyDataChanged);
    _medicationsController.addListener(_notifyDataChanged);
    _allergiesController.addListener(_notifyDataChanged);
    _medicalHistoryController.addListener(_notifyDataChanged);
    _psychiatricHistoryController.addListener(_notifyDataChanged);
  }

  @override
  void dispose() {
    _healthInsuranceController.dispose();
    _insuranceNumberController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _medicalHistoryController.dispose();
    _psychiatricHistoryController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    final data = HealthData(
      healthInsurance: _healthInsuranceController.text.isEmpty
          ? null
          : _healthInsuranceController.text,
      insuranceNumber: _insuranceNumberController.text.isEmpty
          ? null
          : _insuranceNumberController.text,
      currentMedications: _medicationsController.text.isEmpty
          ? null
          : _medicationsController.text,
      allergies: _allergiesController.text.isEmpty
          ? null
          : _allergiesController.text,
      medicalHistory: _medicalHistoryController.text.isEmpty
          ? null
          : _medicalHistoryController.text,
      psychiatricHistory: _psychiatricHistoryController.text.isEmpty
          ? null
          : _psychiatricHistoryController.text,
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
            'Informações de Saúde',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dados médicos e histórico de saúde',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Convênio/Plano de Saúde
          _buildLabel('Convênio/Plano de Saúde'),
          TextFormField(
            controller: _healthInsuranceController,
            decoration: _buildInputDecoration(
              hintText: 'Ex: Unimed, SulAmérica, Particular...',
              icon: Icons.medical_services_outlined,
            ),
          ),
          const SizedBox(height: 20),

          // Número da Carteirinha
          _buildLabel('Número da Carteirinha'),
          TextFormField(
            controller: _insuranceNumberController,
            decoration: _buildInputDecoration(
              hintText: 'Digite o número da carteirinha',
              icon: Icons.credit_card,
            ),
          ),
          const SizedBox(height: 32),

          // Seção Medicamentos
          _buildSectionTitle('Medicamentos e Alergias'),
          const SizedBox(height: 16),

          _buildLabel('Medicações em Uso'),
          Text(
            'Liste os medicamentos que o paciente usa atualmente',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _medicationsController,
            decoration: _buildInputDecoration(
              hintText: 'Ex: Sertralina 50mg (manhã), Rivotril 2mg (noite)...',
              icon: Icons.medication_outlined,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          _buildLabel('Alergias'),
          Text(
            'Alergias a medicamentos, alimentos, etc.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _allergiesController,
            decoration: _buildInputDecoration(
              hintText: 'Ex: Dipirona, Penicilina, Frutos do mar...',
              icon: Icons.warning_amber_outlined,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          // Seção Históricos
          _buildSectionTitle('Histórico Médico'),
          const SizedBox(height: 16),

          _buildLabel('Histórico Médico Geral'),
          Text(
            'Doenças, cirurgias, internações, etc.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _medicalHistoryController,
            decoration: _buildInputDecoration(
              hintText: 'Descreva o histórico médico relevante...',
              icon: Icons.local_hospital_outlined,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          _buildLabel('Histórico Psiquiátrico'),
          Text(
            'Diagnósticos anteriores, tratamentos, internações',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _psychiatricHistoryController,
            decoration: _buildInputDecoration(
              hintText: 'Descreva o histórico psiquiátrico relevante...',
              icon: Icons.psychology_outlined,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          // Nota informativa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estas informações são importantes para um atendimento seguro e adequado.',
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
