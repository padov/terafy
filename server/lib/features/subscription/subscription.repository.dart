import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';

class SubscriptionRepository {
  final DBConnection _dbConnection;

  SubscriptionRepository(this._dbConnection);

  /// Retorna o plano ativo do terapeuta com informações completas
  Future<Map<String, dynamic>?> getActiveSubscription(int therapistId) async {
    return await _dbConnection.withConnection((conn) async {
      final results = await conn.execute(
        Sql.named('''
        SELECT 
          ps.id as subscription_id,
          ps.therapist_id,
          ps.plan_id,
          ps.start_date,
          ps.end_date,
          ps.payment_method::text,
          ps.is_active,
          ps.play_store_purchase_token,
          ps.play_store_order_id,
          ps.auto_renewing,
          ps.created_at as subscription_created_at,
          p.id as plan_id,
          p.name as plan_name,
          p.description as plan_description,
          p.price as plan_price,
          p.patient_limit as plan_patient_limit,
          p.features as plan_features,
          p.play_store_product_id,
          p.billing_period
        FROM plan_subscriptions ps
        INNER JOIN plans p ON ps.plan_id = p.id
        WHERE ps.therapist_id = @therapist_id 
          AND ps.is_active = true
          AND ps.end_date >= NOW()
        ORDER BY ps.created_at DESC
        LIMIT 1;
      '''),
        parameters: {'therapist_id': therapistId},
      );

      if (results.isEmpty) {
        return null;
      }

      final map = results.first.toColumnMap();
      return {
        'subscription': {
          'id': map['subscription_id'],
          'therapist_id': map['therapist_id'],
          'start_date': map['start_date'],
          'end_date': map['end_date'],
          'payment_method': map['payment_method'],
          'is_active': map['is_active'],
          'play_store_purchase_token': map['play_store_purchase_token'],
          'play_store_order_id': map['play_store_order_id'],
          'auto_renewing': map['auto_renewing'],
          'created_at': map['subscription_created_at'],
        },
        'plan': {
          'id': map['plan_id'],
          'name': map['plan_name'],
          'description': map['plan_description'],
          'price': map['plan_price'],
          'patient_limit': map['plan_patient_limit'],
          'features': map['plan_features'],
          'play_store_product_id': map['play_store_product_id'],
          'billing_period': map['billing_period'],
        },
      };
    });
  }

  /// Retorna o plano padrão (Free) se não houver assinatura ativa
  Future<Map<String, dynamic>> getDefaultPlan() async {
    return await _dbConnection.withConnection((conn) async {
      final results = await conn.execute(
        Sql.named('''
        SELECT 
          id,
          name,
          description,
          price,
          patient_limit,
          features,
          play_store_product_id,
          billing_period
        FROM plans
        WHERE name = 'Free' AND is_active = true
        LIMIT 1;
      '''),
      );

      if (results.isEmpty) {
        // Fallback se o plano Free não existir
        return {
          'plan': {
            'id': 0,
            'name': 'Free',
            'description': 'Plano gratuito',
            'price': 0.0,
            'patient_limit': 10,
            'features': <String>[],
            'play_store_product_id': null,
            'billing_period': 'monthly',
          },
        };
      }

      final map = results.first.toColumnMap();
      return {
        'plan': {
          'id': map['id'],
          'name': map['name'],
          'description': map['description'],
          'price': map['price'],
          'patient_limit': map['patient_limit'],
          'features': map['features'],
          'play_store_product_id': map['play_store_product_id'],
          'billing_period': map['billing_period'],
        },
      };
    });
  }

  /// Conta o número de pacientes ativos do terapeuta
  Future<int> countActivePatients(int therapistId) async {
    return await _dbConnection.withConnection((conn) async {
      final results = await conn.execute(
        Sql.named('''
        SELECT COUNT(*) as count
        FROM patients
        WHERE therapist_id = @therapist_id
          AND status IN ('active', 'evaluated');
      '''),
        parameters: {'therapist_id': therapistId},
      );

      if (results.isEmpty) {
        return 0;
      }

      return (results.first.toColumnMap()['count'] as int?) ?? 0;
    });
  }

  /// Verifica se o terapeuta pode criar um novo paciente
  Future<bool> canCreatePatient(int therapistId) async {
    final subscription = await getActiveSubscription(therapistId);
    final patientCount = await countActivePatients(therapistId);

    int patientLimit;
    if (subscription != null) {
      patientLimit = subscription['plan']?['patient_limit'] as int? ?? 10;
    } else {
      final defaultPlan = await getDefaultPlan();
      patientLimit = defaultPlan['plan']?['patient_limit'] as int? ?? 10;
    }

    return patientCount < patientLimit;
  }

