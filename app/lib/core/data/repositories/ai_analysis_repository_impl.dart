import 'package:common/common.dart';
import 'package:dio/dio.dart';
import 'package:terafy/core/domain/repositories/ai_analysis_repository.dart';
import 'package:terafy/package/http.dart';

class AiAnalysisRepositoryImpl implements AiAnalysisRepository {
  AiAnalysisRepositoryImpl({required this.httpClient});

  final HttpClient httpClient;

  @override
  Future<Map<String, dynamic>> generateAnalysis({
    required int patientId,
    required String analysisType,
    required String prompt,
    int? sessionId,
  }) async {
    AppLogger.func();
    try {
      final response = await httpClient.post(
        '/ai/generate',
        data: {
          'patient_id': patientId,
          'type': analysisType, // Backend expects 'type'
          'prompt': prompt,
          if (sessionId != null) 'session_id': sessionId,
        },
      );

      if (response.data is! Map) {
        throw Exception('Resposta inválida ao gerar análise IA');
      }

      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      // Extract error message from response
      String errorMessage = 'Erro ao gerar análise IA';

      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;

        if (data is Map) {
          errorMessage =
              data['message']?.toString() ??
              data['error']?.toString() ??
              data['details']?.toString() ??
              'Erro ${e.response!.statusCode}: ${e.response!.statusMessage}';
        } else if (data is String) {
          errorMessage = data;
        } else {
          errorMessage = 'Erro ${e.response!.statusCode}: ${e.response!.statusMessage}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Timeout ao conectar com servidor';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Erro de conexão. Verifique sua internet.';
      }

      throw Exception(errorMessage);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      // Preserve original error message
      throw Exception('Erro inesperado: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAnalyses(int patientId) async {
    try {
      final response = await httpClient.get('/ai/patient/$patientId');

      if (response.data is! Map) {
        throw Exception('Resposta inválida ao carregar análises IA');
      }

      final data = response.data as Map<String, dynamic>;
      final analyses = data['analyses'] as List?;

      if (analyses == null) {
        return [];
      }

      return analyses.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        try {
          final data = e.response!.data;
          String errorMessage = 'Erro ao carregar análises IA';

          if (data is Map) {
            errorMessage = data['message']?.toString() ?? data['error']?.toString() ?? errorMessage;
          } else if (data is String) {
            errorMessage = data;
          }

          throw Exception(errorMessage);
        } catch (_) {
          throw Exception('Erro ao carregar análises IA');
        }
      }
      throw Exception('Erro de conexão ao carregar análises IA');
    } catch (e) {
      throw Exception('Erro inesperado ao carregar análises IA: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAnalysisById(String id) async {
    try {
      final response = await httpClient.get('/ai/analyses/$id');

      if (response.data is! Map) {
        throw Exception('Resposta inválida ao carregar análise IA');
      }

      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        try {
          final data = e.response!.data;
          String errorMessage = 'Erro ao carregar análise IA';

          if (data is Map) {
            errorMessage = data['message']?.toString() ?? data['error']?.toString() ?? errorMessage;
          } else if (data is String) {
            errorMessage = data;
          }

          throw Exception(errorMessage);
        } catch (_) {
          throw Exception('Erro ao carregar análise IA');
        }
      }
      throw Exception('Erro de conexão ao carregar análise IA');
    } catch (e) {
      throw Exception('Erro inesperado ao carregar análise IA: $e');
    }
  }

  @override
  Future<void> archiveAnalysis(String id) async {
    try {
      await httpClient.put('/ai/$id/archive');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;
        String errorMessage = 'Erro ao arquivar análise';

        if (data is Map) {
          errorMessage = data['message']?.toString() ?? data['error']?.toString() ?? errorMessage;
        } else if (data is String) {
          errorMessage = data;
        }

        throw Exception(errorMessage);
      }
      throw Exception('Erro de conexão ao arquivar análise');
    }
  }

  @override
  Future<void> unarchiveAnalysis(String id) async {
    try {
      await httpClient.put('/ai/$id/unarchive');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;
        String errorMessage = 'Erro ao desarquivar análise';

        if (data is Map) {
          errorMessage = data['message']?.toString() ?? data['error']?.toString() ?? errorMessage;
        } else if (data is String) {
          errorMessage = data;
        }

        throw Exception(errorMessage);
      }
      throw Exception('Erro de conexão ao desarquivar análise');
    }
  }
}
