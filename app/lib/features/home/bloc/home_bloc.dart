import 'package:common/common.dart' hide Appointment;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/core/domain/repositories/subscription_repository.dart';
import 'package:terafy/core/domain/usecases/home/get_home_summary_usecase.dart';
import 'package:terafy/core/domain/usecases/therapist/get_current_therapist_usecase.dart';

import 'home_bloc_models.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({GetCurrentTherapistUseCase? getCurrentTherapistUseCase, GetHomeSummaryUseCase? getHomeSummaryUseCase})
    : _getCurrentTherapistUseCase = getCurrentTherapistUseCase ?? DependencyContainer().getCurrentTherapistUseCase,
      _getHomeSummaryUseCase = getHomeSummaryUseCase ?? DependencyContainer().getHomeSummaryUseCase,
      super(const HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<RefreshHomeData>(_onRefreshHomeData);
    on<ChangeBottomNavIndex>(_onChangeBottomNavIndex);
  }

  final GetCurrentTherapistUseCase _getCurrentTherapistUseCase;
  final GetHomeSummaryUseCase _getHomeSummaryUseCase;

  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading(currentNavIndex: state.currentNavIndex, data: state.data));
    try {
      final homeData = await _loadHomeData();
      emit(HomeLoaded(currentNavIndex: state.currentNavIndex, data: homeData));
    } catch (e) {
      emit(HomeError(currentNavIndex: state.currentNavIndex, data: state.data, message: e.toString()));
    }
  }

  Future<void> _onRefreshHomeData(RefreshHomeData event, Emitter<HomeState> emit) async {
    try {
      final homeData = await _loadHomeData();
      emit(HomeLoaded(currentNavIndex: state.currentNavIndex, data: homeData));
    } catch (e) {
      emit(HomeError(currentNavIndex: state.currentNavIndex, data: state.data, message: e.toString()));
    }
  }

  void _onChangeBottomNavIndex(ChangeBottomNavIndex event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      emit(HomeLoaded(currentNavIndex: event.index, data: state.data));
    }
  }

  Future<HomeData> _loadHomeData() async {
    final therapistInfo = await _loadTherapistInfo();
    final summary = await _getHomeSummaryUseCase();

    // Busca informações de uso se disponível
    int? patientCount;
    int? patientLimit;
    try {
      final subscriptionRepository = DependencyContainer().subscriptionRepository;
      final usage = await subscriptionRepository.getUsageInfo();
      patientCount = usage.patientCount;
      patientLimit = usage.patientLimit;
    } catch (e) {
      // Ignora erros ao buscar uso
    }

    return _mapSummaryToHomeData(
      summary: summary,
      therapistName: therapistInfo.$1,
      plan: therapistInfo.$2,
      patientCount: patientCount,
      patientLimit: patientLimit,
    );
  }

  Future<(String?, TherapistPlan)> _loadTherapistInfo() async {
    String? therapistName;
    TherapistPlan plan = const TherapistPlan(id: 0, name: 'Free', price: 0.0, patientLimit: 5);

    try {
      final therapistData = await _getCurrentTherapistUseCase();
      therapistName = therapistData['name'] as String?;

      final planData = therapistData['plan'] as Map<String, dynamic>?;
      if (planData != null) {
        plan = TherapistPlan(
          id: planData['id'] as int? ?? 0,
          name: planData['name'] as String? ?? 'Free',
          price: (planData['price'] as num?)?.toDouble() ?? 0.0,
          patientLimit: planData['patient_limit'] as int? ?? 5,
        );
      }

      AppLogger.info('✅ Dados do terapeuta carregados: $therapistName - Plano: ${plan.name}');
    } catch (e) {
      AppLogger.warning('⚠️ Erro ao buscar dados do terapeuta: $e');
    }

    return (therapistName, plan);
  }

  HomeData _mapSummaryToHomeData({
    required HomeSummary summary,
    required TherapistPlan plan,
    String? therapistName,
    int? patientCount,
    int? patientLimit,
  }) {
    final agendaAppointments = [...summary.listOfTodaySessions]..sort((a, b) => a.startTime.compareTo(b.startTime));
    final agenda = agendaAppointments
        .map(
          (item) => Appointment(
            id: (item.appointmentId ?? item.startTime.millisecondsSinceEpoch).toString(),
            patientName: item.patientName ?? 'Paciente',
            time: DateFormat('HH:mm').format(item.startTime),
            serviceType: _resolveServiceType(item),
            status: _mapAppointmentStatus(item.status),
            startTime: item.startTime,
          ),
        )
        .toList();

    final Map<String, HomeAgendaItem> uniquePatients = {};
    for (final item in agendaAppointments) {
      final key = item.patientId?.toString() ?? item.patientName ?? '';
      if (key.isEmpty) continue;
      uniquePatients.putIfAbsent(key, () => item);
    }

    final recentPatients = uniquePatients.values.take(5).map((entry) {
      final label = entry.patientName?.isNotEmpty ?? false ? entry.patientName! : 'Paciente sem nome';
      final lastVisitTime = DateFormat('HH:mm').format(entry.startTime);

      return RecentPatient(
        id: (entry.patientId ?? label.hashCode).toString(),
        name: label,
        lastVisit: 'Hoje às $lastVisitTime',
      );
    }).toList();

    final stats = DailyStats(
      todayPatients: summary.todayConfirmedSessions,
      pendingAppointments: summary.todayPendingSessions,
      monthlyRevenue: 0.0,
      completionRate: (summary.monthlyCompletionRate * 100).round(),
    );

    final pendingSessions = summary.pendingSessions
        .map(
          (session) => PendingSessionItem(
            id: session.id,
            sessionNumber: session.sessionNumber,
            patientId: session.patientId,
            patientName: session.patientName,
            scheduledStartTime: session.scheduledStartTime,
            status: session.status,
          ),
        )
        .toList();

    AppLogger.info('Sessões pendentes mapeadas para HomeData: ${pendingSessions.length}');

    return HomeData(
      userName: therapistName ?? 'Profissional',
      userRole: 'Terapeuta',
      therapistName: therapistName,
      plan: plan,
      patientCount: patientCount,
      patientLimit: patientLimit,
      notificationCount: 0,
      stats: stats,
      todayAppointments: agenda,
      reminders: const <Reminder>[],
      recentPatients: recentPatients,
      pendingSessions: pendingSessions,
    );
  }

  String _resolveServiceType(HomeAgendaItem item) {
    if ((item.title ?? '').trim().isNotEmpty) {
      return item.title!;
    }
    switch (item.type) {
      case 'session':
        return 'Sessão';
      case 'personal':
        return 'Compromisso pessoal';
      case 'block':
        return 'Bloqueio de agenda';
      default:
        return item.type;
    }
  }

  AppointmentStatus _mapAppointmentStatus(String status) {
    switch (status) {
      case 'reserved':
        return AppointmentStatus.reserved;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.reserved;
    }
  }
}
