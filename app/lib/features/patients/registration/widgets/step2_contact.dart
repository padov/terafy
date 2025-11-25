import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/patients/models/patient.dart';
import 'package:terafy/features/patients/registration/bloc/patient_registration_models.dart';

class Step2Contact extends StatefulWidget {
  final ContactData? initialData;
  final Function(ContactData) onDataChanged;
  final DateTime? dateOfBirth; // Para verificar se é menor de idade

  const Step2Contact({
    super.key,
    this.initialData,
    required this.onDataChanged,
    this.dateOfBirth,
  });

  @override
  State<Step2Contact> createState() => _Step2ContactState();
}

class _Step2ContactState extends State<Step2Contact> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  // Emergency Contact
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _emergencyRelationController;

  // Legal Guardian (if minor)
  late TextEditingController _guardianNameController;
  late TextEditingController _guardianCpfController;
  late TextEditingController _guardianPhoneController;

  bool _showGuardian = false;

  @override
  void initState() {
    super.initState();
    
    // Ativa o switch se já houver responsável legal ou se o paciente for menor de idade
    _showGuardian = widget.initialData?.legalGuardian != null || _isMinor();
    _phoneController = TextEditingController(
      text: widget.initialData?.phone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialData?.email ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initialData?.address ?? '',
    );

    _emergencyNameController = TextEditingController(
      text: widget.initialData?.emergencyContact?.name ?? '',
    );
    _emergencyPhoneController = TextEditingController(
      text: widget.initialData?.emergencyContact?.phone ?? '',
    );
    _emergencyRelationController = TextEditingController(
      text: widget.initialData?.emergencyContact?.relationship ?? '',
    );

    _guardianNameController = TextEditingController(
      text: widget.initialData?.legalGuardian?.name ?? '',
    );
    _guardianCpfController = TextEditingController(
      text: widget.initialData?.legalGuardian?.cpf ?? '',
    );
    _guardianPhoneController = TextEditingController(
      text: widget.initialData?.legalGuardian?.phone ?? '',
    );

    _phoneController.addListener(_notifyDataChanged);
    _emailController.addListener(_notifyDataChanged);
    _addressController.addListener(_notifyDataChanged);
    _emergencyNameController.addListener(_notifyDataChanged);
    _emergencyPhoneController.addListener(_notifyDataChanged);
    _emergencyRelationController.addListener(_notifyDataChanged);
    _guardianNameController.addListener(_notifyDataChanged);
    _guardianCpfController.addListener(_notifyDataChanged);
    _guardianPhoneController.addListener(_notifyDataChanged);
  }

  bool _isMinor() {
    if (widget.dateOfBirth == null) return false;
    final now = DateTime.now();
    int age = now.year - widget.dateOfBirth!.year;
    if (now.month < widget.dateOfBirth!.month ||
        (now.month == widget.dateOfBirth!.month && now.day < widget.dateOfBirth!.day)) {
      age--;
    }
    return age < 18;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _guardianNameController.dispose();
    _guardianCpfController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    EmergencyContact? emergencyContact;
    if (_emergencyNameController.text.isNotEmpty ||
        _emergencyPhoneController.text.isNotEmpty) {
      emergencyContact = EmergencyContact(
        name: _emergencyNameController.text,
        phone: _emergencyPhoneController.text,
        relationship: _emergencyRelationController.text,
      );
    }

    LegalGuardian? legalGuardian;
    if (_showGuardian && _guardianNameController.text.isNotEmpty) {
      legalGuardian = LegalGuardian(
        name: _guardianNameController.text,
        cpf: _guardianCpfController.text,
        phone: _guardianPhoneController.text,
      );
    }

    final data = ContactData(
      phone: _phoneController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      emergencyContact: emergencyContact,
      legalGuardian: legalGuardian,
    );

    widget.onDataChanged(data);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'Contato',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dados de contato e emergência',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Telefone *
            _buildLabel('Telefone', isRequired: true),
            TextFormField(
              controller: _phoneController,
              decoration: _buildInputDecoration(
                hintText: '(00) 00000-0000',
                icon: Icons.phone,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefone é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email
            _buildLabel('Email'),
            TextFormField(
              controller: _emailController,
              decoration: _buildInputDecoration(
                hintText: 'email@exemplo.com',
                icon: Icons.email,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Endereço
            _buildLabel('Endereço Completo'),
            TextFormField(
              controller: _addressController,
              decoration: _buildInputDecoration(
                hintText: 'Rua, número, bairro, cidade - UF',
                icon: Icons.location_on,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Seção - Contato de Emergência
            _buildSectionTitle('Contato de Emergência'),
            const SizedBox(height: 16),

            _buildLabel('Nome'),
            TextFormField(
              controller: _emergencyNameController,
              decoration: _buildInputDecoration(
                hintText: 'Nome do contato',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Telefone'),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: _buildInputDecoration(
                hintText: '(00) 00000-0000',
                icon: Icons.phone_outlined,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
            const SizedBox(height: 20),

            _buildLabel('Relação'),
            TextFormField(
              controller: _emergencyRelationController,
              decoration: _buildInputDecoration(
                hintText: 'Ex: Mãe, Pai, Cônjuge...',
                icon: Icons.family_restroom,
              ),
            ),
            const SizedBox(height: 32),

            // Toggle para Responsável Legal
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Paciente é menor de idade?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Adicionar dados do responsável legal'),
              value: _showGuardian,
              onChanged: (value) {
                setState(() => _showGuardian = value);
                _notifyDataChanged();
              },
              activeThumbColor: AppColors.primary,
            ),

            // Seção - Responsável Legal (se menor)
            if (_showGuardian) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Responsável Legal'),
              const SizedBox(height: 16),

              _buildLabel('Nome do Responsável'),
              TextFormField(
                controller: _guardianNameController,
                decoration: _buildInputDecoration(
                  hintText: 'Nome completo',
                  icon: Icons.person,
                ),
              ),
              const SizedBox(height: 20),

              _buildLabel('CPF do Responsável'),
              TextFormField(
                controller: _guardianCpfController,
                decoration: _buildInputDecoration(
                  hintText: '000.000.000-00',
                  icon: Icons.badge,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
              const SizedBox(height: 20),

              _buildLabel('Telefone do Responsável'),
              TextFormField(
                controller: _guardianPhoneController,
                decoration: _buildInputDecoration(
                  hintText: '(00) 00000-0000',
                  icon: Icons.phone,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
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

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.offBlack,
          ),
          children: isRequired
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ]
              : [],
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
