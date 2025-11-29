import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/common/app_colors.dart';

class SignupStep1Personal extends StatefulWidget {
  static final DateTime _defaultBirthday = DateTime(1979, 1, 1);
  final GlobalKey<FormState> formKey;
  final String? initialName;
  final String? initialNickname;
  final String? initialLegalDocument;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialPassword;
  final DateTime? initialBirthday;
  final bool showPasswordFields; // Controla se mostra campos de senha
  final bool readOnlyEmail; // Controla se o email é somente leitura
  final Function({
    required String name,
    required String nickname,
    required String legalDocument,
    required String email,
    required String phone,
    String? password,
    DateTime? birthday,
  })
  onDataChanged;

  const SignupStep1Personal({
    super.key,
    required this.formKey,
    this.initialName,
    this.initialNickname,
    this.initialLegalDocument,
    this.initialEmail,
    this.initialPhone,
    this.initialPassword,
    this.initialBirthday,
    this.showPasswordFields = true, // Por padrão mostra os campos
    this.readOnlyEmail = false, // Por padrão permite editar email
    required this.onDataChanged,
  });

  @override
  State<SignupStep1Personal> createState() => _SignupStep1PersonalState();
}

class _SignupStep1PersonalState extends State<SignupStep1Personal> {
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _legalDocumentController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthdayController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  DateTime? _selectedBirthday;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _nicknameController = TextEditingController(text: widget.initialNickname);
    _legalDocumentController = TextEditingController(text: widget.initialLegalDocument);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _selectedBirthday = widget.initialBirthday ?? SignupStep1Personal._defaultBirthday;
    _birthdayController = TextEditingController(
      text: _selectedBirthday != null ? DateFormat('dd/MM/yyyy').format(_selectedBirthday!) : '',
    );
    _passwordController = TextEditingController(text: widget.initialPassword);
    _confirmPasswordController = TextEditingController(text: widget.initialPassword);
  }

  @override
  void didUpdateWidget(SignupStep1Personal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Só atualiza os controllers se o valor mudou de uma fonte externa
    // (não durante digitação do usuário). Verifica se o valor atual do controller
    // não é um prefixo do novo valor E o novo valor não é um prefixo do atual
    // (indicando que é uma atualização externa, não digitação)
    final newName = widget.initialName ?? '';
    if (widget.initialName != oldWidget.initialName &&
        _nameController.text != newName &&
        !newName.startsWith(_nameController.text) &&
        !_nameController.text.startsWith(newName)) {
      _nameController.text = newName;
    }

    final newNickname = widget.initialNickname ?? '';
    if (widget.initialNickname != oldWidget.initialNickname &&
        _nicknameController.text != newNickname &&
        !newNickname.startsWith(_nicknameController.text) &&
        !_nicknameController.text.startsWith(newNickname)) {
      _nicknameController.text = newNickname;
    }

    final newLegalDocument = widget.initialLegalDocument ?? '';
    if (widget.initialLegalDocument != oldWidget.initialLegalDocument &&
        _legalDocumentController.text != newLegalDocument &&
        !newLegalDocument.startsWith(_legalDocumentController.text) &&
        !_legalDocumentController.text.startsWith(newLegalDocument)) {
      _legalDocumentController.text = newLegalDocument;
    }

    // Atualiza o controller do email quando o initialEmail mudar
    final newEmail = widget.initialEmail ?? '';
    if (widget.initialEmail != oldWidget.initialEmail &&
        _emailController.text != newEmail &&
        !newEmail.startsWith(_emailController.text) &&
        !_emailController.text.startsWith(newEmail)) {
      _emailController.text = newEmail;
    }

    final newPhone = widget.initialPhone ?? '';
    if (widget.initialPhone != oldWidget.initialPhone &&
        _phoneController.text != newPhone &&
        !newPhone.startsWith(_phoneController.text) &&
        !_phoneController.text.startsWith(newPhone)) {
      _phoneController.text = newPhone;
    }

    if (widget.initialBirthday != oldWidget.initialBirthday) {
      _selectedBirthday = widget.initialBirthday ?? SignupStep1Personal._defaultBirthday;
      final newBirthdayText = _selectedBirthday != null ? DateFormat('dd/MM/yyyy').format(_selectedBirthday!) : '';
      if (_birthdayController.text != newBirthdayText) {
        _birthdayController.text = newBirthdayText;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _legalDocumentController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      _notifyDataChanged();
    }
  }

  void _notifyDataChanged() {
    widget.onDataChanged(
      name: _nameController.text,
      nickname: _nicknameController.text,
      legalDocument: _legalDocumentController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      birthday: _selectedBirthday,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'signup.step1.title'.tr(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.offBlack),
          ),
          const SizedBox(height: 8),
          Text('signup.step1.subtitle'.tr(), style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 24),

          // Nome Completo
          Text(
            'signup.step1.name'.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'signup.step1.name_placeholder'.tr(),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (_) => _notifyDataChanged(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe o nome completo';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Apelido
          Text(
            'signup.step1.nickname'.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nicknameController,
            decoration: InputDecoration(
              hintText: 'signup.step1.nickname_placeholder'.tr(),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (_) => _notifyDataChanged(),
          ),
          const SizedBox(height: 16),

          // CPF/CNPJ
          Text(
            'signup.step1.legal_document'.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _legalDocumentController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'signup.step1.legal_document_placeholder'.tr(),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (_) => _notifyDataChanged(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Documento é obrigatório';
              }
              if (value.trim().length < 11) {
                return 'Documento inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email
          Text(
            'signup.step1.email'.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: widget.readOnlyEmail, // Email somente leitura se especificado
            decoration: InputDecoration(
              hintText: 'signup.step1.email_placeholder'.tr(),
              filled: true,
              fillColor: widget.readOnlyEmail
                  ? Colors.grey[200]
                  : Colors.grey[100], // Cor diferente quando somente leitura
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: widget.readOnlyEmail ? null : (_) => _notifyDataChanged(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email é obrigatório';
              }
              final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campos de senha (opcional)
          if (widget.showPasswordFields) ...[
            // Senha
            Text(
              'Senha',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Crie uma senha',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              onChanged: (_) => _notifyDataChanged(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe uma senha';
                }
                if (value.length < 6) {
                  return 'A senha deve ter pelo menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirmar senha
            Text(
              'Confirmar senha',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: 'Repita a senha',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              onChanged: (_) => _notifyDataChanged(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirme a senha';
                }
                if (value != _passwordController.text) {
                  return 'As senhas não conferem';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Telefone
          Text(
            'signup.step1.phone'.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'signup.step1.phone_placeholder'.tr(),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (_) => _notifyDataChanged(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Telefone é obrigatório';
              }
              if (value.trim().length < 10) {
                return 'Telefone inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Data de Nascimento
          Text(
            'signup.step1.birthday'.tr(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _birthdayController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'signup.step1.birthday_placeholder'.tr(),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
            ),
            onTap: _selectBirthday,
          ),
        ],
      ),
    );
  }
}
