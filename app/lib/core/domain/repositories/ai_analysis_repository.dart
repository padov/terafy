abstract class AiAnalysisRepository {
  /// Generate a new AI analysis
  Future<Map<String, dynamic>> generateAnalysis({
    required int patientId,
    required String analysisType,
    required String prompt,
    int? sessionId,
  });

  /// Fetch all analyses for a patient
  Future<List<Map<String, dynamic>>> fetchAnalyses(int patientId);

  /// Get a single analysis by ID
  Future<Map<String, dynamic>> getAnalysisById(String id);

  /// Archive an analysis
  Future<void> archiveAnalysis(String id);

  /// Unarchive an analysis
  Future<void> unarchiveAnalysis(String id);
}
