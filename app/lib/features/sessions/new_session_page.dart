import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc_models.dart';
import 'package:terafy/features/sessions/models/session.dart';

class NewSessionPage extends StatelessWidget {
  final String patientId;
  final String patientName;

  const NewSessionPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final container = DependencyContainer();
    return BlocProvider(
      create: (context) => SessionsBloc(
        getSessionsUseCase: container.getSessionsUseCase,
        getSessionUseCase: container.getSessionUseCase,
        createSessionUseCase: container.createSessionUseCase,
        updateSessionUseCase: container.updateSessionUseCase,
        deleteSessionUseCase: container.deleteSessionUseCase,
        getAppointmentUseCase: container.getAppointmentUseCase,
        updateAppointmentUseCase: container.updateAppointmentUseCase,
      ),
      child: _NewSessionContent(patientId: patientId, patientName: patientName),
    );
  }
}

class _NewSessionContent extends StatefulWidget {
  final String patientId;
  final String patientName;

  const _NewSessionContent({
    required this.patientId,
    required this.patientName,
  });

  @override
  State<_NewSessionContent> createState() => _NewSessionContentState();
}

class _NewSessionContentState extends State<_NewSessionContent> {
  final _formKey = GlobalKey<FormState>();

  // Informações básicas
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationMinutes = 60;
  SessionType _sessionType = SessionType.presential;
  SessionModality _sessionModality = SessionModality.individual;

  // Local/Link
  final _locationController = TextEditingController();
  final _onlineLinkController = TextEditingController();

  // Financeiro
  final _chargedAmountController = TextEditingController();
  bool _sendReminder = true;

  @override
  void dispose() {
    _locationController.dispose();
    _onlineLinkController.dispose();
    _chargedAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionsBloc, SessionsState>(
      listener: (context, state) {
        if (state is SessionCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sessão criada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is SessionsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is SessionsLoading;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nova Sessão',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.patientName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data e Hora
                  _buildSection('Data e Horário', Icons.calendar_today, [
                    _buildDateTimePicker(),
                    const SizedBox(height: 16),
                    _buildDurationPicker(),
                  ]),

                  const SizedBox(height: 16),

                  // Tipo e Modalidade
                  _buildSection('Tipo de Sessão', Icons.category, [
                    _buildSessionTypePicker(),
                    const SizedBox(height: 16),
                    _buildSessionModalityPicker(),
                  ]),

                  const SizedBox(height: 16),

                  // Local ou Link
                  _buildSection('Local/Link', Icons.location_on, [
                    if (_sessionType == SessionType.presential) ...[
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Local',
                          hintText: 'Ex: Consultório Av. Paulista, 1000',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.place),
                        ),
                        validator: (value) {
                          if (_sessionType == SessionType.presential &&
                              (value == null || value.isEmpty)) {
                            return 'Por favor, informe o local';
                          }
                          return null;
                        },
                      ),
                    ] else if (_sessionType == SessionType.onlineVideo ||
                        _sessionType == SessionType.onlineAudio) ...[
                      TextFormField(
                        controller: _onlineLinkController,
                        decoration: const InputDecoration(
                          labelText: 'Link da Sala Online',
                          hintText: 'Ex: https://meet.google.com/abc-def',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                        validator: (value) {
                          if ((_sessionType == SessionType.onlineVideo ||
                                  _sessionType == SessionType.onlineAudio) &&
                              (value == null || value.isEmpty)) {
                            return 'Por favor, informe o link';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Para sessões por telefone ou em grupo, não é necessário informar local ou link.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.offBlack,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 16),

                  // Informações Financeiras
                  _buildSection('Financeiro', Icons.attach_money, [
                    TextFormField(
                      controller: _chargedAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Valor da Sessão',
                        hintText: 'Ex: 200.00',
                        border: OutlineInputBorder(),
                        prefixText: 'R\$ ',
                        prefixIcon: Icon(Icons.money),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Lembrete
                  _buildSection('Lembrete', Icons.notifications, [
                    SwitchListTile(
                      value: _sendReminder,
                      onChanged: (value) =>
                          setState(() => _sendReminder = value),
                      title: const Text('Enviar lembrete automático'),
                      subtitle: const Text('24h antes da sessão'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // Botão de criar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _createSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Criar Sessão',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.offBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      children: [
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'd \'de\' MMMM \'de\' yyyy',
                          'pt_BR',
                        ).format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectTime,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horário',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duração: $_durationMinutes minutos',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Slider(
          value: _durationMinutes.toDouble(),
          min: 30,
          max: 180,
          divisions: 10,
          label: '$_durationMinutes min',
          onChanged: (value) {
            setState(() {
              _durationMinutes = value.toInt();
            });
          },
        ),
      ],
    );
  }

  Widget _buildSessionTypePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SessionType.values.map((type) {
            final isSelected = _sessionType == type;
            return ChoiceChip(
              label: Text(_getSessionTypeText(type)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _sessionType = type;
                  _locationController.clear();
                  _onlineLinkController.clear();
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.offBlack,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSessionModalityPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modalidade',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SessionModality.values.map((modality) {
            final isSelected = _sessionModality == modality;
            return ChoiceChip(
              label: Text(_getSessionModalityText(modality)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _sessionModality = modality;
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.offBlack,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _createSession() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newSession = Session(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      patientId: widget.patientId,
      therapistId: 'therapist-1',
      scheduledStartTime: scheduledDateTime,
      scheduledEndTime: scheduledDateTime.add(
        Duration(minutes: _durationMinutes),
      ),
      durationMinutes: _durationMinutes,
      sessionNumber: 1, // TODO: Calcular número correto
      type: _sessionType,
      modality: _sessionModality,
      location: _locationController.text.isNotEmpty
          ? _locationController.text
          : null,
      onlineRoomLink: _onlineLinkController.text.isNotEmpty
          ? _onlineLinkController.text
          : null,
      status: SessionStatus.scheduled,
      chargedAmount: _chargedAmountController.text.isNotEmpty
          ? double.tryParse(_chargedAmountController.text)
          : null,
      paymentStatus: PaymentStatus.pending,
      reminderSent: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<SessionsBloc>().add(CreateSession(newSession));
  }

  String _getSessionTypeText(SessionType type) {
    switch (type) {
      case SessionType.presential:
        return 'Presencial';
      case SessionType.onlineVideo:
        return 'Online (Vídeo)';
      case SessionType.onlineAudio:
        return 'Online (Áudio)';
      case SessionType.phone:
        return 'Telefone';
      case SessionType.group:
        return 'Grupo';
    }
  }

  String _getSessionModalityText(SessionModality modality) {
    switch (modality) {
      case SessionModality.individual:
        return 'Individual';
      case SessionModality.couple:
        return 'Casal';
      case SessionModality.family:
        return 'Família';
      case SessionModality.group:
        return 'Grupo';
    }
  }
}
