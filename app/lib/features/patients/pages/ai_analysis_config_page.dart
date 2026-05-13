import 'package:common/common.dart' hide Patient;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/ai_config/models/therapist_profile_model.dart';
import 'package:terafy/features/patients/models/patient.dart';
import 'package:terafy/features/patients/models/ai_analysis.dart';
import 'package:terafy/features/patients/pages/ai_analysis_detail_page.dart';

enum AiAnalysisType { session, overview, evolution, situation }

class AiAnalysisConfigPage extends StatefulWidget {
  final Patient patient;

  const AiAnalysisConfigPage({super.key, required this.patient});

  @override
  State<AiAnalysisConfigPage> createState() => _AiAnalysisConfigPageState();
}

class _AiAnalysisConfigPageState extends State<AiAnalysisConfigPage> {
  AiAnalysisType _selectedType = AiAnalysisType.session;
  bool _isLoading = true;
  String? _errorMessage;

  // Data
  List<Session> _sessions = [];
  Map<String, dynamic>? _anamnesisData;
  Therapist? _therapist;

  // Inputs
  Session? _selectedSession;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _situationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _situationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final patientIdInt = int.tryParse(widget.patient.id);
      if (patientIdInt == null) throw Exception('ID do paciente inválido');

      // Fetch Sessions
      final sessions = await DependencyContainer().sessionRepository.fetchSessions(patientId: patientIdInt);
      // Sort by date desc
      sessions.sort((a, b) => b.scheduledStartTime.compareTo(a.scheduledStartTime));

      // Fetch Anamnesis
      final anamnesis = await DependencyContainer().anamnesisRepository.fetchAnamnesisByPatientId(widget.patient.id);

      // Fetch Therapist
      final therapistMap = await DependencyContainer().therapistRepository.getCurrentTherapist();
      final therapist = Therapist.fromMap(therapistMap);

