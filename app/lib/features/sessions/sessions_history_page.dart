import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc_models.dart';
import 'package:terafy/features/sessions/models/session.dart';
import 'package:terafy/features/sessions/widgets/session_card.dart';

class SessionsHistoryPage extends StatelessWidget {
  final String patientId;
  final String patientName;

  const SessionsHistoryPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final container = DependencyContainer();
    return BlocProvider(
      create: (context) => SessionsBloc(
        getSessionsUseCase: container.getSessionsUseCase,
        getSessionUseCase: container.getSessionUseCase,
        createSessionUseCase: container.createSessionUseCase,
        updateSessionUseCase: container.updateSessionUseCase,
        deleteSessionUseCase: container.deleteSessionUseCase,
        getAppointmentUseCase: container.getAppointmentUseCase,
        updateAppointmentUseCase: container.updateAppointmentUseCase,
      )..add(LoadPatientSessions(patientId)),
      child: _SessionsHistoryContent(
        patientId: patientId,
        patientName: patientName,
      ),
    );
  }
}

class _SessionsHistoryContent extends StatelessWidget {
  final String patientId;
  final String patientName;

  const _SessionsHistoryContent({
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Histórico de Sessões',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              patientName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implementar filtros
            },
          ),
        ],
      ),
      body: BlocConsumer<SessionsBloc, SessionsState>(
        listener: (context, state) {
          if (state is SessionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SessionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SessionsLoaded) {
            if (state.sessions.isEmpty) {
              return _buildEmptyState();
            }

            final groupedSessions = _groupSessionsByPeriod(state.sessions);

            return Column(
              children: [
                // Estatísticas
                _buildStatsBar(state.sessions),

                // Lista de sessões
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: groupedSessions.length,
                    itemBuilder: (context, index) {
                      final period = groupedSessions.keys.elementAt(index);
                      final sessions = groupedSessions[period]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header do período
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              period,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.offBlack,
                              ),
                            ),
                          ),

                          // Cards das sessões
                          ...sessions.map(
                            (session) => SessionCard(
                              session: session,
                              onTap: () => _onSessionTap(context, session),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed(
            '/session/new',
            arguments: {'patientId': patientId, 'patientName': patientName},
          );
          // Se a sessão foi criada, recarregar a lista
          if (result == true && context.mounted) {
            context.read<SessionsBloc>().add(LoadPatientSessions(patientId));
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nova Sessão'),
      ),
    );
  }

  Widget _buildStatsBar(List<Session> sessions) {
    final total = sessions.length;
    final completed = sessions
        .where((s) => s.status == SessionStatus.completed)
        .length;
    final cancelled = sessions
        .where(
          (s) =>
              s.status == SessionStatus.cancelledByPatient ||
              s.status == SessionStatus.cancelledByTherapist,
        )
        .length;
    final upcoming = sessions
        .where(
          (s) =>
              s.status == SessionStatus.scheduled ||
              s.status == SessionStatus.confirmed,
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.offBlack.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('Total', total.toString(), AppColors.primary),
          const SizedBox(width: 16),
          _buildStatItem('Realizadas', completed.toString(), Colors.teal),
          const SizedBox(width: 16),
          _buildStatItem('Próximas', upcoming.toString(), Colors.blue),
          const SizedBox(width: 16),
          _buildStatItem('Canceladas', cancelled.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.offBlack,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma sessão registrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece agendando a primeira sessão',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Map<String, List<Session>> _groupSessionsByPeriod(List<Session> sessions) {
    final now = DateTime.now();
    final grouped = <String, List<Session>>{};

    for (final session in sessions) {
      final sessionDate = session.scheduledStartTime;
      final difference = now.difference(sessionDate).inDays;

      String period;
      if (difference < 0) {
        period = 'Próximas Sessões';
      } else if (difference <= 7) {
        period = 'Última Semana';
      } else if (difference <= 30) {
        period = 'Último Mês';
      } else if (difference <= 90) {
        period = 'Últimos 3 Meses';
      } else {
        period = 'Mais Antigas';
      }

      grouped.putIfAbsent(period, () => []).add(session);
    }

    return grouped;
  }

  void _onSessionTap(BuildContext context, Session session) {
    // Se for rascunho, vai direto para a evolução
    if (session.status == SessionStatus.draft) {
      Navigator.of(context).pushNamed(
        '/session/evolution',
        arguments: {'sessionId': session.id, 'patientName': patientName},
      );
    } else {
      // Senão, vai para os detalhes
      Navigator.of(context).pushNamed(
        '/session/details',
        arguments: {'sessionId': session.id, 'patientName': patientName},
      );
    }
  }
}
