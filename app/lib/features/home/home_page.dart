import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/features/home/bloc/home_bloc.dart';
import 'package:terafy/features/home/bloc/home_bloc_models.dart';
import 'package:terafy/features/home/widgets/home_header.dart';
import 'package:terafy/features/home/widgets/stats_cards.dart';
import 'package:terafy/features/home/widgets/today_agenda.dart';
import 'package:terafy/features/home/widgets/pending_sessions.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (context) => HomeBloc()..add(const LoadHomeData()), child: const _HomePageContent());
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return PopScope(
          // Intercepta o botão de voltar e não permite fechar o app quando estiver na Home
          canPop: false,
          onPopInvoked: (didPop) {
            // Se tentar fazer pop (voltar), não faz nada
            // Isso previne que o app feche quando o usuário pressionar o botão de voltar na Home
          },
          child: Scaffold(
            backgroundColor: Colors.grey[50],
            body: _buildBody(context, state),
            bottomNavigationBar: _buildBottomNav(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state is HomeLoading && state.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is HomeError && state.data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<HomeBloc>().add(const LoadHomeData());
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final data = state.data;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Different content based on bottom nav index
    if (state.currentNavIndex == 0) {
      return _buildHomeContent(context, data);
    } else {
      return _buildPlaceholderScreen(state.currentNavIndex);
    }
  }

  Widget _buildHomeContent(BuildContext context, HomeData data) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<HomeBloc>().add(const RefreshHomeData());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: HomeHeader(
              userName: data.therapistName ?? data.userName,
              userRole: data.userRole,
              userPhotoUrl: data.userPhotoUrl,
              notificationCount: data.notificationCount,
              plan: data.plan,
              onNotificationTap: () {
                // TODO: Navigate to notifications
              },
            ),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: StatsCards(
              todayPatients: data.stats.todayPatients,
              pendingAppointments: data.stats.pendingAppointments,
              monthlyRevenue: data.stats.monthlyRevenue,
              completionRate: data.stats.completionRate,
            ),
          ),

          // Today's Agenda
          SliverToBoxAdapter(
            child: TodayAgenda(
              appointments: data.todayAppointments,
              onSeeAll: () {
                Navigator.of(context).pushNamed(AppRouter.scheduleRoute);
              },
            ),
          ),

          // Pending Sessions
          SliverToBoxAdapter(
            child: PendingSessions(
              sessions: data.pendingSessions,
              onSeeAll: () {
                // TODO: Navegar para lista de sessões pendentes
              },
            ),
          ),

          //   const SliverToBoxAdapter(child: SizedBox(height: 24)),

          //   // Quick Actions
          //   SliverToBoxAdapter(
          //     child: QuickActions(
          //       onNewAppointment: () {
          //         // TODO: Navigate to new appointment
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(
          //             content: Text('home.quick_actions.new_appointment'.tr()),
          //           ),
          //         );
          //       },
          //       onSearchPatient: () {
          //         // TODO: Navigate to search patient
          //         context.read<HomeBloc>().add(const ChangeBottomNavIndex(2));
          //       },
          //       onViewSchedule: () {
          //         Navigator.of(context).pushNamed(AppRouter.scheduleRoute);
          //       },
          //       onAddNote: () {
          //         // TODO: Navigate to add note
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(content: Text('home.quick_actions.add_note'.tr())),
          //         );
          //       },
          //       onViewFinancial: () {
          //         Navigator.of(context).pushNamed(AppRouter.financialRoute);
          //       },
          //     ),
          //   ),

          //   const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderScreen(int index) {
    String title;
    IconData icon;

    switch (index) {
      case 1:
        title = 'home.nav.schedule'.tr();
        icon = Icons.calendar_month;
        break;
      case 2:
        title = 'home.nav.patients'.tr();
        icon = Icons.people;
        break;
      case 3:
        title = 'home.nav.reports'.tr();
        icon = Icons.bar_chart;
        break;
      case 4:
        title = 'home.nav.settings'.tr();
        icon = Icons.settings;
        break;
      default:
        title = 'home.nav.home'.tr();
        icon = Icons.home;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text('Em breve...', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, HomeState state) {
    return BottomNavigationBar(
      currentIndex: state.currentNavIndex,
      onTap: (index) {
        if (index == 1) {
          // Navigate to Schedule page
          Navigator.of(context).pushNamed(AppRouter.scheduleRoute);
        } else if (index == 2) {
          // Navigate to Patients page
          Navigator.of(context).pushNamed(AppRouter.patientsRoute);
        } else {
          context.read<HomeBloc>().add(ChangeBottomNavIndex(index));
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: 'home.nav.home'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_month_outlined),
          activeIcon: const Icon(Icons.calendar_month),
          label: 'home.nav.schedule'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.people_outline),
          activeIcon: const Icon(Icons.people),
          label: 'home.nav.patients'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bar_chart_outlined),
          activeIcon: const Icon(Icons.bar_chart),
          label: 'home.nav.reports'.tr(),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings_outlined),
          activeIcon: const Icon(Icons.settings),
          label: 'home.nav.settings'.tr(),
        ),
      ],
    );
  }
}
