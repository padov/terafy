import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/agenda/bloc/agenda_bloc.dart';
import 'package:terafy/features/agenda/bloc/agenda_bloc_models.dart';
import 'package:terafy/features/agenda/models/appointment.dart';
import 'package:terafy/features/agenda/new_appointment_page.dart';
import 'package:terafy/features/schedule/widgets/schedule_header.dart';
import 'package:terafy/features/schedule/widgets/week_view.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final container = DependencyContainer();

    return BlocProvider(
      create: (context) =>
          AgendaBloc(
            getAppointmentsUseCase: container.getAppointmentsUseCase,
            getAppointmentUseCase: container.getAppointmentUseCase,
            createAppointmentUseCase: container.createAppointmentUseCase,
            updateAppointmentUseCase: container.updateAppointmentUseCase,
            createSessionUseCase: container.createSessionUseCase,
            getNextSessionNumberUseCase: container.getNextSessionNumberUseCase,
            getSessionUseCase: container.getSessionUseCase,
            updateSessionUseCase: container.updateSessionUseCase,
          )..add(
            LoadAgenda(
              startDate: _getWeekStart(DateTime.now()),
              endDate: _getWeekEnd(DateTime.now()),
            ),
          ),
      child: const _SchedulePageContent(),
    );
  }

  static DateTime _getWeekStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  static DateTime _getWeekEnd(DateTime date) {
    return _getWeekStart(date).add(const Duration(days: 7));
  }
}

class _SchedulePageContent extends StatelessWidget {
  const _SchedulePageContent();

  static DateTime _getWeekStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Agenda',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
                const SnackBar(
                  content: Text('Filtros em desenvolvimento'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          // Buscar
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implementar busca
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Busca em desenvolvimento'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<AgendaBloc, AgendaState>(
        listener: (context, state) {
          if (state is AgendaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // Obter semana atual
          DateTime weekStart;
          List<Appointment> appointments = [];

          if (state is AgendaLoaded) {
            weekStart = state.startDate;
            appointments = state.appointments;
          } else {
            weekStart = _getWeekStart(DateTime.now());
          }

          return Column(
            children: [
              // Header com navegação de semanas
              ScheduleHeader(
                currentWeekStart: weekStart,
                onPreviousWeek: () {
                  final newStart = weekStart.subtract(const Duration(days: 7));
                  context.read<AgendaBloc>().add(
                    LoadAgenda(
                      startDate: newStart,
                      endDate: newStart.add(const Duration(days: 7)),
                    ),
                  );
                },
                onNextWeek: () {
                  final newStart = weekStart.add(const Duration(days: 7));
                  context.read<AgendaBloc>().add(
                    LoadAgenda(
                      startDate: newStart,
                      endDate: newStart.add(const Duration(days: 7)),
                    ),
                  );
                },
                onToday: () {
                  final today = _getWeekStart(DateTime.now());
                  context.read<AgendaBloc>().add(
                    LoadAgenda(
                      startDate: today,
                      endDate: today.add(const Duration(days: 7)),
                    ),
                  );
                },
              ),

              // Visualização semanal
              Expanded(
                child: state is AgendaLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () async {
                          context.read<AgendaBloc>().add(
                            LoadAgenda(
                              startDate: weekStart,
                              endDate: weekStart.add(const Duration(days: 7)),
                            ),
                          );
                        },
                        child: WeekView(
                          weekStart: weekStart,
                          appointments: appointments,
                        ),
                      ),
              ),
            ],
          );
        },
      ),

      // FAB para novo agendamento
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AgendaBloc>(),
                child: const NewAppointmentPage(),
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text(
          'Novo Agendamento',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
