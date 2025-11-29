import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/patients/registration/bloc/patient_registration_models.dart';

class Step6Administrative extends StatefulWidget {
  final AdministrativeData? initialData;
  final Function(AdministrativeData) onDataChanged;

  const Step6Administrative({super.key, this.initialData, required this.onDataChanged});

  @override
  State<Step6Administrative> createState() => _Step6AdministrativeState();
}

class _Step6AdministrativeState extends State<Step6Administrative> {
  late TextEditingController _sessionValueController;
  late TextEditingController _observationsController;
  late TextEditingController _tagInputController;

  String? _selectedPaymentMethod;
  DateTime? _consentDate;
  DateTime? _lgpdDate;
  List<String> _tags = [];
  String? _selectedColor;

  final List<String> _paymentMethods = [
    'Dinheiro',
    'PIX',
    'Cartão de Crédito',
    'Cartão de Débito',
    'Transferência Bancária',
    'Convênio',
  ];

  final List<String> _agendaColors = [
    '#7C3AED', // Roxo (primary)
    '#3B82F6', // Azul
    '#10B981', // Verde
    '#F59E0B', // Laranja
    '#EF4444', // Vermelho
    '#EC4899', // Rosa
    '#8B5CF6', // Violeta
    '#06B6D4', // Ciano
  ];

  @override
  void initState() {
    super.initState();
    _sessionValueController = TextEditingController(text: widget.initialData?.sessionValue?.toStringAsFixed(2) ?? '');
    _observationsController = TextEditingController(text: widget.initialData?.generalObservations ?? '');
    _tagInputController = TextEditingController();
    _selectedPaymentMethod = widget.initialData?.paymentMethod;
    _consentDate = widget.initialData?.consentDate;
    _lgpdDate = widget.initialData?.lgpdAcceptanceDate;
    _tags = List.from(widget.initialData?.tags ?? []);
    _selectedColor = widget.initialData?.agendaColor ?? _agendaColors[0];

    _sessionValueController.addListener(_notifyDataChanged);
    _observationsController.addListener(_notifyDataChanged);
  }

