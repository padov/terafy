import 'package:common/common.dart';
import 'package:dio/dio.dart';
import 'package:terafy/core/domain/repositories/financial_repository.dart';
import 'package:terafy/package/http.dart';

class FinancialRepositoryImpl implements FinancialRepository {
  FinancialRepositoryImpl({required this.httpClient});

  final HttpClient httpClient;

  @override
  Future<List<FinancialTransaction>> fetchTransactions({
    int? therapistId,
    int? patientId,
    int? sessionId,
    String? status,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.func();
      final queryParams = <String, dynamic>{};
      if (therapistId != null)
        queryParams['therapistId'] = therapistId.toString();
      if (patientId != null) queryParams['patientId'] = patientId.toString();
      if (sessionId != null) queryParams['sessionId'] = sessionId.toString();
      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toUtc().toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toUtc().toIso8601String();
      }

      final response = await httpClient.get(
        '/financial',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.data is! List) {
        throw Exception('Resposta inválida ao carregar transações');
      }

      final data = response.data as List;

      return data
          .map(
            (item) => FinancialTransaction.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao carregar transações');
    }
  }

  @override
  Future<FinancialTransaction?> fetchTransaction(int transactionId) async {
    try {
      final response = await httpClient.get('/financial/$transactionId');

      if (response.statusCode == 404) {
        return null;
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao carregar transação');
      }

      return FinancialTransaction.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao carregar transação');
    }
  }

  @override
  Future<FinancialTransaction> createTransaction(
    FinancialTransaction transaction,
  ) async {
    AppLogger.func();
    try {
      final response = await httpClient.post(
        '/financial',
        data: transaction.toJson(),
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao criar transação');
      }

      return FinancialTransaction.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao criar transação');
    }
  }

  @override
  Future<FinancialTransaction> updateTransaction(
    int transactionId,
    FinancialTransaction transaction,
  ) async {
    AppLogger.func();
    try {
      final response = await httpClient.put(
        '/financial/$transactionId',
        data: transaction.toJson(),
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao atualizar transação');
      }

      return FinancialTransaction.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao atualizar transação');
    }
  }

  @override
  Future<void> deleteTransaction(int transactionId) async {
    AppLogger.func();
    try {
      await httpClient.delete('/financial/$transactionId');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao remover transação');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchFinancialSummary({
    required int therapistId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.func();
    try {
      final queryParams = <String, dynamic>{
        'therapistId': therapistId.toString(),
      };
      if (startDate != null) {
        queryParams['startDate'] = startDate.toUtc().toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toUtc().toIso8601String();
      }

      final response = await httpClient.get(
        '/financial/summary',
        queryParameters: queryParams,
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao carregar resumo financeiro');
      }

      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e) ?? 'Erro ao carregar resumo financeiro',
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
