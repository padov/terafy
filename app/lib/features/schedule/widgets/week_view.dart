import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/appointments/appointment_details_page.dart';
import 'package:terafy/features/appointments/bloc/appointment_bloc.dart';
import 'package:terafy/features/appointments/models/appointment.dart';
import 'package:terafy/features/appointments/new_appointment_page.dart';
import 'package:terafy/features/schedule/bloc/schedule_settings_bloc.dart';
import 'appointment_card.dart';

class WeekView extends StatefulWidget {
  final DateTime weekStart;
  final List<Appointment> appointments;

  final int startHour;
  final int endHour;
  final Map<String, dynamic> workingHours;

  const WeekView({
    super.key,
    required this.weekStart,
    required this.appointments,
    this.startHour = 6,
    this.endHour = 23,
    this.workingHours = const {},
  });

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  static const int _minutesPerSlot = 60;
  double _slotHeight = 60;
  final double sizeHourHeader = 20;
  bool _showSaturday = false;
  bool _showSunday = false;

  int get _startHour => widget.startHour;
  int get _endHour => widget.endHour;

  int get _totalMinutes => (_endHour - _startHour) * 60;
  int get _totalSlots => _totalMinutes ~/ _minutesPerSlot;
  // _totalHeight deve considerar o número de horas (18), não slots (17)
  // Pois geramos labels para cada hora de _startHour até _endHour (inclusive)
  int get _totalHours => _endHour - _startHour + 1;
  double get _totalHeight => _totalHours * _slotHeight;

  @override
  void didUpdateWidget(covariant WeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.weekStart.isAtSameMomentAs(widget.weekStart)) {
      _showSaturday = false;
      _showSunday = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allWeekDays = _getWeekDays(widget.weekStart);
    final visibleDays = _applyWeekendVisibility(allWeekDays);
    final today = DateTime.now();
    _slotHeight = _calculateSlotHeight(visibleDays.isEmpty ? 1 : visibleDays.length);

    return Column(
      children: [
        _buildWeekendToggleRow(allWeekDays),
        const SizedBox(height: 6),
        // Cabeçalho dos dias da semana
        _buildWeekdaysHeader(visibleDays, today),
        const SizedBox(height: 8),

        // Grade de horários
        Expanded(
          child: SingleChildScrollView(scrollDirection: Axis.vertical, child: _buildTimeGrid(visibleDays, today)),
        ),
      ],
    );
  }

  String _formatRangeLabel(List<DateTime> days) {
    if (days.isEmpty) return '';
    final dateFormat = DateFormat('dd/MM');
    if (days.length == 1) {
      final day = days.first;
      return '${_getDayName(day.weekday)}, ${dateFormat.format(day)}';
    }
    final start = days.first;
    final end = days.last;
    return '${dateFormat.format(start)} - ${dateFormat.format(end)}';
  }

  double _calculateSlotHeight(int dayCount) {
    if (dayCount <= 0) return _slotHeight;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = math.max(screenWidth - sizeHourHeader, 120);
    return availableWidth / dayCount;
  }

  List<DateTime> _applyWeekendVisibility(List<DateTime> allDays) {
    return allDays.where((date) {
      if (date.weekday == DateTime.saturday) {
        return _showSaturday;
      }
      if (date.weekday == DateTime.sunday) {
        return _showSunday;
      }
      return true;
    }).toList();
  }

