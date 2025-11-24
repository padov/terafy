import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/common/app_colors.dart';

class SignupStep2Professional extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<String>? initialSpecialties;
  final List<String>? initialProfessionalRegistrations;
  final String? initialPresentation;
  final String? initialAddress;
  final Function({
    required List<String> specialties,
    required List<String> professionalRegistrations,
    required String presentation,
    required String address,
  })
  onDataChanged;

  const SignupStep2Professional({
    super.key,
    required this.formKey,
    this.initialSpecialties,
    this.initialProfessionalRegistrations,
    this.initialPresentation,
    this.initialAddress,
    required this.onDataChanged,
  });

  @override
  State<SignupStep2Professional> createState() =>
      _SignupStep2ProfessionalState();
}

class _SignupStep2ProfessionalState extends State<SignupStep2Professional> {
  late TextEditingController _presentationController;
  late TextEditingController _addressController;
  late List<String> _specialties;
  late List<String> _professionalRegistrations;
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _presentationController = TextEditingController(
      text: widget.initialPresentation,
    );
    _addressController = TextEditingController(text: widget.initialAddress);
    _specialties = List.from(widget.initialSpecialties ?? []);
    _professionalRegistrations = List.from(
      widget.initialProfessionalRegistrations ?? [],
    );
  }

  @override
  void dispose() {
    _presentationController.dispose();
    _addressController.dispose();
    _specialtyController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    widget.onDataChanged(
      specialties: _specialties,
      professionalRegistrations: _professionalRegistrations,
      presentation: _presentationController.text,
      address: _addressController.text,
    );
  }

  void _addSpecialty() {
    final value = _specialtyController.text.trim();
    if (value.isNotEmpty) {
      setState(() {
        _specialties.add(value);
        _specialtyController.clear();
      });
      _notifyDataChanged();
    }
  }

  void _removeSpecialty(int index) {
    setState(() {
      _specialties.removeAt(index);
    });
    _notifyDataChanged();
  }

  void _addRegistration() {
    final value = _registrationController.text.trim();
    if (value.isNotEmpty) {
      setState(() {
        _professionalRegistrations.add(value);
        _registrationController.clear();
      });
      _notifyDataChanged();
    }
  }

  void _removeRegistration(int index) {
    setState(() {
      _professionalRegistrations.removeAt(index);
    });
    _notifyDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'signup.step2.title'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.offBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'signup.step2.subtitle'.tr(),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Especialidades
          Text(
            'signup.step2.specialties'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.offBlack,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _specialtyController,
                  decoration: InputDecoration(
                    hintText: 'signup.step2.specialties_placeholder'.tr(),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onFieldSubmitted: (_) => _addSpecialty(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addSpecialty,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_specialties.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _specialties
                  .asMap()
                  .entries
                  .map(
                    (entry) => Chip(
                      label: Text(entry.value),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeSpecialty(entry.key),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),

          // Registros Profissionais
          Text(
            'signup.step2.registrations'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.offBlack,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _registrationController,
                  decoration: InputDecoration(
                    hintText: 'signup.step2.registrations_placeholder'.tr(),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onFieldSubmitted: (_) => _addRegistration(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addRegistration,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_professionalRegistrations.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _professionalRegistrations
                  .asMap()
                  .entries
                  .map(
                    (entry) => Chip(
                      label: Text(entry.value),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeRegistration(entry.key),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),

          // Apresentação Profissional
          Text(
            'signup.step2.presentation'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.offBlack,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _presentationController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'signup.step2.presentation_placeholder'.tr(),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => _notifyDataChanged(),
          ),
          const SizedBox(height: 16),

          // Endereço
          Text(
            'signup.step2.address'.tr(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.offBlack,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'signup.step2.address_placeholder'.tr(),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => _notifyDataChanged(),
          ),
        ],
      ),
    );
  }
}
