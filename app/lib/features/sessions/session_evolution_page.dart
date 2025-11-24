import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc_models.dart';
import 'package:terafy/features/sessions/models/session.dart';

class SessionEvolutionPage extends StatelessWidget {
  final String sessionId;
  final String patientName;
  final Session? existingSession;

  const SessionEvolutionPage({
    super.key,
    required this.sessionId,
    required this.patientName,
    this.existingSession,
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
      )..add(LoadSessionDetails(sessionId)),
      child: _SessionEvolutionContent(
        sessionId: sessionId,
        patientName: patientName,
        existingSession: existingSession,
      ),
    );
  }
}

class _SessionEvolutionContent extends StatefulWidget {
  final String sessionId;
  final String patientName;
  final Session? existingSession;

  const _SessionEvolutionContent({
    required this.sessionId,
    required this.patientName,
    this.existingSession,
  });

  @override
  State<_SessionEvolutionContent> createState() =>
      _SessionEvolutionContentState();
}

class _SessionEvolutionContentState extends State<_SessionEvolutionContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  Session? _currentSession;

  // Campos do formulário
  final _moodController = TextEditingController();
  final _topicsController = TextEditingController();
  List<String> _topics = [];
  final _notesController = TextEditingController();
  final _behaviorController = TextEditingController();
  final _interventionController = TextEditingController();
  List<String> _interventions = [];
  final _resourcesController = TextEditingController();
  final _homeworkController = TextEditingController();
  final _reactionsController = TextEditingController();
  final _progressController = TextEditingController();
  final _difficultiesController = TextEditingController();
  final _nextStepsController = TextEditingController();
  final _nextGoalsController = TextEditingController();
  bool _needsReferral = false;
  RiskLevel _currentRisk = RiskLevel.low;
  final _importantObsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    if (widget.existingSession != null) {
      _loadExistingData(widget.existingSession!);
    }
  }

  void _loadExistingData(Session session) {
    _currentSession = session;
    _moodController.text = session.patientMood ?? '';
    _topics = List.from(session.topicsDiscussed);
    _notesController.text = session.sessionNotes ?? '';
    _behaviorController.text = session.observedBehavior ?? '';
    _interventions = List.from(session.interventionsUsed);
    _resourcesController.text = session.resourcesUsed ?? '';
    _homeworkController.text = session.homework ?? '';
    _reactionsController.text = session.patientReactions ?? '';
    _progressController.text = session.progressObserved ?? '';
    _difficultiesController.text = session.difficultiesIdentified ?? '';
    _nextStepsController.text = session.nextSteps ?? '';
    _nextGoalsController.text = session.nextSessionGoals ?? '';
    _needsReferral = session.needsReferral;
    _currentRisk = session.currentRisk;
    _importantObsController.text = session.importantObservations ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _moodController.dispose();
    _topicsController.dispose();
    _notesController.dispose();
    _behaviorController.dispose();
    _interventionController.dispose();
    _resourcesController.dispose();
    _homeworkController.dispose();
    _reactionsController.dispose();
    _progressController.dispose();
    _difficultiesController.dispose();
    _nextStepsController.dispose();
    _nextGoalsController.dispose();
    _importantObsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionsBloc, SessionsState>(
      listener: (context, state) {
        if (state is SessionDetailsLoaded && _currentSession == null) {
          setState(() {
            _loadExistingData(state.session);
          });
        } else if (state is SessionUpdated) {
          final isDraft = state.session.status == SessionStatus.draft;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isDraft
                    ? 'Rascunho salvo com sucesso!'
                    : 'Evolução finalizada com sucesso!',
              ),
              backgroundColor: isDraft ? Colors.amber : Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is SessionsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is SessionsLoading;

        final isDraft = _currentSession?.status == SessionStatus.draft;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Registro de Evolução',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isDraft) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'RASCUNHO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Colors.amber[900],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        widget.patientName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(text: 'Sessão'),
                Tab(text: 'Intervenções'),
                Tab(text: 'Evolução'),
                Tab(text: 'Risco'),
              ],
            ),
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSessionTab(),
                      _buildInterventionsTab(),
                      _buildProgressTab(),
                      _buildRiskTab(),
                    ],
                  ),
                ),
                _buildBottomBar(isLoading),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tab 1: Sessão (Humor, Temas, Notas, Comportamento)
  Widget _buildSessionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Humor/Estado Emocional'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _moodController,
            decoration: const InputDecoration(
              hintText: 'Ex: Ansioso, mas receptivo',
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Temas Abordados'),
          const SizedBox(height: 8),
          if (_topics.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _topics.map((topic) {
                return Chip(
                  label: Text(topic),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() => _topics.remove(topic));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _topicsController,
                  decoration: const InputDecoration(hintText: 'Adicionar tema'),
                  onFieldSubmitted: (_) => _addTopic(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addTopic,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                iconSize: 32,
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Notas da Sessão'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Descreva o conteúdo principal da sessão...',
            ),
            maxLines: 6,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Comportamento Observado'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _behaviorController,
            decoration: const InputDecoration(
              hintText:
                  'Ex: Postura tensa no início, relaxou após primeiros 20 minutos',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // Tab 2: Intervenções (Técnicas, Recursos, Tarefas)
  Widget _buildInterventionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Técnicas/Intervenções Utilizadas'),
          const SizedBox(height: 8),
          if (_interventions.isNotEmpty) ...[
            Column(
              children: _interventions.map((intervention) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(intervention)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() => _interventions.remove(intervention));
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _interventionController,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Reestruturação cognitiva',
                  ),
                  onFieldSubmitted: (_) => _addIntervention(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addIntervention,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                iconSize: 32,
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Recursos/Materiais Utilizados'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _resourcesController,
            decoration: const InputDecoration(
              hintText: 'Ex: Exercícios de respiração, worksheets',
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Tarefas/Orientações para Casa'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _homeworkController,
            decoration: const InputDecoration(
              hintText:
                  'Ex: Praticar respiração 2x/dia. Registrar situações de ansiedade.',
            ),
            maxLines: 4,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Reações do Paciente'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _reactionsController,
            decoration: const InputDecoration(
              hintText: 'Como o paciente reagiu às intervenções?',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // Tab 3: Evolução (Progresso, Dificuldades, Próximos Passos)
  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Progresso Observado'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _progressController,
            decoration: const InputDecoration(
              hintText: 'Que avanços foram notados nesta sessão?',
            ),
            maxLines: 4,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Dificuldades Identificadas'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _difficultiesController,
            decoration: const InputDecoration(
              hintText: 'Quais desafios ou obstáculos foram identificados?',
            ),
            maxLines: 4,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Próximos Passos'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nextStepsController,
            decoration: const InputDecoration(
              hintText: 'O que precisa ser trabalhado nas próximas sessões?',
            ),
            maxLines: 4,
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Objetivos para Próxima Sessão'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nextGoalsController,
            decoration: const InputDecoration(
              hintText: 'Quais serão os focos da próxima sessão?',
            ),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // Tab 4: Risco (Avaliação de Risco e Observações Importantes)
  Widget _buildRiskTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Nível de Risco Atual'),
          const SizedBox(height: 16),

          _buildRiskOption(
            RiskLevel.low,
            'Baixo',
            Colors.green,
            'Paciente estável, sem indicadores de risco',
          ),
          const SizedBox(height: 12),
          _buildRiskOption(
            RiskLevel.medium,
            'Médio',
            Colors.orange,
            'Atenção necessária, monitoramento próximo',
          ),
          const SizedBox(height: 12),
          _buildRiskOption(
            RiskLevel.high,
            'Alto',
            Colors.red,
            'Risco significativo, intervenção imediata',
          ),

          const SizedBox(height: 24),

          CheckboxListTile(
            value: _needsReferral,
            onChanged: (value) =>
                setState(() => _needsReferral = value ?? false),
            title: const Text('Necessita Encaminhamento'),
            subtitle: const Text(
              'Marque se for necessário encaminhar para outro profissional',
            ),
            controlAffinity: ListTileControlAffinity.leading,
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('Observações Importantes'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: TextFormField(
              controller: _importantObsController,
              decoration: InputDecoration(
                hintText:
                    'Registre qualquer observação crítica ou que demande atenção especial',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
                prefixIcon: const Icon(
                  Icons.warning_amber,
                  color: Colors.orange,
                ),
              ),
              maxLines: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskOption(
    RiskLevel level,
    String label,
    Color color,
    String description,
  ) {
    final isSelected = _currentRisk == level;

    return InkWell(
      onTap: () => setState(() => _currentRisk = level),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.offBlack,
      ),
    );
  }

  Widget _buildBottomBar(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.offBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão Salvar Rascunho
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _saveEvolution(isDraft: true),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.save_outlined, size: 20),
                label: const Text(
                  'Salvar Rascunho',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botões Cancelar e Finalizar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => _saveEvolution(isDraft: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle, size: 20),
                    label: isLoading
                        ? const SizedBox.shrink()
                        : const Text(
                            'Finalizar Sessão',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addTopic() {
    if (_topicsController.text.isNotEmpty) {
      setState(() {
        _topics.add(_topicsController.text);
        _topicsController.clear();
      });
    }
  }

  void _addIntervention() {
    if (_interventionController.text.isNotEmpty) {
      setState(() {
        _interventions.add(_interventionController.text);
        _interventionController.clear();
      });
    }
  }

  void _saveEvolution({required bool isDraft}) {
    if (_currentSession == null) return;

    final updatedSession = _currentSession!.copyWith(
      status: isDraft ? SessionStatus.draft : SessionStatus.completed,
      patientMood: _moodController.text.isNotEmpty
          ? _moodController.text
          : null,
      topicsDiscussed: _topics,
      sessionNotes: _notesController.text.isNotEmpty
          ? _notesController.text
          : null,
      observedBehavior: _behaviorController.text.isNotEmpty
          ? _behaviorController.text
          : null,
      interventionsUsed: _interventions,
      resourcesUsed: _resourcesController.text.isNotEmpty
          ? _resourcesController.text
          : null,
      homework: _homeworkController.text.isNotEmpty
          ? _homeworkController.text
          : null,
      patientReactions: _reactionsController.text.isNotEmpty
          ? _reactionsController.text
          : null,
      progressObserved: _progressController.text.isNotEmpty
          ? _progressController.text
          : null,
      difficultiesIdentified: _difficultiesController.text.isNotEmpty
          ? _difficultiesController.text
          : null,
      nextSteps: _nextStepsController.text.isNotEmpty
          ? _nextStepsController.text
          : null,
      nextSessionGoals: _nextGoalsController.text.isNotEmpty
          ? _nextGoalsController.text
          : null,
      needsReferral: _needsReferral,
      currentRisk: _currentRisk,
      importantObservations: _importantObsController.text.isNotEmpty
          ? _importantObsController.text
          : null,
      updatedAt: DateTime.now(),
    );

    context.read<SessionsBloc>().add(UpdateSession(updatedSession));
  }
}
