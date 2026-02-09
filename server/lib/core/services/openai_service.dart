import 'dart:convert';
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';
import 'package:server/features/ai_config/models/therapist_profile_model.dart';

import 'package:server/core/config/env_config.dart';
import 'package:common/common.dart';

class OpenAIService {
  OpenAIService() {
    // A chave deve ser configurada via variável de ambiente OPENAI_API_KEY
    // Usamos EnvConfig para garantir que pegamos do .env se existir
    final apiKey = EnvConfig.get('OPENAI_API_KEY');
    if (apiKey != null && apiKey.isNotEmpty) {
      OpenAI.apiKey = apiKey;
    } else {
      AppLogger.warning('⚠️  OPENAI_API_KEY não configurada! As funcionalidades de IA falharão.');
    }
  }

  /// Transcreve um arquivo de áudio usando o modelo Whisper
  Future<String> transcribeAudio(File audioFile) async {
    try {
      final apiKey = EnvConfig.get('OPENAI_API_KEY');
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('OPENAI_API_KEY falhou. Verifique se a variável de ambiente está configurada.');
      }

      // Explicitly set the key before accessing the instance to ensure it's initialized
      OpenAI.apiKey = apiKey;

      print('Transcrevendo arquivo: ${audioFile.path} (${await audioFile.length()} bytes)');

      // O modelo padrão é o whisper-1
      final transcription = await OpenAI.instance.audio.createTranscription(file: audioFile, model: "whisper-1");

      final text = (transcription as dynamic).text;
      print('=== TRANSCRIPTION RAW ===');
      print(text);
      print('========================');
      return text;
    } catch (e) {
      print('Erro no OpenAI: $e');
      throw Exception('Falha na transcrição do áudio: $e');
    }
  }

  /// Analisa o texto da sessão e extrai os campos estruturados usando GPT-4o
  Future<Map<String, dynamic>> analyzeSession({
    required String transcription,
    required TherapistProfileModel therapistProfile,
    required String patientName,
  }) async {
    try {
      final systemPrompt = _buildSystemPrompt(therapistProfile);
      final userPrompt = "Paciente: $patientName\n\nTranscrição da Sessão:\n$transcription";

      // Ensure API Key is set (redundant but safe)
      final apiKey = EnvConfig.get('OPENAI_API_KEY');
      if (apiKey != null && apiKey.isNotEmpty) {
        OpenAI.apiKey = apiKey;
      }

      // Usamos o response_format json_object para garantir um JSON válido
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4o",
        responseFormat: {"type": "json_object"},
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt)],
            role: OpenAIChatMessageRole.system,
          ),
          OpenAIChatCompletionChoiceMessageModel(
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(userPrompt)],
            role: OpenAIChatMessageRole.user,
          ),
        ],
        temperature: 0.2, // Baixa temperatura para ser mais determinístico e fiel aos fatos
      );

      final content = chatCompletion.choices.first.message.content?.first.text;

      if (content == null) {
        throw Exception('GPT retornou conteúdo vazio');
      }

      return _parseJson(content);
    } catch (e) {
      throw Exception('Falha na análise da sessão: $e');
    }
  }

  Map<String, dynamic> _parseJson(String jsonString) {
    return jsonDecode(jsonString);
  }

  String _buildSystemPrompt(TherapistProfileModel profile) {
    // Constrói o prompt com base no perfil do terapeuta para dar contexto
    final sb = StringBuffer();
    sb.writeln("Você é um assistente clínico especializado em psicologia e psiquiatria.");
    sb.writeln(
      "Sua tarefa é analisar a transcrição de uma sessão terapêutica e extrair informações para o prontuário (Evolução).",
    );
    sb.writeln("");

    // Contexto do Terapeuta
    sb.writeln("CONTEXTO DO TERAPEUTA:");
    if (profile.approaches.isNotEmpty) {
      sb.writeln("- Abordagem: ${profile.approaches.join(', ')}");
    }
    if (profile.therapeuticPosture.isNotEmpty) {
      sb.writeln("- Postura: ${profile.therapeuticPosture}");
    }
    if (profile.sessionPriorities.isNotEmpty) {
      sb.writeln("- Foco: ${profile.sessionPriorities.join(', ')}");
    }

    sb.writeln("");
    sb.writeln("INSTRUÇÕES:");
    sb.writeln("1. Analise o texto transcrever e preencha os campos abaixo.");
    sb.writeln("2. Use linguagem clínica apropriada, mas mantenha o tone: ${profile.aiTone}");
    sb.writeln(
      "3. Se uma informação não estiver explícita, deixe o campo como null ou infira com cautela marcando como 'inferido'.",
    );
    sb.writeln("4. Responda APENAS em formato JSON.");

    sb.writeln("");
    sb.writeln("SCHEMA DO JSON DE RESPOSTA:");
    sb.writeln("""
{
  "patientMood": "string (Descreva o estado emocional/humor do paciente durante a sessão)",
  "topicsDiscussed": ["string", "string"],
  "sessionNotes": "string (Resumo narrativo principal da sessão, integrando os pontos chave)",
  "observedBehavior": "string (Descrição da linguagem não-verbal, postura, tom de voz, contato visual)",
  "interventionsUsed": ["string", "string"],
  "resourcesUsed": "string (Materiais, testes, escalas ou ferramentas utilizadas)",
  "homework": "string (Tarefas, reflexões ou exercícios solicitados para casa)",
  "patientReactions": "string (Como o paciente reagiu às intervenções ou temas difíceis)",
  "progressObserved": "string (Evolução notada em relação às queixas iniciais ou sessões anteriores)",
  "difficultiesIdentified": "string (Barreiras, resistências ou novos problemas identificados)",
  "nextSteps": "string (Planejamento terapêutico imediato)",
  "nextSessionGoals": "string (Objetivos específicos para o próximo encontro)",
  "needsReferral": boolean (true se houver necessidade de encaminhar para psiquiatra ou outra especialidade),
  "currentRisk": "low" | "medium" | "high",
  "importantObservations": "string (Pontos críticos, alertas ou observações que não se encaixam nos outros campos)"
}
""");

    if (profile.aiAnalysisFocus.isNotEmpty) {
      sb.writeln("FOCO ESPECÍFICO DA ANÁLISE: ${profile.aiAnalysisFocus}");
    }

    return sb.toString();
  }
}
