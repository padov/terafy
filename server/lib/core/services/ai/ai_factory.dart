import 'package:dotenv/dotenv.dart';
import 'ai_service.dart';
import 'openai_service.dart';

class AIFactory {
  static AIService create(DotEnv env) {
    // Get provider from env, default to openai
    final provider = env['AI_PROVIDER']?.toLowerCase() ?? 'openai';
    final apiKey = env['AI_API_KEY'] ?? '';

    switch (provider) {
      case 'openai':
        return OpenAIService(apiKey: apiKey);
      default:
        // Fallback to openai for now or throw error
        return OpenAIService(apiKey: apiKey);
    }
  }
}
