import 'package:equatable/equatable.dart';
import 'package:common/common.dart';

// Events
abstract class ScheduleSettingsEvent extends Equatable {
  const ScheduleSettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadScheduleSettings extends ScheduleSettingsEvent {
  const LoadScheduleSettings();
}

class UpdateWorkingDay extends ScheduleSettingsEvent {
  final String dayOfWeek;
  final bool isEnabled;
  final String? morningStart;
  final String? morningEnd;
  final String? afternoonStart;
  final String? afternoonEnd;

  const UpdateWorkingDay({
    required this.dayOfWeek,
    required this.isEnabled,
    this.morningStart,
    this.morningEnd,
    this.afternoonStart,
    this.afternoonEnd,
  });

  @override
  List<Object?> get props => [dayOfWeek, isEnabled, morningStart, morningEnd, afternoonStart, afternoonEnd];
}

class SaveScheduleSettings extends ScheduleSettingsEvent {
  const SaveScheduleSettings();
}

// States
abstract class ScheduleSettingsState extends Equatable {
  const ScheduleSettingsState();

  @override
  List<Object?> get props => [];
}

class ScheduleSettingsInitial extends ScheduleSettingsState {
  const ScheduleSettingsInitial();
}

class ScheduleSettingsLoading extends ScheduleSettingsState {
  const ScheduleSettingsLoading();
}

class ScheduleSettingsLoaded extends ScheduleSettingsState {
  final Map<String, dynamic> workingHours;
  final bool isSaving;

  const ScheduleSettingsLoaded({required this.workingHours, this.isSaving = false});

  ScheduleSettingsLoaded copyWith({Map<String, dynamic>? workingHours, bool? isSaving}) {
    return ScheduleSettingsLoaded(workingHours: workingHours ?? this.workingHours, isSaving: isSaving ?? this.isSaving);
  }

  @override
  List<Object?> get props => [workingHours, isSaving];
}

class ScheduleSettingsError extends ScheduleSettingsState {
  final String message;

  const ScheduleSettingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ScheduleSettingsSaved extends ScheduleSettingsState {
  const ScheduleSettingsSaved();
}
