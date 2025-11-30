import 'package:common/common.dart';
import 'package:server/features/subscription/subscription.repository.dart';
import 'package:server/features/therapist/therapist.repository.dart';

class SubscriptionException implements Exception {
  final String message;
  final int statusCode;

  SubscriptionException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class SubscriptionController {
  final SubscriptionRepository _repository;
  final TherapistRepository _therapistRepository;

  SubscriptionController(this._repository, this._therapistRepository);

  /// Retorna o status da assinatura atual do terapeuta
  Future<Map<String, dynamic>> getSubscriptionStatus(int userId) async {
    try {
      // Busca o terapeuta pelo user_id
      final therapistData = await _therapistRepository.getTherapistByUserIdWithPlan(userId);
      if (therapistData == null) {
        throw SubscriptionException('Terapeuta não encontrado', 404);
      }

      final therapistId = therapistData['id'] as int;
      final subscription = await _repository.getActiveSubscription(therapistId);
      final patientCount = await _repository.countActivePatients(therapistId);

      Map<String, dynamic> planData;
      if (subscription != null) {
        planData = subscription['plan'] as Map<String, dynamic>;
      } else {
        final defaultPlan = await _repository.getDefaultPlan();
        planData = defaultPlan['plan'] as Map<String, dynamic>;
      }

      final patientLimit = planData['patient_limit'] as int? ?? 10;
      final canCreate = patientCount < patientLimit;

      return {
        'subscription': subscription?['subscription'],
        'plan': planData,
        'usage': {
          'patient_count': patientCount,
          'patient_limit': patientLimit,
          'can_create_patient': canCreate,
          'usage_percentage': patientLimit > 0 ? (patientCount / patientLimit * 100).round() : 0,
        },
      };
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      AppLogger.error(e, StackTrace.current);
      throw SubscriptionException('Erro ao buscar status da assinatura: ${e.toString()}', 500);
    }
  }

  /// Lista todos os planos disponíveis
  Future<List<Map<String, dynamic>>> getAvailablePlans() async {
    try {
      return await _repository.getAvailablePlans();
    } catch (e) {
      AppLogger.error(e, StackTrace.current);
      throw SubscriptionException('Erro ao listar planos: ${e.toString()}', 500);
    }
  }

  /// Verifica e sincroniza assinatura do Play Store
  Future<Map<String, dynamic>> verifyPlayStoreSubscription({
    required int userId,
    required String purchaseToken,
    required String orderId,
    required String productId,
    required bool autoRenewing,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Busca o terapeuta pelo user_id
      final therapistData = await _therapistRepository.getTherapistByUserIdWithPlan(userId);
      if (therapistData == null) {
        throw SubscriptionException('Terapeuta não encontrado', 404);
      }

      final therapistId = therapistData['id'] as int;

      // Busca o plano pelo product_id
      final plan = await _repository.getPlanByProductId(productId);
      if (plan == null) {
        throw SubscriptionException('Plano não encontrado para product_id: $productId', 404);
      }

      final planId = plan['id'] as int;

      // Verifica se já existe assinatura com este order_id
      final existingSubscription = await _repository.getSubscriptionByOrderId(orderId);
      if (existingSubscription != null) {
        // Retorna a assinatura existente
        return await getSubscriptionStatus(userId);
      }

      // Sincroniza a assinatura
      await _repository.syncPlayStoreSubscription(
        therapistId: therapistId,
        planId: planId,
        purchaseToken: purchaseToken,
        orderId: orderId,
        autoRenewing: autoRenewing,
        startDate: startDate,
        endDate: endDate,
      );

      AppLogger.info('Assinatura do Play Store sincronizada: order_id=$orderId, therapist_id=$therapistId');

      // Retorna o status atualizado
      return await getSubscriptionStatus(userId);
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      AppLogger.error(e, StackTrace.current);
      throw SubscriptionException('Erro ao verificar assinatura: ${e.toString()}', 500);
    }
  }

  /// Verifica se o terapeuta pode criar um novo paciente
  Future<bool> canCreatePatient(int userId) async {
    try {
      final therapistData = await _therapistRepository.getTherapistByUserIdWithPlan(userId);
      if (therapistData == null) {
        throw SubscriptionException('Terapeuta não encontrado', 404);
      }

      final therapistId = therapistData['id'] as int;
      return await _repository.canCreatePatient(therapistId);
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      AppLogger.error(e, StackTrace.current);
      throw SubscriptionException('Erro ao verificar limite: ${e.toString()}', 500);
    }
  }

  /// Retorna informações de uso (contagem de pacientes)
  Future<Map<String, dynamic>> getUsageInfo(int userId) async {
    try {
      final therapistData = await _therapistRepository.getTherapistByUserIdWithPlan(userId);
      if (therapistData == null) {
        throw SubscriptionException('Terapeuta não encontrado', 404);
      }

      final therapistId = therapistData['id'] as int;
      final subscription = await _repository.getActiveSubscription(therapistId);
      final patientCount = await _repository.countActivePatients(therapistId);

      Map<String, dynamic> planData;
      if (subscription != null) {
        planData = subscription['plan'] as Map<String, dynamic>;
      } else {
        final defaultPlan = await _repository.getDefaultPlan();
        planData = defaultPlan['plan'] as Map<String, dynamic>;
      }

      final patientLimit = planData['patient_limit'] as int? ?? 10;

      return {
        'patient_count': patientCount,
        'patient_limit': patientLimit,
        'can_create_patient': patientCount < patientLimit,
        'usage_percentage': patientLimit > 0 ? (patientCount / patientLimit * 100).round() : 0,
      };
    } catch (e) {
      if (e is SubscriptionException) rethrow;
      AppLogger.error(e, StackTrace.current);
      throw SubscriptionException('Erro ao buscar informações de uso: ${e.toString()}', 500);
    }
  }
}
