import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/appointments/bloc/appointment_bloc.dart';
import 'package:terafy/features/appointments/bloc/appointment_bloc_models.dart';
import 'package:terafy/features/appointments/new_appointment_page.dart';
import 'package:terafy/features/appointments/models/appointment.dart';
import 'package:terafy/features/schedule/widgets/schedule_header.dart';
import 'package:terafy/features/schedule/widgets/week_view.dart';
import 'package:terafy/features/schedule/bloc/schedule_settings_bloc.dart';
import 'package:terafy/features/schedule/bloc/schedule_settings_bloc_models.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final container = DependencyContainer();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AppointmentBloc(
            getAppointmentsUseCase: container.getAppointmentsUseCase,
            getAppointmentUseCase: container.getAppointmentUseCase,
            createAppointmentUseCase: container.createAppointmentUseCase,
            updateAppointmentUseCase: container.updateAppointmentUseCase,
            createSessionUseCase: container.createSessionUseCase,
            getNextSessionNumberUseCase: container.getNextSessionNumberUseCase,
            getSessionUseCase: container.getSessionUseCase,
            updateSessionUseCase: container.updateSessionUseCase,
          )..add(LoadAppointments(startDate: _getWeekStart(DateTime.now()), endDate: _getWeekEnd(DateTime.now()))),
        ),
        BlocProvider(
          create: (context) => ScheduleSettingsBloc(
            getScheduleSettingsUseCase: container.getScheduleSettingsUseCase,
            updateScheduleSettingsUseCase: container.updateScheduleSettingsUseCase,
          )..add(const LoadScheduleSettings()),
        ),
      ],
      child: const _SchedulePageContent(),
    );
  }

  static DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  static DateTime _getWeekEnd(DateTime date) {
    return _getWeekStart(date).add(const Duration(days: 7));
  }
}

class _SchedulePageContent extends StatelessWidget {
  const _SchedulePageContent();

  static DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  int _parseHour(String? time) {
    if (time == null) return 0;
    final parts = time.split(':');
    if (parts.isNotEmpty) {
      return int.tryParse(parts[0]) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Agenda', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.offBlack,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 48,
        actions: [
          // Filtros
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implementar filtros
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtros em desenvolvimento'), duration: Duration(seconds: 2)),
              );
            },
          ),
          // Buscar
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implementar busca
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Busca em desenvolvimento'), duration: Duration(seconds: 2)));
            },
          ),
        ],
      ),
      body: BlocConsumer<AppointmentBloc, AppointmentState>(
        listener: (context, state) {
          if (state is AppointmentError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, agendaState) {
          // Obter semana atual
          DateTime weekStart;
          List<Appointment> appointments = [];

          if (agendaState is AppointmentLoaded) {
            weekStart = agendaState.startDate;
            appointments = agendaState.appointments;
          } else {
            weekStart = _getWeekStart(DateTime.now());
          }

          return BlocBuilder<ScheduleSettingsBloc, ScheduleSettingsState>(
            builder: (context, settingsState) {
              Map<String, dynamic> workingHours = {};
              if (settingsState is ScheduleSettingsLoaded) {
                workingHours = settingsState.workingHours;
              }

              // Calcular horário de início e fim baseado na configuração da semana
              int startHour = 8;
              int endHour = 18;

              if (workingHours.isNotEmpty) {
                int minH = 24;
                int maxH = 0;
                bool hasEnabledDays = false;

                // Dias da semana em inglês para mapear com o json
                final weekDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

                // Verificar configurações para os dias da semana atual
                for (int i = 0; i < 7; i++) {
                  // TODO: Considerar apenas dias visíveis se necessário, por enquanto pega de todos
                  // Para ser mais preciso, poderíamos iterar apenas os dias que a WeekView vai mostrar
                  final dayKey = weekDays[i];
                  final dayConfig = workingHours[dayKey] as Map<String, dynamic>?;

                  if (dayConfig != null && dayConfig['enabled'] == true) {
                    hasEnabledDays = true;
                    final morning = dayConfig['morning'] as Map<String, dynamic>?;
                    final afternoon = dayConfig['afternoon'] as Map<String, dynamic>?;

                    if (morning != null) {
                      final start = _parseHour(morning['start']);
                      final end = _parseHour(morning['end']);
                      if (start < minH) minH = start;
                      if (end > maxH) maxH = end;
                    }

                    if (afternoon != null) {
                      final start = _parseHour(afternoon['start']);
                      final end = _parseHour(afternoon['end']);
                      if (start < minH) minH = start;
                      if (end > maxH) maxH = end;
                    }
                  }
                }

                if (hasEnabledDays) {
                  startHour = minH;
                  endHour = maxH;

                  // Garantir margem mínima se o range for muito pequeno
                  if (endHour <= startHour) {
                    endHour = startHour + 1;
                  }
                }

                // Expandir o range para incluir agendamentos fora do horário
                if (appointments.isNotEmpty) {
                  for (final appointment in appointments) {
                    // Verificar se o agendamento está na data visível (embora a lista já deva ser filtrada ou relevante)
                    // Aqui assumimos que appointments contém os eventos da semana carregada
                    final aptStartHour = appointment.dateTime.hour;
                    final aptEndHour = appointment.endTime.hour;
                    // Se termina em hora cheia (ex 18:00), o range deve ir até 18.
                    // Se termina 18:30, o range deve ir até 19 (para mostrar o bloco inteiro)
                    final aptEndHourAdjusted = (appointment.endTime.minute > 0) ? aptEndHour + 1 : aptEndHour;

                    if (aptStartHour < startHour) {
                      startHour = aptStartHour;
                    }
                    if (aptEndHourAdjusted > endHour) {
                      endHour = aptEndHourAdjusted;
                    }
                  }
                }
              }

              return Column(
                children: [
                  // Header com navegação de semanas
                  ScheduleHeader(
                    currentWeekStart: weekStart,
                    onPreviousWeek: () {
                      final newStart = weekStart.subtract(const Duration(days: 7));
                      context.read<AppointmentBloc>().add(
                        LoadAppointments(startDate: newStart, endDate: newStart.add(const Duration(days: 7))),
                      );
                    },
                    onNextWeek: () {
                      final newStart = weekStart.add(const Duration(days: 7));
                      context.read<AppointmentBloc>().add(
                        LoadAppointments(startDate: newStart, endDate: newStart.add(const Duration(days: 7))),
                      );
                    },
                    onToday: () {
                      final today = _getWeekStart(DateTime.now());
                      context.read<AppointmentBloc>().add(
                        LoadAppointments(startDate: today, endDate: today.add(const Duration(days: 7))),
                      );
                    },
                  ),

                  // Visualização semanal
                  Expanded(
                    child: agendaState is AppointmentLoading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: () async {
                              context.read<AppointmentBloc>().add(
                                LoadAppointments(startDate: weekStart, endDate: weekStart.add(const Duration(days: 7))),
                              );
                              context.read<ScheduleSettingsBloc>().add(const LoadScheduleSettings());
                            },
                            child: WeekView(
                              weekStart: weekStart,
                              appointments: appointments,
                              startHour: startHour,
                              endHour: endHour,
                              workingHours: workingHours,
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),

      // FAB para novo agendamento
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: context.read<AppointmentBloc>()),
                  BlocProvider.value(value: context.read<ScheduleSettingsBloc>()),
                ],
                child: const NewAppointmentPage(),
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Novo Agendamento', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
