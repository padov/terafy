import 'package:equatable/equatable.dart';

// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {
  const LoadHomeData();
}

class RefreshHomeData extends HomeEvent {
  const RefreshHomeData();
}

class ChangeBottomNavIndex extends HomeEvent {
  final int index;

  const ChangeBottomNavIndex(this.index);

  @override
  List<Object?> get props => [index];
}

// States
abstract class HomeState extends Equatable {
  final int currentNavIndex;
  final HomeData? data;

  const HomeState({this.currentNavIndex = 0, this.data});

  @override
  List<Object?> get props => [currentNavIndex, data];
}

class HomeInitial extends HomeState {
  const HomeInitial() : super(currentNavIndex: 0);
}

class HomeLoading extends HomeState {
  const HomeLoading({super.currentNavIndex, super.data});
}

class HomeLoaded extends HomeState {
  const HomeLoaded({super.currentNavIndex, required super.data});
}

class HomeError extends HomeState {
  final String message;

  const HomeError({super.currentNavIndex, super.data, required this.message});

  @override
  List<Object?> get props => [currentNavIndex, data, message];
}

// Data Models
class HomeData extends Equatable {
  final String userName;
  final String userRole;
  final String? userPhotoUrl;
  final int notificationCount;
  final String? therapistName;
  final TherapistPlan? plan;
  final DailyStats stats;
  final List<Appointment> todayAppointments;
  final List<Reminder> reminders;
  final List<RecentPatient> recentPatients;
  final List<PendingSessionItem> pendingSessions;

  const HomeData({
    required this.userName,
    required this.userRole,
    this.userPhotoUrl,
    this.notificationCount = 0,
    this.therapistName,
    this.plan,
    required this.stats,
    required this.todayAppointments,
    required this.reminders,
    required this.recentPatients,
    this.pendingSessions = const [],
  });

  @override
  List<Object?> get props => [
    userName,
    userRole,
    userPhotoUrl,
    notificationCount,
    therapistName,
    plan,
    stats,
    todayAppointments,
    reminders,
    recentPatients,
    pendingSessions,
  ];
}

class TherapistPlan extends Equatable {
  final int id;
  final String name;
  final double price;
  final int patientLimit;

  const TherapistPlan({required this.id, required this.name, required this.price, required this.patientLimit});

  @override
  List<Object?> get props => [id, name, price, patientLimit];
}

class DailyStats extends Equatable {
  final int todayPatients;
  final int pendingAppointments;
  final double monthlyRevenue;
  final int completionRate;

  const DailyStats({
    required this.todayPatients,
    required this.pendingAppointments,
    required this.monthlyRevenue,
    required this.completionRate,
  });

  @override
  List<Object?> get props => [todayPatients, pendingAppointments, monthlyRevenue, completionRate];
}

class Appointment extends Equatable {
  final String id;
  final String patientName;
  final String time;
  final String serviceType;
  final AppointmentStatus status;
  final DateTime startTime;
  final String? sessionId;

  const Appointment({
    required this.id,
    required this.patientName,
    required this.time,
    required this.serviceType,
    required this.status,
    required this.startTime,
    this.sessionId,
  });

  @override
  List<Object?> get props => [id, patientName, time, serviceType, status, startTime, sessionId];
}

enum AppointmentStatus { reserved, confirmed, completed, cancelled }

class Reminder extends Equatable {
  final String id;
  final String title;
  final String description;
  final ReminderType type;

  const Reminder({required this.id, required this.title, required this.description, required this.type});

  @override
  List<Object?> get props => [id, title, description, type];
}

enum ReminderType { evaluation, followUp, birthday, planRenewal }

class RecentPatient extends Equatable {
  final String id;
  final String name;
  final String lastVisit;
  final String? photoUrl;

  const RecentPatient({required this.id, required this.name, required this.lastVisit, this.photoUrl});

  @override
  List<Object?> get props => [id, name, lastVisit, photoUrl];
}

class PendingSessionItem extends Equatable {
  final int id;
  final int sessionNumber;
  final int patientId;
  final String patientName;
  final DateTime scheduledStartTime;
  final String status; // 'draft' or 'completed'

  const PendingSessionItem({
    required this.id,
    required this.sessionNumber,
    required this.patientId,
    required this.patientName,
    required this.scheduledStartTime,
    required this.status,
  });

  @override
  List<Object?> get props => [id, sessionNumber, patientId, patientName, scheduledStartTime, status];
}
