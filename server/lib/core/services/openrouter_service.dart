import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dart_openai/dart_openai.dart';
import 'package:path/path.dart' as path;
import 'package:server/features/ai_config/models/therapist_profile_model.dart';

import 'package:server/core/config/env_config.dart';
import 'package:common/common.dart';

class OpenRouterService {
  OpenRouterService() {
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

  /// Envia um prompt genérico via OpenRouter e retorna o texto gerado
  Future<String> generateText(String prompt) async {
    final openRouterKey = EnvConfig.get('OPENROUTER_KEY') ?? EnvConfig.get('OPENAI_API_KEY');
    if (openRouterKey == null || openRouterKey.isEmpty) {
      throw Exception('OPENROUTER_KEY não configurada.');
    }

    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openRouterKey',
        'HTTP-Referer': 'https://github.com/marciopadovani/terafy',
        'X-Title': 'Terafy',
      },
      body: jsonEncode({
        'model': 'stepfun/step-3.5-flash:free',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro na API do OpenRouter: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) return '';
    return choices.first['message']['content'].toString();
  }

  /// Analisa o texto da sessão e extrai os campos estruturados usando OpenRouter.ai (gpt-4o)
  Future<Map<String, dynamic>> analyzeSession({
    required String transcription,
    required TherapistProfileModel therapistProfile,
    required String patientName,
  }) async {
    try {
      final systemPrompt = _buildSystemPrompt(therapistProfile);
      final userPrompt = "Paciente: $patientName\n\nTranscrição da Sessão:\n$transcription";

      final openRouterKey = EnvConfig.get('OPENROUTER_KEY') ?? EnvConfig.get('OPENAI_API_KEY');
      if (openRouterKey == null || openRouterKey.isEmpty) {
        throw Exception('OPENROUTER_KEY falhou. Verifique se a variável de ambiente está configurada.');
      }

      final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openRouterKey',
          'HTTP-Referer': 'https://github.com/marciopadovani/terafy', // Identificador da aplicação
          'X-Title': 'Terafy', // Nome da aplicação
        },
        body: jsonEncode({
          'model': 'stepfun/step-3.5-flash:free',
          'response_format': {'type': 'json_object'},
          'temperature': 0.2, // Baixa temperatura para ser mais determinístico e fiel aos fatos
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro na API do OpenRouter: ${response.statusCode} - ${response.body}');
      }

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      final choices = responseBody['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('OpenRouter não retornou choices');
      }

      final content = choices.first['message']['content'] as String?;
      if (content == null) {
        throw Exception('OpenRouter retornou conteúdo vazio');
      }

      return _parseJson(content);
    } catch (e) {
      throw Exception('Falha na análise da sessão: $e');
    }
  }

  Map<String, dynamic> _parseJson(String jsonString) {
    try {
      var cleanedString = jsonString.trim();

      // Tenta achar o primeiro '{' e o último '}' para ignorar textos Markdown fora do JSON
      final startIndex = cleanedString.indexOf('{');
      final endIndex = cleanedString.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
        cleanedString = cleanedString.substring(startIndex, endIndex + 1);
      } else {
        // Fallback pro método antigo de só tirar crases das pontas
        if (cleanedString.startsWith('```')) {
          final lines = cleanedString.split('\n'); // corrigido escape
          if (lines.first.trim().startsWith('```')) {
            lines.removeAt(0);
          }
          if (lines.isNotEmpty && lines.last.trim().startsWith('```')) {
            lines.removeLast();
          }
          cleanedString = lines.join('\n').trim(); // corrigido escape
        }
      }

      return jsonDecode(cleanedString);
    } catch (e) {
      AppLogger.error('Erro fatal ao fazer parse do JSON recebido da IA.\nConteúdo sujo: $jsonString\nErro: $e');
      throw FormatException('A IA não retornou um JSON válido. Tente novamente.');
    }
  }

