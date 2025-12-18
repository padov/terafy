
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

class OpenAIService implements AIService {
  final String apiKey;
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  OpenAIService({required this.apiKey});

  @override
  Future<String> generateText(String prompt) async {
    if (apiKey.isEmpty || apiKey == 'sua-chave-api-aqui') {
      throw Exception('OpenAI API key not configured');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', // or config
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'].toString();
        }
        return '';
      } else {
        throw Exception('OpenAI API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate text: $e');
    }
  }
}
