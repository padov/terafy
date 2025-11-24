import 'package:dio/dio.dart';
import 'package:terafy/core/domain/entities/therapist_signup_input.dart';
import 'package:terafy/core/domain/repositories/therapist_repository.dart';
import 'package:terafy/package/http.dart';
import 'package:common/common.dart';

class TherapistRepositoryImpl implements TherapistRepository {
  final HttpClient httpClient;

  TherapistRepositoryImpl({required this.httpClient});

  @override
  Future<void> createTherapist({required TherapistSignupInput input}) {
    return _wrapRequest(() async {
      final response = await httpClient.post(
        '/therapists/me',
        data: input.toJson(),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Falha ao criar terapeuta.');
      }
    }, defaultErrorMessage: 'Erro ao criar terapeuta');
  }

  @override
  Future<Map<String, dynamic>> getCurrentTherapist() async {
    Map<String, dynamic>? result;

    await _wrapRequest(() async {
      final response = await httpClient.get('/therapists/me');

      if (response.statusCode != 200) {
        throw Exception('Falha ao buscar dados do terapeuta.');
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        result = data;
      } else {
        result = Map<String, dynamic>.from(data as Map);
      }
    }, defaultErrorMessage: 'Erro ao buscar dados do terapeuta');

    if (result == null) {
      throw Exception('Resposta inválida do servidor ao buscar terapeuta.');
    }

    return result!;
  }

  @override
  Future<Map<String, dynamic>> updateTherapist({required Therapist therapist}) async {
    Map<String, dynamic>? result;

    await _wrapRequest(() async {
      final response = await httpClient.put(
        '/therapists/me',
        data: therapist.toJson(),
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao atualizar dados do terapeuta.');
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        result = data;
      } else {
        result = Map<String, dynamic>.from(data as Map);
      }
    }, defaultErrorMessage: 'Erro ao atualizar dados do terapeuta');

    if (result == null) {
      throw Exception('Resposta inválida do servidor ao atualizar terapeuta.');
    }

    return result!;
  }

  Future<void> _wrapRequest(
    Future<void> Function() action, {
    required String defaultErrorMessage,
  }) async {
    AppLogger.func();
    try {
      await action();
    } on DioException catch (e) {
      String errorMessage = defaultErrorMessage;

      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['error'] is String) {
          errorMessage = data['error'] as String;
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      AppLogger.error(errorMessage, e.stackTrace);
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      rethrow;
    }
  }
}