  Widget _buildWeekendToggleRow(List<DateTime> allWeekDays) {
    // Verificar se deve mostrar os controles de sábado e domingo
    final hasSatConfig = widget.workingHours['saturday']?['enabled'] == true;
    final hasSunConfig = widget.workingHours['sunday']?['enabled'] == true;

    final hasSatApp = widget.appointments.any((a) => a.dateTime.weekday == DateTime.saturday);
    final hasSunApp = widget.appointments.any((a) => a.dateTime.weekday == DateTime.sunday);

    final showSatControl = hasSatConfig || hasSatApp;
    final showSunControl = hasSunConfig || hasSunApp;

    // Se tiver agendamento mas o toggle estiver desligado, forçar ligar (opcional, ou deixar o usuário ligar)
    // O requisito diz "se não tiver configuração... não precisa mostrar os botões".
    // Então se TIVER agendamento, mostra o botão.
    // Se não tiver config E não tiver agendamento, esconde o botão.

    final label = _formatRangeLabel(_applyWeekendVisibility(allWeekDays));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.offBlack),
            ),
          ),
          if (showSatControl) ...[
            const SizedBox(width: 8),
            _WeekendToggleChip(
              label: 'Sábado',
              isActive: _showSaturday,
              onTap: () => setState(() => _showSaturday = !_showSaturday),
            ),
          ],
          if (showSunControl) ...[
            const SizedBox(width: 8),
            _WeekendToggleChip(
              label: 'Domingo',
              isActive: _showSunday,
              onTap: () => setState(() => _showSunday = !_showSunday),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekdaysHeader(List<DateTime> weekDays, DateTime today) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          // Coluna de horários (vazia no header)
          SizedBox(width: sizeHourHeader),

          // Dias da semana (largura proporcional)
          ...weekDays.map((date) {
            final isToday = date.day == today.day && date.month == today.month && date.year == today.year;

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: isToday ? 4 : 0),
                child: Column(
                  children: [
                    Text(
                      _getDayName(date.weekday),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isToday ? AppColors.primary : AppColors.offBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isToday ? 40 : 32,
                      height: isToday ? 40 : 32,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(isToday ? 10 : 16),
                      ),
                      child: Center(
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.white : AppColors.offBlack,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeGrid(List<DateTime> weekDays, DateTime today) {
    return SizedBox(
      height: _totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeLabels(),
          ...weekDays.map((date) {
            final isToday = date.day == today.day && date.month == today.month && date.year == today.year;
            final dayAppointments = _getAppointmentsForDay(date);

            return Expanded(
              child: _buildDayColumn(context: context, date: date, isToday: isToday, appointments: dayAppointments),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeLabels() {
    final hours = List.generate(_endHour - _startHour + 1, (index) => _startHour + index);

    return SizedBox(
      width: sizeHourHeader,
      height: _totalHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: hours.map((hour) {
          return SizedBox(
            height: _slotHeight,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '${hour.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayColumn({
    required BuildContext context,
    required DateTime date,
    required bool isToday,
    required List<Appointment> appointments,
  }) {
    final stackChildren = <Widget>[
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final dy = details.localPosition.dy;
            final minutes = (dy / _totalHeight) * _totalMinutes;
            final roundedMinutes = (minutes / 30).round() * 30;
            final time = TimeOfDay(
              hour: _startHour,
              minute: 0,
            ).replacing(hour: _startHour + (roundedMinutes ~/ 60), minute: roundedMinutes % 60);

            final tapDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<AppointmentBloc>()),
                    BlocProvider.value(value: context.read<ScheduleSettingsBloc>()),
                  ],
                  child: NewAppointmentPage(initialDateTime: tapDate),
                ),
              ),
            );
          },
        ),
      ),
      _buildBackgroundGrid(isToday),
      _buildUnavailableRegions(date),
    ];

    for (final appointment in appointments) {
      final positioned = _buildAppointmentPositioned(context: context, appointment: appointment);
      if (positioned != null) {
        stackChildren.add(positioned);
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _totalHeight,
      decoration: BoxDecoration(
        // borderRadius: BorderRadius.circular(isToday ? 12 : 8),
        border: Border.all(
          width: 1,
          color: isToday ? AppColors.primary.withOpacity(0.35) : Colors.grey[300]!.withOpacity(0.5),
        ),
        color: isToday ? AppColors.primary.withOpacity(0.05) : Colors.white,
      ),
      child: Stack(children: stackChildren),
    );
  }

  Widget _buildBackgroundGrid(bool isToday) {
    final slotsPerHour = (60 / _minutesPerSlot).round();

    return Column(
      children: List.generate(_totalSlots, (index) {
        final isHourBoundary = index % slotsPerHour == 0;
        final isLast = index == _totalSlots - 1;

        return Container(
          height: _slotHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isHourBoundary
                    ? (isToday ? AppColors.primary.withOpacity(0.35) : Colors.grey[300]!)
                    : Colors.grey[200]!,
                width: isHourBoundary ? 1.1 : 0.6,
              ),
              bottom: isLast ? BorderSide(color: Colors.grey[300]!, width: 1) : BorderSide.none,
            ),
          ),
        );
      }),
    );
  }

  Positioned? _buildAppointmentPositioned({required BuildContext context, required Appointment appointment}) {
    final startMinutes = (appointment.dateTime.hour * 60 + appointment.dateTime.minute) - _startHour * 60;
    final endMinutes = startMinutes + appointment.duration.inMinutes;

    if (endMinutes <= 0 || startMinutes >= _totalMinutes) {
      return null;
    }

    final clampedStart = startMinutes.clamp(0, _totalMinutes).toDouble();
    final clampedEnd = endMinutes.clamp(0, _totalMinutes).toDouble();

    final top = _minuteToPixels(clampedStart);
    final height = math.max(_minuteToPixels(clampedEnd - clampedStart), _slotHeight * 0.75);

    return Positioned(
      top: top,
      left: 0.1,
      right: 0.1,
      height: height,
      child: AppointmentCard(
        appointment: appointment,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AppointmentBloc>(),
                child: AppointmentDetailsPage(appointmentId: appointment.id),
              ),
            ),
          );
        },
      ),
    );
  }

  double _minuteToPixels(double minutes) {
    return (minutes / _minutesPerSlot) * _slotHeight;
  }

  List<DateTime> _getWeekDays(DateTime start) {
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  String _getDayName(int weekday) {
    const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return days[weekday - 1];
  }

  List<Appointment> _getAppointmentsForDay(DateTime date) {
    final dayAppointments = widget.appointments.where((apt) {
      return apt.dateTime.year == date.year && apt.dateTime.month == date.month && apt.dateTime.day == date.day;
    }).toList();

    // Separar agendamentos ativos e cancelados
    final activeAppointments = dayAppointments.where((a) => a.status != AppointmentStatus.cancelled).toList();
    final cancelledAppointments = dayAppointments.where((a) => a.status == AppointmentStatus.cancelled).toList();

    // Filtrar cancelados que colidem com ativos
    final visibleCancelled = cancelledAppointments.where((cancelled) {
      // Verifica se existe algum ativo que colide
      final hasOverlap = activeAppointments.any((active) {
        // Colisão: (StartA < EndB) && (EndA > StartB)
        return cancelled.dateTime.isBefore(active.endTime) && cancelled.endTime.isAfter(active.dateTime);
      });
      // Se TEM sobreposição com ativo, ESCONDE (retorna false). Se NÃO tem, MOSTRA (retorna true).
      return !hasOverlap;
    }).toList();

    // Retorna lista combinada e ordenada
    return [...activeAppointments, ...visibleCancelled]..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Widget _buildUnavailableRegions(DateTime date) {
    if (widget.workingHours.isEmpty) return const SizedBox.shrink();

    final weekDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    // date.weekday: 1=Segunda ... 7=Domingo
    final dayKey = weekDays[date.weekday - 1];
    final dayConfig = widget.workingHours[dayKey] as Map<String, dynamic>?;

    final unavailableColor = Colors.grey.withOpacity(0.15); // Cor mais escura para indisponível

    // Se o dia não está configurado ou não está habilitado, bloqueia tudo
    if (dayConfig == null || dayConfig['enabled'] != true) {
      return Container(height: _totalHeight, color: unavailableColor);
    }

    final regions = <Widget>[];

    // Converter hora string "HH:MM" em minutos desde _startHour
    int timeToMinutes(String? time) {
      if (time == null) return 0;
      final parts = time.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return (h * 60 + m) - (_startHour * 60);
    }

    final morning = dayConfig['morning'] as Map<String, dynamic>? ?? {};
    final afternoon = dayConfig['afternoon'] as Map<String, dynamic>? ?? {};

    // Início do dia até início da manhã
    final morningStart = timeToMinutes(morning['start'] ?? '08:00');
    if (morningStart > 0) {
      regions.add(
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _minuteToPixels(morningStart.toDouble()),
          child: Container(color: unavailableColor),
        ),
      );
    }

    // Fim da manhã até início da tarde
    final morningEnd = timeToMinutes(morning['end'] ?? '12:00');
    final afternoonStart = timeToMinutes(afternoon['start'] ?? '13:00');

    if (afternoonStart > morningEnd) {
      final top = _minuteToPixels(morningEnd.toDouble());
      final height = _minuteToPixels((afternoonStart - morningEnd).toDouble());
      regions.add(
        Positioned(
          top: top,
          left: 0,
          right: 0,
          height: height,
          child: Container(color: unavailableColor),
        ),
      );
    }

    // Fim da tarde até fim do dia
    final afternoonEnd = timeToMinutes(afternoon['end'] ?? '18:00');
    if (afternoonEnd < _totalMinutes) {
      final top = _minuteToPixels(afternoonEnd.toDouble());
      final height = _minuteToPixels((_totalMinutes - afternoonEnd).toDouble());
      regions.add(
        Positioned(
          top: top,
          left: 0,
          right: 0,
          height: height,
          child: Container(color: unavailableColor),
        ),
      );
    }

    return Stack(children: regions);
  }
}

class _WeekendToggleChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _WeekendToggleChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isActive ? AppColors.primary : Colors.grey.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.visibility : Icons.visibility_off,
              size: 16,
              color: isActive ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
