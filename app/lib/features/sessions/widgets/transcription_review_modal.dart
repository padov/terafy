import 'package:flutter/material.dart';
import 'package:terafy/common/app_colors.dart';

class TranscriptionReviewModal extends StatelessWidget {
  final String transcription;
  final Map<String, dynamic> analysisResult;

  const TranscriptionReviewModal({super.key, required this.transcription, required this.analysisResult});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.rate_review_outlined, color: AppColors.primary),
          SizedBox(width: 12),
          Text('Revisão da Transcrição', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500, // Altura fixa para acomodar as abas
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(25)),
                child: TabBar(
                  indicator: BoxDecoration(borderRadius: BorderRadius.circular(25), color: AppColors.primary),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: "Transcrição"),
                    Tab(text: "Dados Extraídos"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Transcrição
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          transcription,
                          style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.offBlack),
                        ),
                      ),
                    ),

                    // Tab 2: Dados Extraídos (Preview Markdown)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _generateMarkdownPreview(),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.offBlack,
                            fontFamily: 'monospace', // Monospaced para sensação de markdown/código
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Descartar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.check, size: 20),
          label: const Text('Confirmar e Preencher'),
        ),
      ],
    );
  }

  String _generateMarkdownPreview() {
    final buffer = StringBuffer();

    void addField(String label, dynamic value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      if (value is List && value.isEmpty) return;

      buffer.writeln('### $label');
      if (value is List) {
        for (var item in value) {
          buffer.writeln('- $item');
        }
      } else {
        buffer.writeln(value.toString());
      }
      buffer.writeln(''); // Separador de linha
    }

    addField('Humor/Estado Emocional', analysisResult['patientMood']);
    addField('Temas Abordados', analysisResult['topicsDiscussed']);
    addField('Notas da Sessão', analysisResult['sessionNotes']);
    addField('Comportamento Observado', analysisResult['observedBehavior']);
    addField('Intervenções', analysisResult['interventionsUsed']);
    addField('Recursos Utilizados', analysisResult['resourcesUsed']);
    addField('Tarefas de Casa', analysisResult['homework']);
    addField('Reações do Paciente', analysisResult['patientReactions']);
    addField('Progresso', analysisResult['progressObserved']);
    addField('Dificuldades', analysisResult['difficultiesIdentified']);
    addField('Próximos Passos', analysisResult['nextSteps']);
    addField('Objetivos Próxima Sessão', analysisResult['nextSessionGoals']);

    // Risk
    if (analysisResult['currentRisk'] != null) {
      buffer.writeln('### Risco Atual');
      buffer.writeln('**${analysisResult['currentRisk'].toString().toUpperCase()}**');
      buffer.writeln('');
    }

    // Referral
    if (analysisResult['needsReferral'] == true) {
      buffer.writeln('### Encaminhamento');
      buffer.writeln('⚠️ **Necessita Encaminhamento**');
      buffer.writeln('');
    }

    addField('Observações Importantes', analysisResult['importantObservations']);

    if (buffer.isEmpty) {
      return "Nenhum dado estruturado foi extraído.";
    }

    return buffer.toString();
  }
}
