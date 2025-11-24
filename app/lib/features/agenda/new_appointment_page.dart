import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/agenda/bloc/agenda_bloc.dart';
import 'package:terafy/features/agenda/bloc/agenda_bloc_models.dart';
import 'package:terafy/features/agenda/models/appointment.dart';
import 'package:terafy/features/patients/models/patient.dart' as patient_model;

class NewAppointmentPage extends StatelessWidget {
  final Appointment? appointment; // Para edição

  const NewAppointmentPage({super.key, this.appointment});

  @override
  Widget build(BuildContext context) {
    return _NewAppointmentContent(appointment: appointment);
  }
}

class _NewAppointmentContent extends StatefulWidget {
  final Appointment? appointment;

  const _NewAppointmentContent({this.appointment});

  @override
  State<_NewAppointmentContent> createState() => _NewAppointmentContentState();
}

class _NewAppointmentContentState extends State<_NewAppointmentContent> {
  final _formKey = GlobalKey<FormState>();
  static final List<TimeOfDay> _allTimeSlots = List.generate(
    48,
    (index) => TimeOfDay(hour: index ~/ 2, minute: index.isEven ? 0 : 30),
  );

  // Controllers
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late Duration _duration;
  late AppointmentType _type;
  late RecurrenceType _recurrence;
  DateTime? _recurrenceEndDate;
  final _notesController = TextEditingController();
  final _roomController = TextEditingController();
  final _onlineLinkController = TextEditingController();

  late Set<int> _selectedWeekdays;
  int _recurrenceWeeksCount = 1;
  final List<DateTime> _creationQueue = [];
  Appointment? _templateAppointment;
  String? _lastCreatedAppointmentId;
  int _pendingCreations = 0;
  int _lastCreationCount = 0;

  String? _selectedPatientId;
  bool _isLoading = false;

  final List<patient_model.Patient> _patients = [];
  bool _patientsLoading = false;
  String? _patientsError;

