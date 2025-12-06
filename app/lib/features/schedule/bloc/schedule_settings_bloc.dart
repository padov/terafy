import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/domain/usecases/schedule/get_schedule_settings_usecase.dart';
import 'package:terafy/core/domain/usecases/schedule/update_schedule_settings_usecase.dart';
import 'package:common/common.dart';
import 'schedule_settings_bloc_models.dart';

class ScheduleSettingsBloc extends Bloc<ScheduleSettingsEvent, ScheduleSettingsState> {
  final GetScheduleSettingsUseCase getScheduleSettingsUseCase;
  final UpdateScheduleSettingsUseCase updateScheduleSettingsUseCase;

  TherapistScheduleSettings? _currentSettings;

  ScheduleSettingsBloc({required this.getScheduleSettingsUseCase, required this.updateScheduleSettingsUseCase})
    : super(const ScheduleSettingsInitial()) {
    on<LoadScheduleSettings>(_onLoadScheduleSettings);
    on<UpdateWorkingDay>(_onUpdateWorkingDay);
    on<SaveScheduleSettings>(_onSaveScheduleSettings);
  }

  Future<void> _onLoadScheduleSettings(LoadScheduleSettings event, Emitter<ScheduleSettingsState> emit) async {
    emit(const ScheduleSettingsLoading());
    try {
      // Fetch settings from the dedicated schedule API
      _currentSettings = await getScheduleSettingsUseCase();

      final workingHours = _currentSettings?.workingHours.isNotEmpty == true
          ? Map<String, dynamic>.from(_currentSettings!.workingHours)
          : _getDefaultWorkingHours();

      emit(ScheduleSettingsLoaded(workingHours: workingHours));
    } catch (e) {
      emit(ScheduleSettingsError('Erro ao carregar configurações: $e'));
    }
  }

  Map<String, dynamic> _getDefaultWorkingHours() {
    return {
      'monday': {
        'enabled': true,
        'morning': {'start': '08:00', 'end': '12:00'},
        'afternoon': {'start': '14:00', 'end': '18:00'},
      },
      'tuesday': {
        'enabled': true,
        'morning': {'start': '08:00', 'end': '12:00'},
        'afternoon': {'start': '14:00', 'end': '18:00'},
      },
      'wednesday': {
        'enabled': true,
        'morning': {'start': '08:00', 'end': '12:00'},
        'afternoon': {'start': '14:00', 'end': '18:00'},
      },
      'thursday': {
        'enabled': true,
        'morning': {'start': '08:00', 'end': '12:00'},
        'afternoon': {'start': '14:00', 'end': '18:00'},
      },
      'friday': {
        'enabled': true,
        'morning': {'start': '08:00', 'end': '12:00'},
        'afternoon': {'start': '14:00', 'end': '18:00'},
      },
      'saturday': {'enabled': false},
      'sunday': {'enabled': false},
    };
  }

  void _onUpdateWorkingDay(UpdateWorkingDay event, Emitter<ScheduleSettingsState> emit) {
    final currentState = state;
    if (currentState is ScheduleSettingsLoaded) {
      final updatedWorkingHours = Map<String, dynamic>.from(currentState.workingHours);

      updatedWorkingHours[event.dayOfWeek] = {
        'enabled': event.isEnabled,
        if (event.isEnabled) ...{
          'morning': {'start': event.morningStart ?? '08:00', 'end': event.morningEnd ?? '12:00'},
          'afternoon': {'start': event.afternoonStart ?? '14:00', 'end': event.afternoonEnd ?? '18:00'},
        },
      };

      emit(currentState.copyWith(workingHours: updatedWorkingHours));
    }
  }

  Future<void> _onSaveScheduleSettings(SaveScheduleSettings event, Emitter<ScheduleSettingsState> emit) async {
    final currentState = state;
    if (currentState is ScheduleSettingsLoaded && _currentSettings != null) {
      emit(currentState.copyWith(isSaving: true));
      try {
        // Create updated settings object
        // We use the existing _currentSettings as a base to preserve other fields
        // that are not being edited in this UI (like breakMinutes, sessionDuration, etc.)
        final updatedSettings = TherapistScheduleSettings(
          therapistId: _currentSettings!.therapistId,
          workingHours: currentState.workingHours,
          sessionDurationMinutes: _currentSettings!.sessionDurationMinutes,
          breakMinutes: _currentSettings!.breakMinutes,
          locations: _currentSettings!.locations,
          daysOff: _currentSettings!.daysOff,
          holidays: _currentSettings!.holidays,
          customBlocks: _currentSettings!.customBlocks,
          reminderEnabled: _currentSettings!.reminderEnabled,
          reminderDefaultOffset: _currentSettings!.reminderDefaultOffset,
          reminderDefaultChannel: _currentSettings!.reminderDefaultChannel,
          cancellationPolicy: _currentSettings!.cancellationPolicy,
          createdAt: _currentSettings!.createdAt,
          updatedAt: DateTime.now(),
        );

        await updateScheduleSettingsUseCase(updatedSettings);

        emit(const ScheduleSettingsSaved());
        // Reload to ensure we have the latest server state
        add(const LoadScheduleSettings());
      } catch (e) {
        emit(ScheduleSettingsError('Erro ao salvar configurações: $e'));
        emit(currentState.copyWith(isSaving: false));
      }
    }
  }
}