  /// Lista todos os planos disponíveis
  Future<List<Map<String, dynamic>>> getAvailablePlans() async {
    return await _dbConnection.withConnection((conn) async {
      final results = await conn.execute(
        Sql.named('''
        SELECT 
          id,
          name,
          description,
          price,
          patient_limit,
          features,
          play_store_product_id,
          billing_period,
          is_active
        FROM plans
        WHERE is_active = true
        ORDER BY price ASC;
      '''),
      );

      return results.map((row) {
        final map = row.toColumnMap();
        return {
          'id': map['id'],
          'name': map['name'],
          'description': map['description'],
          'price': map['price'],
          'patient_limit': map['patient_limit'],
          'features': map['features'],
          'play_store_product_id': map['play_store_product_id'],
          'billing_period': map['billing_period'],
        };
      }).toList();
    });
  }

  /// Busca plano por product_id do Play Store
  Future<Map<String, dynamic>?> getPlanByProductId(String productId) async {
    return await _dbConnection.withConnection((conn) async {
      final results = await conn.execute(
        Sql.named('''
        SELECT 
          id,
          name,
          description,
          price,
          patient_limit,
          features,
          play_store_product_id,
          billing_period
        FROM plans
        WHERE play_store_product_id = @product_id
          AND is_active = true
        LIMIT 1;
      '''),
        parameters: {'product_id': productId},
      );

      if (results.isEmpty) {
        return null;
      }

      final map = results.first.toColumnMap();
      return {
        'id': map['id'],
        'name': map['name'],
        'description': map['description'],
        'price': map['price'],
        'patient_limit': map['patient_limit'],
        'features': map['features'],
        'play_store_product_id': map['play_store_product_id'],
        'billing_period': map['billing_period'],
      };
    });
  }

  /// Cria ou atualiza assinatura do Play Store
  Future<void> syncPlayStoreSubscription({
    required int therapistId,
    required int planId,
    required String purchaseToken,
    required String orderId,
    required bool autoRenewing,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _dbConnection.withConnection((conn) async {
      // Desativa assinaturas anteriores do terapeuta
      await conn.execute(
        Sql.named('''
        UPDATE plan_subscriptions
        SET is_active = false
        WHERE therapist_id = @therapist_id
          AND is_active = true;
      '''),
        parameters: {'therapist_id': therapistId},
      );

      // Cria nova assinatura
      final subscriptionStartDate = startDate ?? DateTime.now();
      final subscriptionEndDate =
          endDate ?? DateTime(subscriptionStartDate.year, subscriptionStartDate.month + 1, subscriptionStartDate.day);

      await conn.execute(
        Sql.named('''
        INSERT INTO plan_subscriptions (
          therapist_id,
          plan_id,
          start_date,
          end_date,
          payment_method,
          play_store_purchase_token,
          play_store_order_id,
          auto_renewing,
          is_active
        ) VALUES (
          @therapist_id,
          @plan_id,
          @start_date,
          @end_date,
          @payment_method::payment_method,
          @purchase_token,
          @order_id,
          @auto_renewing,
          @is_active
        );
      '''),
        parameters: {
          'therapist_id': therapistId,
          'plan_id': planId,
          'start_date': subscriptionStartDate,
          'end_date': subscriptionEndDate,
          'payment_method': 'credit_card',
          'purchase_token': purchaseToken,
          'order_id': orderId,
          'auto_renewing': autoRenewing,
          'is_active': true,
        },
      );
    });
  }

  /// Atualiza status de renovação automática
  Future<void> updateAutoRenewingStatus({required int therapistId, required bool autoRenewing}) async {
    await _dbConnection.withConnection((conn) async {
      await conn.execute(
        Sql.named('''
        UPDATE plan_subscriptions
        SET auto_renewing = @auto_renewing
        WHERE therapist_id = @therapist_id
          AND is_active = true;
      '''),
        parameters: {'therapist_id': therapistId, 'auto_renewing': autoRenewing},
      );
    });
  }

  /// Busca assinatura por order_id do Play Store
  Future<Map<String, dynamic>?> getSubscriptionByOrderId(String orderId) async {
    return await _dbConnection.withConnection((conn) async {
      final results = await conn.execute(
        Sql.named('''
        SELECT 
          ps.id as subscription_id,
          ps.therapist_id,
          ps.plan_id,
          ps.start_date,
          ps.end_date,
          ps.payment_method::text,
          ps.is_active,
          ps.play_store_purchase_token,
          ps.play_store_order_id,
          ps.auto_renewing,
          p.name as plan_name
        FROM plan_subscriptions ps
        INNER JOIN plans p ON ps.plan_id = p.id
        WHERE ps.play_store_order_id = @order_id
        ORDER BY ps.created_at DESC
        LIMIT 1;
      '''),
        parameters: {'order_id': orderId},
      );

      if (results.isEmpty) {
        return null;
      }

      final map = results.first.toColumnMap();
      return {
        'subscription_id': map['subscription_id'],
        'therapist_id': map['therapist_id'],
        'plan_id': map['plan_id'],
        'plan_name': map['plan_name'],
        'start_date': map['start_date'],
        'end_date': map['end_date'],
        'is_active': map['is_active'],
        'auto_renewing': map['auto_renewing'],
      };
    });
  }
}
