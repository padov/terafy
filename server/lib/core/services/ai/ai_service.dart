
/// Interface for AI Service providers
abstract class AIService {
  /// Generates text based on a prompt
  Future<String> generateText(String prompt);
}
