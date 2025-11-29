import 'package:dio/dio.dart';
import 'package:terafy/core/domain/repositories/anamnesis_template_repository.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_template.dart';
import 'package:terafy/package/http.dart';

class AnamnesisTemplateRepositoryImpl implements AnamnesisTemplateRepository {
  AnamnesisTemplateRepositoryImpl({required this.httpClient});

  final HttpClient httpClient;

  @override
  Future<List<AnamnesisTemplate>> fetchTemplates({
    String? category,
    bool? isSystem,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (isSystem != null) queryParams['isSystem'] = isSystem.toString();

      final response = await httpClient.get(
        '/anamnesis/templates',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao carregar templates');
      }

      if (response.data is! List) {
        throw Exception('Resposta inesperada ao carregar templates');
      }

      return (response.data as List)
          .map((item) => AnamnesisTemplate.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao carregar templates';
      throw Exception(message);
    }
  }

  @override
  Future<AnamnesisTemplate?> fetchTemplateById(String id) async {
    try {
      final response = await httpClient.get('/anamnesis/templates/$id');

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao carregar template');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao carregar template');
      }

      return AnamnesisTemplate.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      final message = _extractErrorMessage(e) ?? 'Erro ao carregar template';
      throw Exception(message);
    }
  }

  @override
  Future<AnamnesisTemplate> createTemplate(AnamnesisTemplate template) async {
    try {
      final payload = template.toApiJson();

      final response =
          await httpClient.post('/anamnesis/templates', data: payload);

      final isSuccess =
          response.statusCode == 201 || response.statusCode == 200;
      if (!isSuccess || response.data == null) {
        throw Exception('Erro ao criar template');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao criar template');
      }

      return AnamnesisTemplate.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao criar template';
      throw Exception(message);
    }
  }

  @override
  Future<AnamnesisTemplate> updateTemplate(
    String id,
    AnamnesisTemplate template,
  ) async {
    try {
      final payload = template.toApiJson();

      final response =
          await httpClient.put('/anamnesis/templates/$id', data: payload);

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao atualizar template');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao atualizar template');
      }

      return AnamnesisTemplate.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao atualizar template';
      throw Exception(message);
    }
  }

  @override
  Future<void> deleteTemplate(String id) async {
    try {
      final response = await httpClient.delete('/anamnesis/templates/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro ao deletar template');
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao deletar template';
      throw Exception(message);
    }
  }

  String? _extractErrorMessage(DioException exception) {
    if (exception.response?.data is Map<String, dynamic>) {
      final map = exception.response!.data as Map<String, dynamic>;
      final error = map['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    } else if (exception.message != null) {
      return exception.message;
    }
    return null;
  }
}

