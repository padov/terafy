import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/patients/models/patient.dart';
import 'package:terafy/features/patients/registration/bloc/patient_registration_models.dart';

class Step1Identification extends StatefulWidget {
  final IdentificationData? initialData;
  final Function(IdentificationData) onDataChanged;

  const Step1Identification({super.key, this.initialData, required this.onDataChanged});

  @override
  State<Step1Identification> createState() => _Step1IdentificationState();
}

class _Step1IdentificationState extends State<Step1Identification> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _cpfController;
  late TextEditingController _rgController;
  DateTime? _selectedDate;
  Gender? _selectedGender;
  String? _selectedMaritalStatus;

  final List<String> _maritalStatusOptions = ['Solteiro(a)', 'Casado(a)', 'Divorciado(a)', 'Viúvo(a)', 'União Estável'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?.fullName ?? '');
    _cpfController = TextEditingController(text: widget.initialData?.cpf ?? '');
    _rgController = TextEditingController(text: widget.initialData?.rg ?? '');
    _selectedDate = widget.initialData?.dateOfBirth;
    _selectedGender = widget.initialData?.gender;
    _selectedMaritalStatus = widget.initialData?.maritalStatus;

    _nameController.addListener(_notifyDataChanged);
    _cpfController.addListener(_notifyDataChanged);
    _rgController.addListener(_notifyDataChanged);
  }

  @override
  void didUpdateWidget(Step1Identification oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Só atualiza os controllers se o valor mudou de uma fonte externa
    // (não durante digitação do usuário). Verifica se o valor atual do controller
    // não é um prefixo do novo valor E o novo valor não é um prefixo do atual
    final newFullName = widget.initialData?.fullName ?? '';
    if (widget.initialData?.fullName != oldWidget.initialData?.fullName &&
        _nameController.text != newFullName &&
        !newFullName.startsWith(_nameController.text) &&
        !_nameController.text.startsWith(newFullName)) {
      _nameController.text = newFullName;
    }

    final newCpf = widget.initialData?.cpf ?? '';
    if (widget.initialData?.cpf != oldWidget.initialData?.cpf &&
        _cpfController.text != newCpf &&
        !newCpf.startsWith(_cpfController.text) &&
        !_cpfController.text.startsWith(newCpf)) {
      _cpfController.text = newCpf;
    }

    final newRg = widget.initialData?.rg ?? '';
    if (widget.initialData?.rg != oldWidget.initialData?.rg &&
        _rgController.text != newRg &&
        !newRg.startsWith(_rgController.text) &&
        !_rgController.text.startsWith(newRg)) {
      _rgController.text = newRg;
    }

    if (widget.initialData?.dateOfBirth != oldWidget.initialData?.dateOfBirth) {
      _selectedDate = widget.initialData?.dateOfBirth;
    }
    if (widget.initialData?.gender != oldWidget.initialData?.gender) {
      _selectedGender = widget.initialData?.gender;
    }
    if (widget.initialData?.maritalStatus != oldWidget.initialData?.maritalStatus) {
      _selectedMaritalStatus = widget.initialData?.maritalStatus;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _rgController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    final data = IdentificationData(
      fullName: _nameController.text,
      cpf: _cpfController.text.isEmpty ? null : _cpfController.text,
      rg: _rgController.text.isEmpty ? null : _rgController.text,
      dateOfBirth: _selectedDate,
      gender: _selectedGender,
      maritalStatus: _selectedMaritalStatus,
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
              'Identificação',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Preencha os dados básicos de identificação do paciente',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Nome Completo *
            _buildLabel('Nome Completo', isRequired: true),
            TextFormField(
              controller: _nameController,
              decoration: _buildInputDecoration(hintText: 'Digite o nome completo', icon: Icons.person),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // CPF
            _buildLabel('CPF'),
            TextFormField(
              controller: _cpfController,
              decoration: _buildInputDecoration(hintText: '000.000.000-00', icon: Icons.badge),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
            ),
            const SizedBox(height: 20),

            // RG
            _buildLabel('RG'),
            TextFormField(
              controller: _rgController,
              decoration: _buildInputDecoration(hintText: 'Digite o RG', icon: Icons.credit_card),
            ),
            const SizedBox(height: 20),

            // Data de Nascimento
            _buildLabel('Data de Nascimento'),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  locale: const Locale('pt', 'BR'),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                  _notifyDataChanged();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Selecione a data',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate != null ? AppColors.offBlack : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Gênero
            _buildLabel('Gênero'),
            Wrap(
              spacing: 12,
              children: Gender.values.map((gender) {
                final isSelected = _selectedGender == gender;
                return ChoiceChip(
                  label: Text(_getGenderLabel(gender)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedGender = selected ? gender : null);
                    _notifyDataChanged();
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.offBlack,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Estado Civil
            _buildLabel('Estado Civil'),
            DropdownButtonFormField<String>(
              initialValue: _selectedMaritalStatus,
              decoration: _buildInputDecoration(hintText: 'Selecione o estado civil', icon: Icons.favorite),
              items: _maritalStatusOptions.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedMaritalStatus = value);
                _notifyDataChanged();
              },
            ),
            const SizedBox(height: 32),
          ],
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
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

  InputDecoration _buildInputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(icon, color: Colors.grey[600]),
    );
  }

  String _getGenderLabel(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Masculino';
      case Gender.female:
        return 'Feminino';
      case Gender.other:
        return 'Outro';
      case Gender.preferNotToSay:
        return 'Prefiro não dizer';
    }
  }
}
