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

  @override
  void initState() {
    super.initState();
    _healthInsuranceController = TextEditingController(
      text: widget.initialData?.healthInsurance ?? '',
    );
    _insuranceNumberController = TextEditingController(
      text: widget.initialData?.insuranceNumber ?? '',
    );

    _healthInsuranceController.addListener(_notifyDataChanged);
    _insuranceNumberController.addListener(_notifyDataChanged);
  }

  @override
  void dispose() {
    _healthInsuranceController.dispose();
    _insuranceNumberController.dispose();
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
                    'Informações sobre medicações, alergias e histórico médico podem ser registradas na anamnese do paciente.',
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
