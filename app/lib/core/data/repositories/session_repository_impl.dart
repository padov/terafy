import 'package:common/common.dart';
import 'package:dio/dio.dart';
import 'package:terafy/core/domain/repositories/session_repository.dart';
import 'package:terafy/package/http.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({required this.httpClient});

  final HttpClient httpClient;

  @override
  Future<List<Session>> fetchSessions({
    int? patientId,
    int? therapistId,
    int? appointmentId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.func();
      final queryParams = <String, dynamic>{};
      if (patientId != null) queryParams['patientId'] = patientId.toString();
      if (therapistId != null)
        queryParams['therapistId'] = therapistId.toString();
      if (appointmentId != null)
        queryParams['appointmentId'] = appointmentId.toString();
      if (status != null) queryParams['status'] = status;
      if (startDate != null)
        queryParams['start'] = startDate.toUtc().toIso8601String();
      if (endDate != null)
        queryParams['end'] = endDate.toUtc().toIso8601String();

      final response = await httpClient.get(
        '/sessions',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.data is! List) {
        throw Exception('Resposta inválida ao carregar sessões');
      }

      final data = response.data as List;

      return data
          .map(
            (item) => Session.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao carregar sessões');
    }
  }

  @override
  Future<Session> fetchSession(int sessionId) async {
    try {
      final response = await httpClient.get('/sessions/$sessionId');

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao carregar sessão');
      }

      return Session.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao carregar sessão');
    }
  }

  @override
  Future<Session> createSession(Session session) async {
    AppLogger.func();
    try {
      final response = await httpClient.post(
        '/sessions',
        data: session.toJson(),
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao criar sessão');
      }

      return Session.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao criar sessão');
    }
  }

  @override
  Future<Session> updateSession(int sessionId, Session session) async {
    AppLogger.func();
    try {
      final response = await httpClient.put(
        '/sessions/$sessionId',
        data: session.toJson(),
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao atualizar sessão');
      }

      return Session.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao atualizar sessão');
    }
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    AppLogger.func();
    try {
      await httpClient.delete('/sessions/$sessionId');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao remover sessão');
    }
  }

  @override
  Future<int> getNextSessionNumber(int patientId) async {
    AppLogger.func();
    try {
      final response = await httpClient.get(
        '/sessions/next-number',
        queryParameters: {'patientId': patientId.toString()},
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao calcular próximo número');
      }

      final data = response.data as Map<String, dynamic>;
      return data['nextNumber'] as int;
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e) ?? 'Erro ao calcular próximo número de sessão',
      );
    }
  }

  String? _extractErrorMessage(DioException exception) {
    AppLogger.func();
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    } else if (exception.message != null) {
      return exception.message;
    }
    return null;
  }
}
