import 'package:dio/dio.dart';
import 'package:common/common.dart';
import 'package:terafy/core/domain/repositories/subscription_repository.dart';
import 'package:terafy/core/subscription/subscription_models.dart';
import 'package:terafy/package/http.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final HttpClient httpClient;

  SubscriptionRepositoryImpl({required this.httpClient});

  @override
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    return await _wrapRequest(() async {
      final response = await httpClient.get('/subscription/status');

      if (response.statusCode != 200) {
        throw Exception('Falha ao buscar status da assinatura.');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao buscar status da assinatura.');
      }

      return SubscriptionStatus.fromJson(data);
    }, defaultErrorMessage: 'Erro ao buscar status da assinatura');
  }

  @override
  Future<List<SubscriptionPlan>> getAvailablePlans() async {
    return await _wrapRequest(() async {
      final response = await httpClient.get('/subscription/plans');

      if (response.statusCode != 200) {
        throw Exception('Falha ao listar planos disponíveis.');
      }

      final data = response.data;
      if (data is! List) {
        throw Exception('Resposta inválida ao listar planos.');
      }

      return data.cast<Map<String, dynamic>>().map((json) => SubscriptionPlan.fromJson(json)).toList();
    }, defaultErrorMessage: 'Erro ao listar planos disponíveis');
  }

  @override
  Future<SubscriptionStatus> verifyPlayStoreSubscription({
    required String purchaseToken,
    required String orderId,
    required String productId,
    required bool autoRenewing,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _wrapRequest(() async {
      final payload = <String, dynamic>{
        'purchase_token': purchaseToken,
        'order_id': orderId,
        'product_id': productId,
        'auto_renewing': autoRenewing,
      };

      if (startDate != null) {
        payload['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        payload['end_date'] = endDate.toIso8601String();
      }

      final response = await httpClient.post('/subscription/verify', data: payload);

      if (response.statusCode != 200) {
        throw Exception('Falha ao verificar assinatura do Play Store.');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao verificar assinatura.');
      }

      return SubscriptionStatus.fromJson(data);
    }, defaultErrorMessage: 'Erro ao verificar assinatura do Play Store');
  }

  @override
  Future<SubscriptionUsage> getUsageInfo() async {
    return await _wrapRequest(() async {
      final response = await httpClient.get('/subscription/usage');

      if (response.statusCode != 200) {
        throw Exception('Falha ao buscar informações de uso.');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao buscar informações de uso.');
      }

      return SubscriptionUsage.fromJson(data);
    }, defaultErrorMessage: 'Erro ao buscar informações de uso');
  }

  Future<T> _wrapRequest<T>(Future<T> Function() action, {required String defaultErrorMessage}) async {
    AppLogger.func();
    try {
      return await action();
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
