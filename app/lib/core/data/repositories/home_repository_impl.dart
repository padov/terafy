import 'package:common/common.dart';
import 'package:dio/dio.dart';
import 'package:terafy/core/domain/repositories/home_repository.dart';
import 'package:terafy/package/http.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required this.httpClient});

  final HttpClient httpClient;

  @override
  Future<HomeSummary> fetchSummary({
    DateTime? referenceDate,
    int? therapistId,
  }) async {
    try {
      final response = await httpClient.get(
        '/home/summary',
        queryParameters: {
          if (referenceDate != null)
            'date': referenceDate.toUtc().toIso8601String(),
          if (therapistId != null) 'therapistId': therapistId.toString(),
        },
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao carregar resumo da home');
      }

      return HomeSummary.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e) ?? 'Erro ao carregar resumo da home',
      );
    }
  }

  String? _extractErrorMessage(DioException exception) {
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