      setState(() {
        _sessions = sessions;
        if (sessions.isNotEmpty) _selectedSession = sessions.first;
        _anamnesisData = anamnesis?.data;
        _therapist = therapist;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAndShowPrompt() async {
    if (_anamnesisData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Anamnese não encontrada (contexto base necessário)')));
      return;
    }

    // Validate inputs based on type
    if (_selectedType == AiAnalysisType.session && _selectedSession == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selecione uma sessão')));
      return;
    }

    if (_selectedType == AiAnalysisType.situation && _situationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Descreva a situação')));
      return;
    }

    // Prepare variables
    String therapistConfigText = '';
    if (_therapist?.aiConfig != null && _therapist!.aiConfig!.isNotEmpty) {
      try {
        final profile = TherapistProfileModel.fromJson(_therapist!.aiConfig!);
        therapistConfigText =
            '## 📋 Configuração do Terapeuta (System Prompt)\n\n' + _formatTherapistProfile(profile) + '\n\n---\n';
      } catch (e) {
        therapistConfigText = '> ⚠️ **Aviso**: Erro ao processar configuração do terapeuta: $e\n\n';
      }
    } else {
      therapistConfigText = '> ⚠️ **Aviso**: Nenhuma configuração de IA encontrada para este terapeuta.\n\n';
    }

    String anamnesisText = _formatAnamnesis(_anamnesisData ?? {});

    // Load base prompt
    String prompt = '';

    // Show loading dialog for generation (re-used later)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text('Gerando análise IA...')]),
      ),
    );

    try {
      final baseTemplate = await rootBundle.loadString('assets/prompts/analysis_base.md');
      String specificData = '';
      String questionSection = '';

      if (_questionController.text.isNotEmpty) {
        questionSection = '\n### 💭 Pergunta ou Foco Específico\n\n> ${_questionController.text}\n';
      }

      switch (_selectedType) {
        case AiAnalysisType.session:
          final sessionTemplate = await rootBundle.loadString('assets/prompts/analysis_session.md');
          specificData = sessionTemplate
              .replaceAll('{{session_data}}', _formatSession(_selectedSession!))
              .replaceAll('{{question_section}}', questionSection);
          break;
        case AiAnalysisType.overview:
          final overviewTemplate = await rootBundle.loadString('assets/prompts/analysis_overview.md');
          final recentSessions = _sessions.take(5).toList();
          final recentSessionsData = StringBuffer();
          for (var s in recentSessions) {
            recentSessionsData.writeln(
              '- **${DateFormat("dd/MM").format(s.scheduledStartTime)}**: ${s.sessionNotes ?? "Sem notas"} *(Humor: ${s.patientMood ?? "-"})*',
            );
          }
          final treatmentStart = widget.patient.treatmentStartDate != null
              ? DateFormat("dd/MM/yyyy").format(widget.patient.treatmentStartDate!)
              : "-";

          specificData = overviewTemplate
              .replaceAll('{{total_sessions}}', widget.patient.totalSessions.toString())
              .replaceAll('{{treatment_start_date}}', treatmentStart)
              .replaceAll('{{recent_sessions_count}}', recentSessions.length.toString())
              .replaceAll('{{recent_sessions_data}}', recentSessionsData.toString())
              .replaceAll('{{question_section}}', questionSection);
          break;
        case AiAnalysisType.evolution:
          final evolutionTemplate = await rootBundle.loadString('assets/prompts/analysis_evolution.md');
          final sortedSessions = List<Session>.from(_sessions)
            ..sort((a, b) => a.scheduledStartTime.compareTo(b.scheduledStartTime));
          final evolutionData = StringBuffer();
          for (var s in sortedSessions) {
            evolutionData.writeln(
              '### Sessão ${s.sessionNumber} - ${DateFormat("dd/MM/yyyy").format(s.scheduledStartTime)}\n',
            );
            evolutionData.writeln('- **Notas:** ${s.sessionNotes}');
            evolutionData.writeln('- **Humor:** ${s.patientMood}');
            evolutionData.writeln('- **Evolução observada:** ${s.progressObserved ?? "-"}\n');
          }
          specificData = evolutionTemplate
              .replaceAll('{{evolution_data}}', evolutionData.toString())
              .replaceAll('{{question_section}}', questionSection);
          break;
        case AiAnalysisType.situation:
          final situationTemplate = await rootBundle.loadString('assets/prompts/analysis_situation.md');
          specificData = situationTemplate
              .replaceAll('{{situation_data}}', _situationController.text)
              .replaceAll('{{question_section}}', questionSection);
          break;
      }

      prompt = baseTemplate
          .replaceAll('{{therapist_config}}', therapistConfigText)
          .replaceAll('{{anamnesis}}', anamnesisText)
          .replaceAll('{{specific_data}}', specificData);
    } catch (e) {
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar templates de prompt. $e')));
      return;
    }

    try {
      // Call backend API
      final patientIdInt = int.tryParse(widget.patient.id);
      if (patientIdInt == null) throw Exception('ID do paciente inválido');

      final response = await DependencyContainer().aiAnalysisRepository.generateAnalysis(
        patientId: patientIdInt,
        analysisType: _getAnalysisTypeString(_selectedType),
        prompt: prompt,
        sessionId: _selectedSession?.id,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Parse response and navigate to detail page
      final analysis = AiAnalysis.fromJson(response);

      // Navigate to detail page
      Navigator.push(context, MaterialPageRoute(builder: (context) => AiAnalysisDetailPage(analysis: analysis))).then((
        _,
      ) {
        // Pop back to dashboard after viewing with refresh signal
        Navigator.pop(context, true);
      });
    } catch (e) {
      // Close loading dialog safely
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Debug: print full error
      print('ERRO AO GERAR ANÁLISE: $e');
      print('TIPO DO ERRO: ${e.runtimeType}');

      // Extract clean error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      // Show error only if still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 8),
            action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
          ),
        );
      }
    }
  }

  String _getAnalysisTypeString(AiAnalysisType type) {
    // Map to database enum values
    switch (type) {
      case AiAnalysisType.session:
        return 'individual_session_analysis';
      case AiAnalysisType.overview:
        return 'patient_overview';
      case AiAnalysisType.evolution:
        return 'evolution_analysis';
      case AiAnalysisType.situation:
        return 'specific_situation';
    }
  }

  String _formatAnamnesis(Map<String, dynamic> data) {
    if (data.isEmpty) return "*Dados de anamnese não disponíveis.*";
    final buffer = StringBuffer();
    data.forEach((key, value) => buffer.writeln('- **$key:** $value'));
    return buffer.toString();
  }

  String _formatSession(Session session) {
    return '''
- **Data:** ${DateFormat("dd/MM/yyyy HH:mm").format(session.scheduledStartTime)}
- **Número da Sessão:** ${session.sessionNumber}
- **Notas da Sessão:** ${session.sessionNotes ?? "N/A"}
- **Humor do Paciente:** ${session.patientMood ?? "N/A"}
- **Comportamento Observado:** ${session.observedBehavior ?? "N/A"}
- **Intervenções Utilizadas:** ${session.interventionsUsed.join(", ")}
- **Próximos Passos:** ${session.nextSteps ?? "N/A"}
''';
  }

  String _formatTherapistProfile(TherapistProfileModel profile) {
    final buffer = StringBuffer();
    buffer.writeln('### 🎓 Abordagem Teórica');
    buffer.writeln();
    if (profile.approaches.isNotEmpty) buffer.writeln('- **Abordagens:** ${profile.approaches.join(", ")}');
    if (profile.approachDescription.isNotEmpty) buffer.writeln('- **Descrição:** ${profile.approachDescription}');
    if (profile.frequentTechniques.isNotEmpty)
      buffer.writeln('- **Técnicas Frequentes:** ${profile.frequentTechniques}');
    buffer.writeln();

    buffer.writeln('### 💬 Estilo Clínico e Comunicação');
    buffer.writeln();
    if (profile.therapeuticPosture.isNotEmpty)
      buffer.writeln('- **Postura Terapêutica:** ${profile.therapeuticPosture}');
    if (profile.communicationTone.isNotEmpty) buffer.writeln('- **Tom de Comunicação:** ${profile.communicationTone}');
    if (profile.humorUsage.isNotEmpty) buffer.writeln('- **Uso de Humor:** ${profile.humorUsage}');
    if (profile.confrontationStyle.isNotEmpty)
      buffer.writeln('- **Estilo de Confrontação:** ${profile.confrontationStyle}');
    buffer.writeln();

    buffer.writeln('### 🌟 Visão e Valores');
    buffer.writeln();
    if (profile.changeVision.isNotEmpty) buffer.writeln('- **Visão de Mudança:** ${profile.changeVision}');
    if (profile.sufferingNature.isNotEmpty) buffer.writeln('- **Natureza do Sofrimento:** ${profile.sufferingNature}');
    buffer.writeln();

    if (profile.untreatableSituations.isNotEmpty || profile.outOfSessionContact.isNotEmpty) {
      buffer.writeln('### ⚖️ Restrições e Ética');
      buffer.writeln();
      if (profile.untreatableSituations.isNotEmpty)
        buffer.writeln('- **Situações Não Tratáveis:** ${profile.untreatableSituations}');
      if (profile.outOfSessionContact.isNotEmpty)
        buffer.writeln('- **Contato Fora da Sessão:** ${profile.outOfSessionContact}');
      buffer.writeln();
    }

    if (profile.aiAnalysisFocus.isNotEmpty) {
      buffer.writeln('### 🎯 Foco da Análise IA');
      buffer.writeln();
      buffer.writeln('> ${profile.aiAnalysisFocus}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nova Análise IA'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.offBlack, // Assuming this exists or using Colors.black
        elevation: 0.5,
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text('Erro: $_errorMessage', style: TextStyle(color: Colors.red)),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Patient Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(Icons.person, color: AppColors.primary),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.patient.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('ID: ${widget.patient.id}', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  Text(
                    '1. Tipo de Análise',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.offBlack),
                  ),
                  SizedBox(height: 12),
                  _buildAnalysisOptions(),

                  SizedBox(height: 32),

                  Text(
                    '2. Configuração',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.offBlack),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: _buildParametersForm(),
                  ),

                  SizedBox(height: 24),

                  // AI Disclaimer
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'A análise de IA é uma ferramenta de apoio à sua prática clínica. Recomendamos revisar e validar as sugestões com base na sua experiência profissional.',
                            style: TextStyle(fontSize: 13, color: Colors.orange[900], height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _generateAndShowPrompt,
                      icon: Icon(Icons.auto_awesome),
                      label: Text('Gerar Análise (Preview)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalysisOptions() {
    return Column(children: AiAnalysisType.values.map((type) => _buildOptionCard(type)).toList());
  }

  Widget _buildOptionCard(AiAnalysisType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Radio<AiAnalysisType>(
              value: type,
              groupValue: _selectedType,
              onChanged: (val) => setState(() => _selectedType = val!),
              activeColor: AppColors.primary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTypeLabel(type),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(_getTypeDescription(type), style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersForm() {
    // Reuse logic but clean up UI
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedType == AiAnalysisType.session) ...[
          // Wrap in Padding
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Sessão Alvo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          DropdownButtonFormField<Session>(
            isExpanded: true,
            value: _selectedSession,
            items: _sessions
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text('${DateFormat("dd/MM").format(s.scheduledStartTime)} - Sessão ${s.sessionNumber}'),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedSession = val),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          SizedBox(height: 20),
        ],
        if (_selectedType == AiAnalysisType.situation) ...[
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Descreva a Situação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          TextField(
            controller: _situationController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Detelhe o evento, crise ou comportamento...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          SizedBox(height: 20),
        ],

        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Pergunta ou Foco Específico (Opcional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        TextField(
          controller: _questionController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Ex: "Como lidar com a resistência apresentada?"',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(AiAnalysisType type) {
    switch (type) {
      case AiAnalysisType.session:
        return "Análise de Sessão Individual";
      case AiAnalysisType.overview:
        return "Visão Geral do Paciente";
      case AiAnalysisType.evolution:
        return "Análise de Evolução";
      case AiAnalysisType.situation:
        return "Situação Específica";
    }
  }

  String _getTypeDescription(AiAnalysisType type) {
    switch (type) {
      case AiAnalysisType.session:
        return "Analisa uma sessão em profundidade.";
      case AiAnalysisType.overview:
        return "Resumo do caso e progresso recente.";
      case AiAnalysisType.evolution:
        return "Comparativo temporal e tendências.";
      case AiAnalysisType.situation:
        return "Análise de um evento ou crise.";
    }
  }
}