  String _buildSystemPrompt(TherapistProfileModel profile) {
    try {
      final promptFile = File(path.join(Directory.current.path, 'prompts', 'analyze_session_v1.md'));
      var prompt = promptFile.readAsStringSync();

      final therapistContextParts = <String>[];
      if (profile.approaches.isNotEmpty) {
        therapistContextParts.add("- Abordagem: ${profile.approaches.join(', ')}");
      }
      if (profile.therapeuticPosture.isNotEmpty) {
        therapistContextParts.add("- Postura: ${profile.therapeuticPosture}");
      }
      if (profile.sessionPriorities.isNotEmpty) {
        therapistContextParts.add("- Foco: ${profile.sessionPriorities.join(', ')}");
      }

      prompt = prompt.replaceAll('{{therapist_context}}', therapistContextParts.join('\n'));
      prompt = prompt.replaceAll('{{ai_tone}}', profile.aiTone);

      if (profile.aiAnalysisFocus.isNotEmpty) {
        prompt = prompt.replaceAll('{{ai_focus}}', 'FOCO ESPECÍFICO DA ANÁLISE: ${profile.aiAnalysisFocus}');
      } else {
        prompt = prompt.replaceAll('{{ai_focus}}', '');
      }

      return prompt;
    } catch (e) {
      AppLogger.error('Erro ao ler o arquivo analyze_session_v1.md. Fallback. Erro: $e');
      return "Erro: Falha estrutural ao carregar o prompt do sistema interno.";
    }
  }

  /// Prompt v2: recebe texto livre + transcrição STT e retorna relato em markdown + classificações simples.
  Future<Map<String, dynamic>> analyzeSessionV2({
    required String freeNotes,
    required String transcription,
    required TherapistProfileModel therapistProfile,
    required String patientName,
  }) async {
    final openRouterKey = EnvConfig.get('OPENROUTER_KEY') ?? EnvConfig.get('OPENAI_API_KEY');
    if (openRouterKey == null || openRouterKey.isEmpty) {
      throw Exception('OPENROUTER_KEY não configurada.');
    }

    final systemPrompt = _buildSystemPromptV2(therapistProfile);
    final userPrompt = StringBuffer();
    userPrompt.writeln('Paciente: $patientName');
    userPrompt.writeln('');
    if (freeNotes.isNotEmpty) {
      userPrompt.writeln('ANOTAÇÕES DO TERAPEUTA:');
      userPrompt.writeln(freeNotes);
      userPrompt.writeln('');
    }
    if (transcription.isNotEmpty) {
      userPrompt.writeln('TRANSCRIÇÃO DA SESSÃO (STT):');
      userPrompt.writeln(transcription);
    }

    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openRouterKey',
        'HTTP-Referer': 'https://github.com/marciopadovani/terafy',
        'X-Title': 'Terafy',
      },
      body: jsonEncode({
        'model': 'stepfun/step-3.5-flash:free',
        'temperature': 0.2,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt.toString()},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro na API do OpenRouter: ${response.statusCode} - ${response.body}');
    }

    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
    final choices = responseBody['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) throw Exception('OpenRouter não retornou choices');

    final content = choices.first['message']['content'] as String?;
    if (content == null) throw Exception('OpenRouter retornou conteúdo vazio');

    return _parseJson(content);
  }

  String _buildSystemPromptV2(TherapistProfileModel profile) {
    try {
      final promptFile = File(path.join(Directory.current.path, 'prompts', 'analyze_session_v2.md'));
      var prompt = promptFile.readAsStringSync();

      final therapistContextParts = <String>[];
      if (profile.approaches.isNotEmpty) {
        therapistContextParts.add("- Abordagem: ${profile.approaches.join(', ')}");
      }
      if (profile.therapeuticPosture.isNotEmpty) {
        therapistContextParts.add("- Postura: ${profile.therapeuticPosture}");
      }
      if (profile.sessionPriorities.isNotEmpty) {
        therapistContextParts.add("- Foco: ${profile.sessionPriorities.join(', ')}");
      }

      prompt = prompt.replaceAll('{{therapist_context}}', therapistContextParts.join('\n'));
      prompt = prompt.replaceAll('{{ai_tone}}', profile.aiTone);

      if (profile.aiAnalysisFocus.isNotEmpty) {
        prompt = prompt.replaceAll('{{ai_focus}}', 'FOCO DA ANÁLISE: ${profile.aiAnalysisFocus}');
      } else {
        prompt = prompt.replaceAll('{{ai_focus}}', '');
      }

      return prompt;
    } catch (e) {
      AppLogger.error('Erro ao ler o arquivo analyze_session_v2.md. Fallback. Erro: $e');
      return "Erro: Falha estrutural ao carregar o prompt v2 do sistema interno.";
    }
  }
}
