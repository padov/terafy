import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:common/common.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/schedule/bloc/schedule_settings_bloc.dart';
import 'package:terafy/features/schedule/bloc/schedule_settings_bloc_models.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';

class ScheduleSettingsPage extends StatelessWidget {
  const ScheduleSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final container = DependencyContainer();
        return ScheduleSettingsBloc(
          getScheduleSettingsUseCase: container.getScheduleSettingsUseCase,
          updateScheduleSettingsUseCase: container.updateScheduleSettingsUseCase,
        )..add(const LoadScheduleSettings());
      },
      child: const _ScheduleSettingsPageContent(),
    );
  }
}

class _ScheduleSettingsPageContent extends StatelessWidget {
  const _ScheduleSettingsPageContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScheduleSettingsBloc, ScheduleSettingsState>(
      listener: (context, state) {
        if (state is ScheduleSettingsError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
        } else if (state is ScheduleSettingsSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configurações salvas com sucesso!'), backgroundColor: AppColors.success),
          );
        }
      },
      builder: (context, state) {
        if (state is ScheduleSettingsInitial ||
            (state is ScheduleSettingsLoading && state is! ScheduleSettingsLoaded)) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Configuração de Agenda'),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.offBlack,
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        Map<String, dynamic> workingHours = {};
        bool isSaving = false;

        if (state is ScheduleSettingsLoaded) {
          workingHours = state.workingHours;
          isSaving = state.isSaving;
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Configuração de Agenda', style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.offBlack,
            elevation: 0,
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        context.read<ScheduleSettingsBloc>().add(const SaveScheduleSettings());
                      },
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text(
                        'Salvar',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDayConfig(context, 'Segunda-feira', 'monday', workingHours),
              _buildDayConfig(context, 'Terça-feira', 'tuesday', workingHours),
              _buildDayConfig(context, 'Quarta-feira', 'wednesday', workingHours),
              _buildDayConfig(context, 'Quinta-feira', 'thursday', workingHours),
              _buildDayConfig(context, 'Sexta-feira', 'friday', workingHours),
              _buildDayConfig(context, 'Sábado', 'saturday', workingHours),
              _buildDayConfig(context, 'Domingo', 'sunday', workingHours),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayConfig(BuildContext context, String label, String key, Map<String, dynamic> workingHours) {
    final daySettings = workingHours[key] as Map<String, dynamic>? ?? {};
    final isEnabled = daySettings['enabled'] as bool? ?? false;
    final morning = daySettings['morning'] as Map<String, dynamic>? ?? {};
    final afternoon = daySettings['afternoon'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            value: isEnabled,
            activeColor: AppColors.primary,
            onChanged: (value) {
              context.read<ScheduleSettingsBloc>().add(
                UpdateWorkingDay(
                  dayOfWeek: key,
                  isEnabled: value,
                  morningStart: morning['start'],
                  morningEnd: morning['end'],
                  afternoonStart: afternoon['start'],
                  afternoonEnd: afternoon['end'],
                ),
              );
            },
          ),
          if (isEnabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTimeRow(context, 'Manhã', morning['start'] ?? '08:00', morning['end'] ?? '12:00', (start, end) {
                    context.read<ScheduleSettingsBloc>().add(
                      UpdateWorkingDay(
                        dayOfWeek: key,
                        isEnabled: true,
                        morningStart: start,
                        morningEnd: end,
                        afternoonStart: afternoon['start'],
                        afternoonEnd: afternoon['end'],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  _buildTimeRow(context, 'Tarde', afternoon['start'] ?? '14:00', afternoon['end'] ?? '18:00', (
                    start,
                    end,
                  ) {
                    context.read<ScheduleSettingsBloc>().add(
                      UpdateWorkingDay(
                        dayOfWeek: key,
                        isEnabled: true,
                        morningStart: morning['start'],
                        morningEnd: morning['end'],
                        afternoonStart: start,
                        afternoonEnd: end,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeRow(
    BuildContext context,
    String label,
    String start,
    String end,
    Function(String, String) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildTimeInput(context, start, (newTime) {
                  onChanged(newTime, end);
                }),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
              Expanded(
                child: _buildTimeInput(context, end, (newTime) {
                  onChanged(start, newTime);
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInput(BuildContext context, String time, Function(String) onChanged) {
    return InkWell(
      onTap: () async {
        final parts = time.split(':');
        final currentHour = int.tryParse(parts[0]) ?? 0;
        final currentMinute = int.tryParse(parts[1]) ?? 0;

        final TimeOfDay? selected = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
              child: child!,
            );
          },
        );

        if (selected != null) {
          final formatted = '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
          onChanged(formatted);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