  @override
  void initState() {
    super.initState();

    _selectedWeekdays = {DateTime.now().weekday};
    _recurrenceWeeksCount = 1;

    if (widget.appointment != null) {
      // Modo edição
      final apt = widget.appointment!;
      _selectedDate = DateTime(apt.dateTime.year, apt.dateTime.month, apt.dateTime.day);
      _selectedTime = TimeOfDay(hour: apt.dateTime.hour, minute: apt.dateTime.minute);
      _selectedTime = _normalizeTime(_selectedTime);
      _duration = apt.duration;
      _type = apt.type;
      _recurrence = apt.recurrence;
      _recurrenceEndDate = apt.recurrenceEndDate;
      _selectedPatientId = apt.patientId;
      _notesController.text = apt.notes ?? '';
      _roomController.text = apt.room ?? '';
      _onlineLinkController.text = apt.onlineLink ?? '';

      if (apt.recurrenceRule != null) {
        final ruleType = apt.recurrenceRule!['type']?.toString();
        final weeksCount = apt.recurrenceRule!['weeksCount'];
        if (weeksCount is int && weeksCount > 0) {
          _recurrenceWeeksCount = weeksCount;
        }

        if (ruleType == 'daily') {
          final weekdays = apt.recurrenceRule!['weekdays'];
          if (weekdays is List) {
            _selectedWeekdays = weekdays
                .whereType<num>()
                .map((e) => e.toInt())
                .where((day) => day >= 1 && day <= 7)
                .toSet();
            if (_selectedWeekdays.isEmpty) {
              _selectedWeekdays = {apt.dateTime.weekday};
            }
          }
        }
      }
    } else {
      // Modo criação
      _selectedDate = DateTime.now();
      _selectedTime = _normalizeTime(TimeOfDay.now());
      _duration = const Duration(minutes: 50);
      _type = AppointmentType.session;
      _recurrence = RecurrenceType.none;
    }

    if (_type == AppointmentType.session) {
      const sessionDurations = [
        Duration(minutes: 30),
        Duration(minutes: 60),
        Duration(minutes: 90),
        Duration(minutes: 120),
      ];
      if (!sessionDurations.contains(_duration)) {
        _duration = sessionDurations.first;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensurePatientsLoaded();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _roomController.dispose();
    _onlineLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appointment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Agendamento' : 'Novo Agendamento',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<AgendaBloc, AgendaState>(
        listener: (context, state) {
          if (state is AppointmentCreated) {
            if (_pendingCreations > 0) {
              _pendingCreations--;
              _lastCreatedAppointmentId = state.appointment.id;
              if (_creationQueue.isNotEmpty) {
                final nextDate = _creationQueue.removeAt(0);
                final nextAppointment = _templateAppointment!.copyWith(
                  id: 'tmp-${DateTime.now().millisecondsSinceEpoch}-${_creationQueue.length}',
                  dateTime: nextDate,
                  parentAppointmentId: _lastCreatedAppointmentId,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                context.read<AgendaBloc>().add(CreateAppointment(nextAppointment));
                return;
              }
              if (_pendingCreations == 0) {
                final message = _lastCreationCount > 1
                    ? '${_lastCreationCount} agendamentos criados com sucesso!'
                    : 'Agendamento criado com sucesso!';
                if (mounted) {
                  setState(() => _isLoading = false);
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
                Navigator.of(context).pop();
                _lastCreationCount = 0;
                _creationQueue.clear();
                _templateAppointment = null;
                _lastCreatedAppointmentId = null;
              }
            } else {
              if (mounted) {
                setState(() => _isLoading = false);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Agendamento criado com sucesso!'), backgroundColor: Colors.green),
              );
              Navigator.of(context).pop();
              _creationQueue.clear();
              _templateAppointment = null;
              _lastCreatedAppointmentId = null;
            }
          } else if (state is AppointmentUpdated) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Agendamento atualizado com sucesso!'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop();
          } else if (state is AgendaError) {
            // Limpa todo o estado de criação imediatamente
            _pendingCreations = 0;
            _lastCreationCount = 0;
            _creationQueue.clear();
            _templateAppointment = null;
            _lastCreatedAppointmentId = null;

            // IMPORTANTE: Sempre reseta o loading quando há erro
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
            );
          }
        },
        builder: (context, state) {
          // Garante que o loading seja resetado se o estado mudar para erro
          // mesmo que o listener não seja chamado
          if (state is AgendaError && _isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _pendingCreations = 0;
                  _lastCreationCount = 0;
                  _creationQueue.clear();
                  _templateAppointment = null;
                  _lastCreatedAppointmentId = null;
                });
              }
            });
          }

          // Se o estado não é mais de erro e o loading está ativo sem motivo,
          // reseta o loading (pode acontecer se o estado mudou sem o listener ser chamado)
          if (!(state is AgendaError) &&
              !(state is AppointmentCreated) &&
              !(state is AppointmentUpdated) &&
              _isLoading &&
              _pendingCreations == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pendingCreations == 0) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tipo de agendamento
                _buildSectionTitle('Tipo de Agendamento'),
                const SizedBox(height: 8),
                _buildTypeSelector(),

                const SizedBox(height: 24),

                // Paciente (apenas para sessões)
                if (_type == AppointmentType.session) ...[
                  _buildSectionTitle('Paciente'),
                  const SizedBox(height: 8),
                  _buildPatientSelector(),
                  const SizedBox(height: 24),
                ],

                // Data e Hora
                _buildSectionTitle('Data e Horário'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildDateField()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeField()),
                  ],
                ),

                const SizedBox(height: 24),

                // Duração
                _buildSectionTitle('Duração'),
                const SizedBox(height: 8),
                _buildDurationSelector(),

                const SizedBox(height: 24),

                // Recorrência
                _buildSectionTitle('Recorrência'),
                const SizedBox(height: 8),
                _buildRecurrenceSelector(),

                if (_recurrence == RecurrenceType.daily) ...[
                  const SizedBox(height: 4),
                  _buildWeekdaySelector(),
                  const SizedBox(height: 8),
                  _buildWeeksCountSelector('Repetir por (semanas)'),
                ] else if (_recurrence == RecurrenceType.weekly) ...[
                  const SizedBox(height: 8),
                  _buildWeeksCountSelector('Repetir por (semanas)'),
                ] else if (_recurrence != RecurrenceType.none) ...[
                  const SizedBox(height: 8),
                  _buildRecurrenceEndDateField(),
                ],

                const SizedBox(height: 24),

                // Local
                _buildSectionTitle('Local'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(hintText: 'Ex: Sala 1, Consultório', prefixIcon: Icon(Icons.room)),
                ),

                const SizedBox(height: 24),

                // Link Online (se aplicável)
                _buildSectionTitle('Link Online (opcional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _onlineLinkController,
                  decoration: const InputDecoration(
                    hintText: 'https://meet.google.com/...',
                    prefixIcon: Icon(Icons.videocam),
                  ),
                ),

                const SizedBox(height: 24),

                // Notas
                _buildSectionTitle('Notas'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(hintText: 'Observações sobre o agendamento'),
                  maxLines: 3,
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(isEditing),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.offBlack),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppointmentType.values.map((type) {
        final isSelected = _type == type;
        return ChoiceChip(
          label: Text(_getTypeLabel(type)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _type = type;
                if (_type != AppointmentType.session) {
                  _selectedPatientId = null;
                } else {
                  _selectedTime = _normalizeTime(_selectedTime);
                  const sessionDurations = [
                    Duration(minutes: 30),
                    Duration(minutes: 60),
                    Duration(minutes: 90),
                    Duration(minutes: 120),
                  ];
                  if (!sessionDurations.contains(_duration)) {
                    _duration = sessionDurations.first;
                  }
                }
              });
              if (type == AppointmentType.session) {
                _ensurePatientsLoaded();
              }
            }
          },
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.offBlack, fontWeight: FontWeight.w500),
        );
      }).toList(),
    );
  }

  String _getTypeLabel(AppointmentType type) {
    switch (type) {
      case AppointmentType.session:
        return 'Sessão';
      case AppointmentType.personal:
        return 'Pessoal';
      case AppointmentType.block:
        return 'Bloqueio';
    }
  }

  Widget _buildPatientSelector() {
    patient_model.Patient? selectedPatient;
    if (_selectedPatientId != null) {
      try {
        selectedPatient = _patients.firstWhere((p) => p.id == _selectedPatientId);
      } catch (_) {
        selectedPatient = null;
      }
    }

    final hasSelection = selectedPatient != null;
    final contactInfo = selectedPatient == null
        ? 'Escolha o paciente que receberá o atendimento'
        : (selectedPatient.phone.isNotEmpty ? selectedPatient.phone : selectedPatient.email ?? 'Sem contato principal');
    final initials = selectedPatient?.initials ?? '👤';
    final displayName = selectedPatient?.fullName ?? 'Selecionar paciente';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _patientsLoading ? null : _openPatientSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
              child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasSelection ? AppColors.offBlack : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(contactInfo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            if (_patientsLoading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              dateFormat.format(_selectedDate),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.offBlack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    final options = _allTimeSlots;

    final hasCurrent = options.any((slot) => slot.hour == _selectedTime.hour && slot.minute == _selectedTime.minute);

    if (!hasCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedTime = options.first);
      });
    }

    final selected = options.firstWhere(
      (slot) => slot.hour == _selectedTime.hour && slot.minute == _selectedTime.minute,
      orElse: () => options.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: PopupMenuButton<TimeOfDay>(
        initialValue: selected,
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) => setState(() => _selectedTime = value),
        itemBuilder: (context) => options
            .map(
              (slot) => PopupMenuItem<TimeOfDay>(
                value: slot,
                child: Text(
                  _formatTimeOfDay(slot),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: slot == selected ? FontWeight.w600 : FontWeight.w400,
                    color: slot == selected ? AppColors.primary : AppColors.offBlack,
                  ),
                ),
              ),
            )
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    _formatTimeOfDay(selected),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.offBlack),
                  ),
                ],
              ),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    final List<Duration> durations = _type == AppointmentType.session
        ? const [Duration(minutes: 30), Duration(minutes: 60), Duration(minutes: 90), Duration(minutes: 120)]
        : const [Duration(minutes: 30), Duration(minutes: 60), Duration(minutes: 90), Duration(minutes: 120)];

    final options = durations.contains(_duration) ? durations : [...durations, _duration];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((duration) {
        final isSelected = _duration == duration;
        return ChoiceChip(
          label: Text('${duration.inMinutes} min'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _duration = duration);
            }
          },
          padding: EdgeInsets.all(6),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.offBlack, fontWeight: FontWeight.w500),
        );
      }).toList(),
    );
  }

  Widget _buildRecurrenceSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RecurrenceType.values.map((recurrence) {
        final isSelected = _recurrence == recurrence;
        return ChoiceChip(
          label: Text(_getRecurrenceLabel(recurrence)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _recurrence = recurrence;
                if (_recurrence == RecurrenceType.daily) {
                  if (_selectedWeekdays.isEmpty) {
                    _selectedWeekdays = {_selectedDate.weekday};
                  }
                  _recurrenceWeeksCount = _recurrenceWeeksCount.clamp(1, 52);
                  _recurrenceEndDate = null;
                } else if (_recurrence == RecurrenceType.weekly) {
                  _recurrenceWeeksCount = _recurrenceWeeksCount.clamp(1, 52);
                  _recurrenceEndDate = null;
                }
              });
            }
          },
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.offBlack, fontWeight: FontWeight.w500),
        );
      }).toList(),
    );
  }

  String _getRecurrenceLabel(RecurrenceType recurrence) {
    switch (recurrence) {
      case RecurrenceType.none:
        return 'Único';
      case RecurrenceType.daily:
        return 'Diário';
      case RecurrenceType.weekly:
        return 'Semanal';
    }
  }

  Widget _buildRecurrenceEndDateField() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _recurrenceEndDate ?? _selectedDate.add(const Duration(days: 30)),
          firstDate: _selectedDate,
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _recurrenceEndDate = date);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_repeat, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              _recurrenceEndDate != null ? 'Até ${dateFormat.format(_recurrenceEndDate!)}' : 'Definir data final',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _recurrenceEndDate != null ? AppColors.offBlack : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdaySelector() {
    const labels = {1: 'Seg', 2: 'Ter', 3: 'Qua', 4: 'Qui', 5: 'Sex', 6: 'Sáb', 7: 'Dom'};

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: labels.entries.map((entry) {
        final day = entry.key;
        final label = entry.value;
        final isSelected = _selectedWeekdays.contains(day);
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedWeekdays.add(day);
              } else {
                _selectedWeekdays.remove(day);
              }
              if (_selectedWeekdays.isEmpty) {
                _selectedWeekdays = {day};
              }
            });
          },
          showCheckmark: false,
          padding: EdgeInsets.all(4),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.offBlack,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeksCountSelector(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: _recurrenceWeeksCount > 1
                ? () {
                    setState(() {
                      _recurrenceWeeksCount--;
                    });
                  }
                : null,
          ),
          Text(
            '$_recurrenceWeeksCount',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.offBlack),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              setState(() {
                _recurrenceWeeksCount++;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isEditing ? 'Atualizar' : 'Criar Agendamento',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAppointment() {
    // Previne múltiplas submissões simultâneas
    if (_isLoading) {
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_type == AppointmentType.session && _selectedPatientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o paciente da sessão.')));
        return;
      }

      if (_recurrence == RecurrenceType.daily && _selectedWeekdays.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Selecione ao menos um dia da semana.')));
        return;
      }

      // Limpa qualquer estado anterior de criação antes de começar
      _pendingCreations = 0;
      _lastCreationCount = 0;
      _creationQueue.clear();
      _templateAppointment = null;
      _lastCreatedAppointmentId = null;

      setState(() => _isLoading = true);

      // Combinar data e hora
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Se estiver editando, não precisa gerar ocorrências
      if (widget.appointment != null) {
        // Modo edição - atualiza apenas o agendamento existente
        final appointment = Appointment(
          id: widget.appointment!.id,
          therapistId: widget.appointment!.therapistId,
          patientId: _type == AppointmentType.session ? _selectedPatientId : null,
          dateTime: dateTime,
          duration: _duration,
          type: _type,
          status: widget.appointment!.status, // Mantém o status atual
          recurrence: _recurrence,
          recurrenceEndDate: _recurrenceEndDate,
          recurrenceRule: _recurrence == RecurrenceType.none
              ? null
              : (_recurrence == RecurrenceType.daily
                    ? {
                        'type': 'daily',
                        'weekdays': _selectedWeekdays.toList()..sort(),
                        'weeksCount': _recurrenceWeeksCount,
                      }
                    : {'type': 'weekly', 'weeksCount': _recurrenceWeeksCount}),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          room: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
          onlineLink: _onlineLinkController.text.trim().isEmpty ? null : _onlineLinkController.text.trim(),
          createdAt: widget.appointment!.createdAt,
          updatedAt: DateTime.now(),
          sessionId: widget.appointment!.sessionId,
          parentAppointmentId: widget.appointment!.parentAppointmentId,
        );

        _pendingCreations = 0;
        _lastCreationCount = 0;
        context.read<AgendaBloc>().add(UpdateAppointment(appointment));
        return;
      }

      // Modo criação - gera ocorrências para recorrência
      Map<String, dynamic>? recurrenceRule;
      if (_recurrence == RecurrenceType.daily) {
        recurrenceRule = {
          'type': 'daily',
          'weekdays': _selectedWeekdays.toList()..sort(),
          'weeksCount': _recurrenceWeeksCount,
        };
      } else if (_recurrence == RecurrenceType.weekly) {
        recurrenceRule = {'type': 'weekly', 'weeksCount': _recurrenceWeeksCount};
      }

      final occurrences = _generateOccurrences(dateTime);
      if (occurrences.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nenhuma ocorrência válida encontrada.')));
        return;
      }

      final recurrenceEndDate = _recurrence == RecurrenceType.none ? null : occurrences.last;

      final appointment = Appointment(
        id: 'apt-${DateTime.now().millisecondsSinceEpoch}',
        therapistId: 'therapist-1', // TODO: Pegar do usuário logado
        patientId: _type == AppointmentType.session ? _selectedPatientId : null,
        dateTime: dateTime,
        duration: _duration,
        type: _type,
        status: AppointmentStatus.reserved,
        recurrence: _recurrence,
        recurrenceEndDate: recurrenceEndDate,
        recurrenceRule: recurrenceRule,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        room: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
        onlineLink: _onlineLinkController.text.trim().isEmpty ? null : _onlineLinkController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Modo criação
      final epoch = DateTime.now().millisecondsSinceEpoch;
      _pendingCreations = occurrences.length;
      _lastCreationCount = _pendingCreations;
      _templateAppointment = appointment;
      _creationQueue
        ..clear()
        ..addAll(occurrences.skip(1));
      _lastCreatedAppointmentId = null;

      final firstAppointment = appointment.copyWith(
        id: 'tmp-$epoch-0',
        dateTime: occurrences.first,
        parentAppointmentId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      context.read<AgendaBloc>().add(CreateAppointment(firstAppointment));
    }
  }

  Future<void> _ensurePatientsLoaded() async {
    if (_patients.isNotEmpty || _patientsLoading) return;
    setState(() {
      _patientsLoading = true;
      _patientsError = null;
    });

    try {
      final container = DependencyContainer();
      final patients = await container.getPatientsUseCase();
      if (!mounted) return;
      setState(() {
        _patients
          ..clear()
          ..addAll(patients);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _patientsError = 'Erro ao carregar pacientes: ${e.toString()}';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _patientsLoading = false;
      });
    }
  }

  Future<void> _openPatientSelector() async {
    await _ensurePatientsLoaded();
    if (!mounted) return;

    if (_patientsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_patientsError!)));
      return;
    }

    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum paciente cadastrado ainda.')));
      return;
    }

    String query = '';

    final selectedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final filteredPatients = _patients.where((patient) {
                  final haystack = '${patient.fullName} ${patient.phone} ${patient.email ?? ''}'.toLowerCase();
                  return haystack.contains(query.trim().toLowerCase());
                }).toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                    TextField(
                      autofocus: true,
                      onChanged: (value) => setModalState(() => query = value),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar paciente por nome, email ou telefone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 320,
                      child: filteredPatients.isEmpty
                          ? const Center(child: Text('Nenhum paciente encontrado.'))
                          : ListView.separated(
                              itemCount: filteredPatients.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final patient = filteredPatients[index];
                                final isSelected = patient.id == _selectedPatientId;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withOpacity(0.12),
                                    child: Text(
                                      patient.initials,
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(patient.fullName),
                                  subtitle: Text(
                                    patient.phone.isNotEmpty ? patient.phone : patient.email ?? 'Sem contato',
                                  ),
                                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                                  onTap: () => Navigator.of(modalContext).pop(patient.id),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedId != null && mounted) {
      setState(() {
        _selectedPatientId = selectedId;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final dt = DateTime(0, 1, 1, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  TimeOfDay _normalizeTime(TimeOfDay time) {
    final totalMinutes = time.hour * 60 + time.minute;
    final nearestSlot = (totalMinutes / 30).round().clamp(0, 47);
    final normalizedHour = nearestSlot ~/ 2;
    final normalizedMinute = nearestSlot.isEven ? 0 : 30;
    return TimeOfDay(hour: normalizedHour, minute: normalizedMinute);
  }

  List<DateTime> _generateOccurrences(DateTime start) {
    if (_recurrence == RecurrenceType.none) {
      return [start];
    }

    final occurrences = <DateTime>[];

    if (_recurrence == RecurrenceType.daily) {
      final weekdays = _selectedWeekdays.toList()..sort();
      for (var week = 0; week < _recurrenceWeeksCount; week++) {
        for (final weekday in weekdays) {
          final delta = ((weekday - start.weekday) + 7) % 7 + week * 7;
          final occurrence = start.add(Duration(days: delta));
          if (!occurrences.contains(occurrence)) {
            occurrences.add(occurrence);
          }
        }
      }
    } else if (_recurrence == RecurrenceType.weekly) {
      for (var week = 0; week < _recurrenceWeeksCount; week++) {
        occurrences.add(start.add(Duration(days: week * 7)));
      }
    } else {
      occurrences.add(start);
    }

    occurrences.sort();
    return occurrences;
  }
}