  @override
  void didUpdateWidget(Step6Administrative oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Só atualiza os controllers se o valor mudou de uma fonte externa
    // (não durante digitação do usuário). Verifica se o valor atual do controller
    // não é um prefixo do novo valor E o novo valor não é um prefixo do atual
    final newSessionValue = widget.initialData?.sessionValue?.toStringAsFixed(2) ?? '';
    if (widget.initialData?.sessionValue != oldWidget.initialData?.sessionValue &&
        _sessionValueController.text != newSessionValue &&
        !newSessionValue.startsWith(_sessionValueController.text) &&
        !_sessionValueController.text.startsWith(newSessionValue)) {
      _sessionValueController.text = newSessionValue;
    }

    final newObservations = widget.initialData?.generalObservations ?? '';
    if (widget.initialData?.generalObservations != oldWidget.initialData?.generalObservations &&
        _observationsController.text != newObservations &&
        !newObservations.startsWith(_observationsController.text) &&
        !_observationsController.text.startsWith(newObservations)) {
      _observationsController.text = newObservations;
    }
    // Atualiza outros campos se necessário
    if (widget.initialData?.paymentMethod != oldWidget.initialData?.paymentMethod) {
      _selectedPaymentMethod = widget.initialData?.paymentMethod;
    }
    if (widget.initialData?.consentDate != oldWidget.initialData?.consentDate) {
      _consentDate = widget.initialData?.consentDate;
    }
    if (widget.initialData?.lgpdAcceptanceDate != oldWidget.initialData?.lgpdAcceptanceDate) {
      _lgpdDate = widget.initialData?.lgpdAcceptanceDate;
    }
    if (widget.initialData?.agendaColor != oldWidget.initialData?.agendaColor) {
      _selectedColor = widget.initialData?.agendaColor ?? _agendaColors[0];
    }
    // Atualiza tags apenas se mudaram externamente
    if (widget.initialData?.tags != oldWidget.initialData?.tags) {
      final newTags = widget.initialData?.tags ?? [];
      if (!_listsEqual(_tags, newTags)) {
        _tags = List.from(newTags);
      }
    }
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _sessionValueController.dispose();
    _observationsController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _notifyDataChanged() {
    final data = AdministrativeData(
      sessionValue: _sessionValueController.text.isEmpty ? null : double.tryParse(_sessionValueController.text),
      paymentMethod: _selectedPaymentMethod,
      consentDate: _consentDate,
      lgpdAcceptanceDate: _lgpdDate,
      tags: _tags,
      generalObservations: _observationsController.text.isEmpty ? null : _observationsController.text,
      agendaColor: _selectedColor,
    );
    widget.onDataChanged(data);
  }

  void _addTag() {
    if (_tagInputController.text.trim().isNotEmpty) {
      setState(() {
        _tags.add(_tagInputController.text.trim());
        _tagInputController.clear();
      });
      _notifyDataChanged();
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    _notifyDataChanged();
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
            'Dados Administrativos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text('Informações financeiras e organização', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 32),

          // Valor da Sessão
          _buildLabel('Valor da Sessão (R\$)'),
          TextFormField(
            controller: _sessionValueController,
            decoration: _buildInputDecoration(hintText: '150.00', icon: Icons.attach_money),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          ),
          const SizedBox(height: 20),

          // Forma de Pagamento
          _buildLabel('Forma de Pagamento Preferencial'),
          DropdownButtonFormField<String>(
            initialValue: _selectedPaymentMethod,
            decoration: _buildInputDecoration(hintText: 'Selecione a forma de pagamento', icon: Icons.payment),
            items: _paymentMethods.map((method) {
              return DropdownMenuItem(value: method, child: Text(method));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedPaymentMethod = value);
              _notifyDataChanged();
            },
          ),
          const SizedBox(height: 32),

          // Termos e Consentimentos
          _buildSectionTitle('Termos e Consentimentos'),
          const SizedBox(height: 16),

          // Termo de Consentimento
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Termo de Consentimento Assinado'),
            subtitle: _consentDate != null
                ? Text(
                    'Data: ${DateFormat('dd/MM/yyyy').format(_consentDate!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  )
                : null,
            value: _consentDate != null,
            onChanged: (value) {
              setState(() {
                _consentDate = value == true ? DateTime.now() : null;
              });
              _notifyDataChanged();
            },
            activeColor: AppColors.primary,
          ),

          // LGPD
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Aceite LGPD'),
            subtitle: _lgpdDate != null
                ? Text(
                    'Data: ${DateFormat('dd/MM/yyyy').format(_lgpdDate!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  )
                : null,
            value: _lgpdDate != null,
            onChanged: (value) {
              setState(() {
                _lgpdDate = value == true ? DateTime.now() : null;
              });
              _notifyDataChanged();
            },
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 32),

          // Tags
          _buildSectionTitle('Tags de Organização'),
          const SizedBox(height: 16),

          _buildLabel('Adicionar Tags'),
          Text('Tags para organizar e filtrar pacientes', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagInputController,
                  decoration: _buildInputDecoration(
                    hintText: 'Ex: Ansiedade, Prioridade, Online...',
                    icon: Icons.label_outline,
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                height: 56,
                child: ElevatedButton(
                  onPressed: _addTag,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  side: const BorderSide(color: AppColors.primary),
                  labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeTag(tag),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 32),

          // Cor da Agenda
          _buildLabel('Cor de Identificação na Agenda'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _agendaColors.map((color) {
              final isSelected = _selectedColor == color;
              return InkWell(
                onTap: () {
                  setState(() => _selectedColor = color);
                  _notifyDataChanged();
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? AppColors.offBlack : Colors.transparent, width: 3),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.offBlack.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Observações Gerais
          _buildLabel('Observações Gerais'),
          Text('Anotações importantes sobre o paciente', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextFormField(
            controller: _observationsController,
            decoration: _buildInputDecoration(hintText: 'Adicione observações relevantes...', icon: Icons.notes),
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          // Nota informativa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ao finalizar, você poderá editar todas essas informações a qualquer momento.',
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
        border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 2)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.offBlack),
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
}
