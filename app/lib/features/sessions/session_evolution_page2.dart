import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc.dart';
import 'package:terafy/features/sessions/bloc/sessions_bloc_models.dart';
import 'package:terafy/features/sessions/models/session.dart';
import 'package:terafy/features/sessions/models/session_mapper.dart';
import 'package:terafy/features/sessions/services/session_transcription_service.dart';

class SessionEvolutionPageV2 extends StatelessWidget {
  final String sessionId;
  final String patientName;
  final Session? existingSession;

  const SessionEvolutionPageV2({super.key, required this.sessionId, required this.patientName, this.existingSession});

  @override
  Widget build(BuildContext context) {
    final container = DependencyContainer();
    return BlocProvider(
      create: (context) => SessionsBloc(
        getSessionsUseCase: container.getSessionsUseCase,
        getSessionUseCase: container.getSessionUseCase,
        createSessionUseCase: container.createSessionUseCase,
        updateSessionUseCase: container.updateSessionUseCase,
        getAppointmentUseCase: container.getAppointmentUseCase,
        updateAppointmentUseCase: container.updateAppointmentUseCase,
        getTransactionUseCase: container.getTransactionUseCase,
        createTransactionUseCase: container.createTransactionUseCase,
      )..add(LoadSessionDetails(sessionId)),
      child: _SessionEvolutionV2Content(
        sessionId: sessionId,
        patientName: patientName,
        existingSession: existingSession,
      ),
    );
  }
}

class _SessionEvolutionV2Content extends StatefulWidget {
  final String sessionId;
  final String patientName;
  final Session? existingSession;

  const _SessionEvolutionV2Content({required this.sessionId, required this.patientName, this.existingSession});

  @override
  State<_SessionEvolutionV2Content> createState() => _SessionEvolutionV2ContentState();
}

class _SessionEvolutionV2ContentState extends State<_SessionEvolutionV2Content> {
  final _notesController = TextEditingController();
  final _transcriptionController = TextEditingController();
  final _reportController = TextEditingController();

  Session? _currentSession;
  String _patientMood = '';
  String _progressLevel = 'stable';
  RiskLevel _currentRisk = RiskLevel.low;

  // Transcrição STT
  final _sttService = SessionTranscriptionService();
  bool _sttAvailable = false;
  bool _isListening = false;
  String _liveText = '';
  String _accumulatedTranscription = '';

