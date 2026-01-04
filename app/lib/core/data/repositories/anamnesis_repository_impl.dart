import 'package:dio/dio.dart';
import 'package:terafy/core/domain/repositories/anamnesis_repository.dart';
import 'package:terafy/features/anamnesis/models/anamnesis.dart';
import 'package:terafy/package/http.dart';

class AnamnesisRepositoryImpl implements AnamnesisRepository {
  AnamnesisRepositoryImpl({required this.httpClient});

  final HttpClient httpClient;

  @override
  Future<Anamnesis?> fetchAnamnesisByPatientId(String patientId) async {
    try {
      final response = await httpClient.get('/anamnesis/patient/$patientId');

      if (response.statusCode == 404) {
        return null; // Anamnese não encontrada
      }

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao carregar anamnese');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao carregar anamnese');
      }

      return Anamnesis.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      final message = _extractErrorMessage(e) ?? 'Erro ao carregar anamnese';
      throw Exception(message);
    }
  }

  @override
  Future<Anamnesis?> fetchAnamnesisById(String id) async {
    try {
      final response = await httpClient.get('/anamnesis/$id');

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao carregar anamnese');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao carregar anamnese');
      }

      return Anamnesis.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      final message = _extractErrorMessage(e) ?? 'Erro ao carregar anamnese';
      throw Exception(message);
    }
  }

  @override
  Future<Anamnesis> createAnamnesis(Anamnesis anamnesis) async {
    try {
      final payload = anamnesis.toApiJson();

      final response = await httpClient.post('/anamnesis', data: payload);

      final isSuccess = response.statusCode == 201 || response.statusCode == 200;
      if (!isSuccess || response.data == null) {
        throw Exception('Erro ao criar anamnese');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao criar anamnese');
      }

      return Anamnesis.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao criar anamnese';
      throw Exception(message);
    }
  }

  @override
  Future<Anamnesis> updateAnamnesis(String id, Anamnesis anamnesis) async {
    try {
      final payload = anamnesis.toApiJson();

      final response = await httpClient.put('/anamnesis/$id', data: payload);

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao atualizar anamnese');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao atualizar anamnese');
      }

      return Anamnesis.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao atualizar anamnese';
      throw Exception(message);
    }
  }

  @override
  Future<void> deleteAnamnesis(String id) async {
    try {
      final response = await httpClient.delete('/anamnesis/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro ao deletar anamnese');
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao deletar anamnese';
      throw Exception(message);
    }
  }

  @override
  Future<String> createInvite(String patientId, String templateId) async {
    try {
      final response = await httpClient.post(
        '/anamnesis/invite',
        data: {'patientId': patientId, 'templateId': templateId},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erro ao criar convite');
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('link')) {
          return data['link'].toString();
        }
        if (data.containsKey('token')) {
          return data['token'].toString();
        }
      }

      throw Exception('Link não encontrado na resposta');
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao criar convite';
      throw Exception(message);
    }
  }

  @override
  Future<Map<String, dynamic>> getPublicInviteContext(String token) async {
    try {
      final response = await httpClient.get('/anamnesis/public/invite/$token');

      if (response.statusCode != 200) {
        throw Exception('Erro ao carregar convite');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida do servidor');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao carregar convite';
      throw Exception(message);
    }
  }

  @override
  Future<void> submitPublicInvite(String token, Map<String, dynamic> data) async {
    try {
      final response = await httpClient.post('/anamnesis/public/invite/$token/submit', data: data);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erro ao enviar anamnese');
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao enviar anamnese';
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
