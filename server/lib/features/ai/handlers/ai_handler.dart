import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:common/common.dart';
import 'package:server/core/handlers/base_handler.dart';
import 'package:server/core/services/openrouter_service.dart';
import 'package:server/core/middleware/auth_middleware.dart';
import '../ai_analysis_repository.dart';
import '../models/ai_analysis.dart';

class AiHandler extends BaseHandler {
  final OpenRouterService _aiService;
  final AIAnalysisRepository _repository;

  AiHandler(this._aiService, this._repository);

  @override
  Router get router {
    final router = Router();
    router.post('/generate', handleGenerate);
    router.get('/patient/<patientId>', handleGetByPatient);
    router.get('/<id>', handleGetById);
    router.put('/<id>/archive', handleArchive);
    router.put('/<id>/unarchive', handleUnarchive);
    return router;
  }

  /// Handler for POST /api/v1/ai/generate
  /// Creates an analysis record, calls AI, and updates with result
  Future<Response> handleGenerate(Request request) async {
    AppLogger.func();
    try {
      final body = await request.readAsString();
      if (body.isEmpty) {
        return badRequestResponse('Request body cannot be empty');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;

      // Extract required fields
      final patientId = data['patient_id'] as int?;
      final typeStr = data['type'] as String?;
      final prompt = data['prompt'] as String?;

      if (patientId == null || typeStr == null || prompt == null) {
        return badRequestResponse('patient_id, type, and prompt are required');
      }

      // Parse type
      AIAnalysisType type;
      try {
        type = AIAnalysisType.fromString(typeStr);
      } catch (e) {
        AppLogger.error('Invalid analysis type: $typeStr $e');
        return badRequestResponse('Invalid analysis type: $typeStr');
      }

      // Extract optional session IDs
      final sessionIds = data['session_ids'] != null ? List<int>.from(data['session_ids'] as List) : <int>[];

      // Get therapist ID from request headers (set by auth middleware)
      final therapistId = getAccountId(request);
      if (therapistId == null) {
        AppLogger.error('account_id not found in request headers');
        return unauthorizedResponse('Authentication required');
      }

      // Create analysis record with pending status
      final analysis = await _repository.create(
        therapistId: therapistId,
        patientId: patientId,
        type: type,
        prompt: prompt,
        sessionIds: sessionIds,
      );

      // Call AI service
      String result;
      double cost = 0.0;

      try {
        result = await _aiService.generateText(prompt);

        // Calculate cost (simplified - you might want to parse usage from API response)
        // For now, estimate based on token count (rough estimate)
        final estimatedTokens = (prompt.length + result.length) / 4;
        cost = estimatedTokens * 0.000002; // Rough estimate for gpt-4o-mini

        // Update with result
        await _repository.updateWithResult(id: analysis.id!, result: result, cost: cost);
      } catch (e) {
        AppLogger.error('AI service error: ${e.toString()}');
        // Update with error
        await _repository.updateWithError(id: analysis.id!, errorMessage: e.toString());

        return errorResponse('AI service error: ${e.toString()}', statusCode: 500);
      }

      // Fetch the complete analysis from database to return all fields
      final completeAnalysis = await _repository.getById(analysis.id!);
      if (completeAnalysis == null) {
        return errorResponse('Failed to retrieve generated analysis', statusCode: 500);
      }

      // Return the completed analysis with all fields
      return successResponse(completeAnalysis.toJson());
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Error generating AI analysis: ${e.toString()}');
    }
  }

  /// Handler for GET /api/v1/ai/<id>
  /// Gets a specific analysis by ID
  Future<Response> handleGetById(Request request, String id) async {
    AppLogger.func();
    try {
      final analysisId = int.tryParse(id);
      if (analysisId == null) {
        return badRequestResponse('Invalid analysis ID');
      }

      final analysis = await _repository.getById(analysisId);
      if (analysis == null) {
        return notFoundResponse('Analysis not found');
      }

      return successResponse(analysis.toJson());
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Error fetching analysis: ${e.toString()}');
    }
  }

  /// Handler for GET /api/v1/ai/patient/<patientId>
  /// Gets all analyses for a patient
  Future<Response> handleGetByPatient(Request request, String patientId) async {
    AppLogger.func();
    try {
      final id = int.tryParse(patientId);
      if (id == null) {
        return badRequestResponse('Invalid patient ID');
      }

      final analyses = await _repository.getByPatientId(id);

      return successResponse({'analyses': analyses.map((a) => a.toJson()).toList()});
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Error fetching analyses: ${e.toString()}');
    }
  }

  /// Archives an analysis
  Future<Response> handleArchive(Request request, String id) async {
    try {
      final analysisId = int.tryParse(id);
      if (analysisId == null) {
        return badRequestResponse('Invalid analysis ID');
      }

      await _repository.archive(id: analysisId);

      return successResponse({'message': 'Analysis archived successfully'});
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Error archiving analysis: ${e.toString()}');
    }
  }

  /// Unarchives an analysis
  Future<Response> handleUnarchive(Request request, String id) async {
    try {
      final analysisId = int.tryParse(id);
      if (analysisId == null) {
        return badRequestResponse('Invalid analysis ID');
      }

      await _repository.unarchive(id: analysisId);

      return successResponse({'message': 'Analysis unarchived successfully'});
    } catch (e, stack) {
      AppLogger.error(e, stack);
      return internalServerErrorResponse('Error unarchiving analysis: ${e.toString()}');
    }
  }
}