  // AI
  bool _isAnalyzing = false;

  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null) {
      _loadExistingData(widget.existingSession!);
    }

    // Sincroniza digitação manual com a transcrição acumulada
    _transcriptionController.addListener(() {
      if (!_isListening) {
        _accumulatedTranscription = _transcriptionController.text;
      }
    });

    // Auto-save a cada 15 segundos
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _saveDraft(isAutoSave: true);
    });
  }

  Future<bool> _ensureSTTInitialized() async {
    if (_sttAvailable) return true;
    try {
      final available = await _sttService.init();
      if (mounted) {
        setState(() => _sttAvailable = available);
      }
      return available;
    } catch (e) {
      debugPrint('Erro inicializando STT: $e');
      if (mounted) {
        setState(() => _sttAvailable = false);
        if (e.toString().contains('MissingPluginException')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Falha de Plugin: Seu navegador não suporta captura de voz ou está bloqueando a API de Microfone (requer HTTPS ou permissão do site).',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 7),
            ),
          );
        }
      }
      return false;
    }
  }

  void _loadExistingData(Session session) {
    _currentSession = session;
    _notesController.text = session.freeNotes ?? '';
    _accumulatedTranscription = session.transcription ?? '';
    _transcriptionController.text = _accumulatedTranscription;
    _reportController.text = session.sessionReport ?? '';
    _patientMood = session.patientMood ?? '';
    _progressLevel = session.progressLevel ?? 'stable';
    _currentRisk = session.currentRisk;
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _sttService.stopListening();
      setState(() {
        _isListening = false;
        // Finaliza o texto acumulado
        if (_liveText.isNotEmpty) {
          if (_accumulatedTranscription.isNotEmpty) {
            _accumulatedTranscription += ' $_liveText';
          } else {
            _accumulatedTranscription = _liveText;
          }
          _transcriptionController.text = _accumulatedTranscription;
          _liveText = '';
        }
      });
    } else {
      try {
        final available = await _ensureSTTInitialized();
        if (!available) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ops, não foi possível acessar o microfone neste dispositivo.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _isListening = true;
          _liveText = '';
        });
        await _sttService.startListening(
          onResult: (text) {
            if (mounted) {
              setState(() => _liveText = text);
            }
          },
          onChunkDone: () {
            // Quando o STT auto-pausar (web), salva o trecho e recomeça
            if (mounted && _liveText.isNotEmpty) {
              setState(() {
                if (_accumulatedTranscription.isNotEmpty) {
                  _accumulatedTranscription += ' $_liveText';
                } else {
                  _accumulatedTranscription = _liveText;
                }
                _transcriptionController.text = _accumulatedTranscription;
                _liveText = '';
              });
            }
          },
        );
      } catch (e) {
        debugPrint('Erro ao tentar ouvir STT: $e');
        if (mounted) {
          setState(() {
            _isListening = false;
            _sttAvailable = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro no microfone: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  // ── AI ─────────────────────────────────────────────

  Future<void> _organizeWithAI() async {
    final freeNotes = _notesController.text;
    final transcription = _transcriptionController.text;

    if (freeNotes.isEmpty && transcription.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Adicione anotações ou transcrição antes de organizar com a IA.')));
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final repository = DependencyContainer().sessionRepository;
      final sessionId = int.parse(widget.sessionId);

      final result = await repository.analyzeTextV2(sessionId, freeNotes: freeNotes, transcription: transcription);

      if (!mounted) return;

      setState(() {
        if (result['sessionReport'] != null) {
          _reportController.text = result['sessionReport'];
        }
        if (result['patientMood'] != null) {
          _patientMood = result['patientMood'];
        }
        if (result['progressLevel'] != null) {
          _progressLevel = result['progressLevel'];
        }
        if (result['currentRisk'] != null) {
          final riskStr = result['currentRisk'].toString().toLowerCase();
          if (riskStr == 'high')
            _currentRisk = RiskLevel.high;
          else if (riskStr == 'medium')
            _currentRisk = RiskLevel.medium;
          else
            _currentRisk = RiskLevel.low;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão organizada com sucesso! Você pode editar o relato abaixo.'),
          backgroundColor: Colors.green,
        ),
      );
      // Remove o Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao organizar com IA: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _saveDraft({bool isAutoSave = false}) async {
    if (_currentSession == null) return;

    // Se estivermos ouvindo e há texto em live, garanta que não seja perdido
    final live = _liveText.isNotEmpty ? ' $_liveText' : '';

    final currentNotes = _notesController.text;
    final currentTranscription = _transcriptionController.text + live;
    final currentReport = _reportController.text;

    final updatedSession = _currentSession!.copyWith(
      status: SessionStatus.draft,
      freeNotes: currentNotes.isNotEmpty ? currentNotes : null,
      transcription: currentTranscription.isNotEmpty ? currentTranscription.trim() : null,
      sessionReport: currentReport.isNotEmpty ? currentReport : null,
      patientMood: _patientMood.isNotEmpty ? _patientMood : null,
      progressLevel: _progressLevel,
      currentRisk: _currentRisk,
      updatedAt: DateTime.now(),
    );

    if (isAutoSave) {
      try {
        final useCase = DependencyContainer().updateSessionUseCase;
        await useCase(int.parse(updatedSession.id), mapToDomainSession(updatedSession));
        /* Silencioso no UI para não interromper digitacão */
      } catch (e) {
        debugPrint('Auto-save falhou silenciosamente: $e');
      }
    } else {
      context.read<SessionsBloc>().add(UpdateSession(updatedSession));
    }
  }

  Future<void> _shutdownSTTAndTimers() async {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    if (_isListening) {
      await _sttService.stopListening();
    }
  }

  Future<void> _finalizeSession() async {
    if (_currentSession == null) return;

    await _shutdownSTTAndTimers();

    final live = _liveText.isNotEmpty ? ' $_liveText' : '';

    final currentNotes = _notesController.text;
    final currentTranscription = _transcriptionController.text + live;
    final currentReport = _reportController.text;

    final updatedSession = _currentSession!.copyWith(
      status: SessionStatus.completed,
      freeNotes: currentNotes.isNotEmpty ? currentNotes : null,
      transcription: currentTranscription.isNotEmpty ? currentTranscription.trim() : null,
      sessionReport: currentReport.isNotEmpty ? currentReport : null,
      patientMood: _patientMood.isNotEmpty ? _patientMood : null,
      progressLevel: _progressLevel,
      currentRisk: _currentRisk,
      updatedAt: DateTime.now(),
    );

    context.read<SessionsBloc>().add(UpdateSession(updatedSession));
  }

  void _simulateSessionData() {
    setState(() {
      _notesController.text =
          "Paciente (João) relatou forte ansiedade ao longo da semana no trabalho, principalmente relacionada a prazos curtos.\nAplicamos técnicas de respiração diafragmática. Ele pareceu mais calmo ao final da sessão e combinamos de ele tentar reproduzir em casa durante crises.";

      final simTranscription =
          "Terapeuta: E como foi essa semana no trabalho?\nJoão: Ah, foi bem estressante. Tive que entregar um projeto na quinta e mal consegui dormir. A cobrança estava altíssima.\nTerapeuta: Entendo, a pressão destes prazos curtos te afetou bastante.\nJoão: Sim, senti aquela palpitação de novo, parecia que não ia dar tempo e que eu ia travar.\nTerapeuta: Perfeito, vamos focar em como podemos reagir melhor a essa pressão então, lembra daquele exercício de respiração focado no diafragma?";
      _accumulatedTranscription = simTranscription;
      _transcriptionController.text = simTranscription;

      _patientMood = 'Ansioso'; // Will fall back or not map perfectly to icons, let's use 'Triste' or just leave it
      _patientMood = 'Triste'; // Represents stressed here
    });

    // Auto-save the simulated data right away
    _saveDraft(isAutoSave: true);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _sttService.dispose();
    _notesController.dispose();
    _transcriptionController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionsBloc, SessionsState>(
      listener: (context, state) {
        if (state is SessionDetailsLoaded && _currentSession == null) {
          setState(() => _loadExistingData(state.session));
        } else if (state is SessionUpdated) {
          final isCompleted = state.session.status == SessionStatus.completed;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isCompleted ? 'Sessão finalizada com sucesso!' : 'Rascunho salvo!'),
              backgroundColor: isCompleted ? Colors.green : Colors.amber,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is SessionsError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        final isLoading = state is SessionsLoading;
        return WillPopScope(
          onWillPop: () async {
            await _shutdownSTTAndTimers();
            return true;
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF6F7FB),
            appBar: _buildAppBar(),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNotesSection(),
                        const SizedBox(height: 16),
                        _buildTranscriptionSection(),
                        const SizedBox(height: 16),
                        // Seção Dinâmica: só exibe se houver relato sendo digitado ou gerado
                        _buildReportSection(),
                        const SizedBox(height: 16),
                        _buildClassificationsSection(),
                      ],
                    ),
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

  PreferredSizeWidget _buildAppBar() {
    final isDraft = _currentSession?.status == SessionStatus.draft;
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Registro de Sessão', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              if (isDraft) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    'RASCUNHO',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                  ),
                ),
              ],
            ],
          ),
          Text(widget.patientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.auto_fix_high), tooltip: 'Simular Dados', onPressed: _simulateSessionData),
      ],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          await _shutdownSTTAndTimers();
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  // Seção 1: Notas livres
  Widget _buildNotesSection() {
    return _SectionCard(
      icon: Icons.edit_note_rounded,
      iconColor: AppColors.primary,
      title: 'Minhas anotações',
      subtitle: 'Escreva livremente durante a sessão',
      child: TextField(
        controller: _notesController,
        maxLines: 8,
        style: const TextStyle(fontSize: 15, height: 1.6),
        decoration: InputDecoration(
          hintText: 'Ex: Paciente mencionou dificuldades em dormir. Realizamos exercício de respiração...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          fillColor: const Color(0xFFF0F2FA),
          filled: true,
        ),
      ),
    );
  }

  // Seção 2: Transcrição ao vivo
  Widget _buildTranscriptionSection() {
    return _SectionCard(
      icon: Icons.mic_rounded,
      iconColor: _isListening ? Colors.red : Colors.teal,
      title: 'Transcrição ao vivo',
      subtitle: 'Toque para iniciar/parar a transcrição',
      trailing: GestureDetector(
        onTap: _toggleListening,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isListening ? Colors.red : Colors.teal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                _isListening ? 'Parar' : 'Gravar',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador pulsante quando ouvindo
          if (_isListening)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PulsingDot(),
                  const SizedBox(width: 6),
                  Text(
                    'Ouvindo...',
                    style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          // Campo editável da transcrição
          TextField(
            controller: _transcriptionController,
            maxLines: 5,
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'A transcrição irá aparecer aqui...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              fillColor: _isListening ? Colors.red.withOpacity(0.03) : const Color(0xFFF0F2FA),
              filled: true,
            ),
          ),
          if (_isListening && _liveText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '← texto ao vivo: $_liveText',
              style: TextStyle(fontSize: 12, color: Colors.teal[700], fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  // Seção 3: Classificações rápidas
  Widget _buildClassificationsSection() {
    return _SectionCard(
      icon: Icons.insights_rounded,
      iconColor: Colors.deepPurple,
      title: 'Classificações rápidas',
      subtitle: 'Humor, evolução e risco desta sessão',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Humor
          _buildLabel('Estado emocional do paciente'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MoodIcon(
                icon: Icons.sentiment_very_dissatisfied,
                color: const Color(0xFFEF5350), // Red
                selected: _patientMood == 'Raiva',
                onTap: () => setState(() => _patientMood = 'Raiva'),
              ),
              _MoodIcon(
                icon: Icons.sentiment_dissatisfied,
                color: const Color(0xFFFFA726), // Orange
                selected: _patientMood == 'Triste',
                onTap: () => setState(() => _patientMood = 'Triste'),
              ),
              _MoodIcon(
                icon: Icons.sentiment_neutral,
                color: const Color(0xFFFFEE58), // Yellow
                selected: _patientMood == 'Neutro',
                onTap: () => setState(() => _patientMood = 'Neutro'),
              ),
              _MoodIcon(
                icon: Icons.sentiment_satisfied,
                color: const Color(0xFF9CCC65), // Light Green
                selected: _patientMood == 'Feliz',
                onTap: () => setState(() => _patientMood = 'Feliz'),
              ),
              _MoodIcon(
                icon: Icons.sentiment_very_satisfied,
                color: const Color(0xFF66BB6A), // Dark Green
                selected: _patientMood == 'Muito Feliz',
                onTap: () => setState(() => _patientMood = 'Muito Feliz'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Evolução
          _buildLabel('Evolução nesta sessão'),
          const SizedBox(height: 8),
          Row(
            children: [
              _ProgressChip(
                label: 'Melhorando',
                icon: Icons.trending_up,
                color: Colors.green,
                selected: _progressLevel == 'improving',
                onTap: () => setState(() => _progressLevel = 'improving'),
              ),
              const SizedBox(width: 8),
              _ProgressChip(
                label: 'Estável',
                icon: Icons.trending_flat,
                color: Colors.blue,
                selected: _progressLevel == 'stable',
                onTap: () => setState(() => _progressLevel = 'stable'),
              ),
              const SizedBox(width: 8),
              _ProgressChip(
                label: 'Regredindo',
                icon: Icons.trending_down,
                color: Colors.orange,
                selected: _progressLevel == 'regressing',
                onTap: () => setState(() => _progressLevel = 'regressing'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Risco
          _buildLabel('Nível de risco'),
          const SizedBox(height: 8),
          Row(
            children: [
              _RiskChip(
                label: 'Baixo',
                color: Colors.green,
                level: RiskLevel.low,
                current: _currentRisk,
                onTap: () => setState(() => _currentRisk = RiskLevel.low),
              ),
              const SizedBox(width: 8),
              _RiskChip(
                label: 'Médio',
                color: Colors.orange,
                level: RiskLevel.medium,
                current: _currentRisk,
                onTap: () => setState(() => _currentRisk = RiskLevel.medium),
              ),
              const SizedBox(width: 8),
              _RiskChip(
                label: 'Alto',
                color: Colors.red,
                level: RiskLevel.high,
                current: _currentRisk,
                onTap: () => setState(() => _currentRisk = RiskLevel.high),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
    );
  }

  Widget _buildReportSection() {
    if (_reportController.text.isEmpty && !_isAnalyzing) return const SizedBox.shrink();

    return _SectionCard(
      icon: Icons.auto_awesome,
      iconColor: Colors.deepPurple,
      title: 'Relatório Gerado (Markdown)',
      subtitle: 'Edite o conteúdo antes de finalizar a sessão',
      child: TextField(
        controller: _reportController,
        maxLines: null,
        minLines: 5,
        style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'O relatório gerado pela IA aparecerá aqui para você revisar e editar...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          fillColor: const Color(0xFFF9FAFC),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão IA Principal (Organizar Sessão)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isLoading || _isAnalyzing) ? null : _organizeWithAI,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                      )
                    : const Text('✨', style: TextStyle(fontSize: 18)),
                label: Text(
                  _isAnalyzing ? 'Organizando...' : 'Organizar Sessão',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Botão Finalizar Sessão
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isLoading || _isAnalyzing) ? null : _finalizeSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Finalizar Sessão', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            // Linha inferior: Cancelar + Salvar rascunho
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: (isLoading || _isAnalyzing)
                        ? null
                        : () async {
                            await _shutdownSTTAndTimers();
                            if (mounted) Navigator.of(context).pop();
                          },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (isLoading || _isAnalyzing) ? null : () => _saveDraft(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.amber[800],
                      side: BorderSide(color: Colors.amber[300]!),
                    ),
                    icon: isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Rascunho', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), child: child),
        ],
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ProgressChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : const Color(0xFFF0F2FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  final String label;
  final Color color;
  final RiskLevel level;
  final RiskLevel current;
  final VoidCallback onTap;

  const _RiskChip({
    required this.label,
    required this.color,
    required this.level,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = current == level;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : const Color(0xFFF0F2FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}

class _MoodIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _MoodIcon({required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Fundo mais forte se selecionado, suave se não selecionado
          color: color.withOpacity(selected ? 1.0 : 0.3),
          boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)] : null,
        ),
        padding: const EdgeInsets.all(10), // Aumentando área touch
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            // Ícone maior e branco se selecionado, senão colorido escuro
            size: selected ? 38 : 32,
            color: selected ? Colors.white : color.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}
