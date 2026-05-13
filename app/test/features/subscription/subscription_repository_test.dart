import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:terafy/core/data/repositories/subscription_repository_impl.dart';
import 'package:terafy/core/domain/repositories/subscription_repository.dart';
import 'package:terafy/core/subscription/subscription_models.dart';
import 'package:terafy/package/http.dart';

class _MockHttpClient extends Mock implements HttpClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockHttpClient httpClient;
  late SubscriptionRepository repository;

  setUp(() {
    httpClient = _MockHttpClient();
    repository = SubscriptionRepositoryImpl(httpClient: httpClient);
  });

  group('SubscriptionRepositoryImpl', () {
    group('getSubscriptionStatus', () {
      test('retorna SubscriptionStatus com sucesso', () async {
        // Arrange
        final responseData = {
          'subscription': {
            'id': 1,
            'therapist_id': 10,
            'plan_id': 2,
            'start_date': DateTime.now().toIso8601String(),
            'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
            'payment_method': 'credit_card',
            'is_active': true,
            'auto_renewing': true,
          },
          'plan': {
            'id': 2,
            'name': 'Starter',
            'description': 'Plano Starter',
            'price': 30.0,
            'patient_limit': 999999,
            'features': ['Pacientes ilimitados'],
            'play_store_product_id': 'starter_monthly',
            'billing_period': 'monthly',
          },
          'usage': {'patient_count': 5, 'patient_limit': 999999, 'can_create_patient': true, 'usage_percentage': 0},
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/subscription/status'),
        );

        when(() => httpClient.get('/subscription/status')).thenAnswer((_) async => response);

        // Act
        final result = await repository.getSubscriptionStatus();

        // Assert
        expect(result, isA<SubscriptionStatus>());
        expect(result.plan.name, equals('Starter'));
        expect(result.usage.patientCount, equals(5));
        expect(result.usage.canCreatePatient, isTrue);
      });

      test('lança exceção quando status code não é 200', () async {
        // Arrange
        final response = Response(
          data: {'error': 'Erro ao buscar status'},
          statusCode: 500,
          requestOptions: RequestOptions(path: '/subscription/status'),
        );

        when(() => httpClient.get('/subscription/status')).thenAnswer((_) async => response);

        // Act & Assert
        expect(() => repository.getSubscriptionStatus(), throwsA(isA<Exception>()));
      });
    });

    group('getAvailablePlans', () {
      test('retorna lista de planos disponíveis', () async {
        // Arrange
        final responseData = [
          {
            'id': 1,
            'name': 'Free',
            'description': 'Plano gratuito',
            'price': 0.0,
            'patient_limit': 10,
            'features': ['Até 10 pacientes'],
            'play_store_product_id': null,
            'billing_period': 'monthly',
          },
          {
            'id': 2,
            'name': 'Starter',
            'description': 'Plano Starter',
            'price': 30.0,
            'patient_limit': 999999,
            'features': ['Pacientes ilimitados'],
            'play_store_product_id': 'starter_monthly',
            'billing_period': 'monthly',
          },
        ];

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/subscription/plans'),
        );

        when(() => httpClient.get('/subscription/plans')).thenAnswer((_) async => response);

        // Act
        final result = await repository.getAvailablePlans();

        // Assert
        expect(result, hasLength(2));
        expect(result.first.name, equals('Free'));
        expect(result.last.name, equals('Starter'));
      });
    });

    group('verifyPlayStoreSubscription', () {
      test('verifica e sincroniza assinatura com sucesso', () async {
        // Arrange
        final responseData = {
          'subscription': {'id': 1, 'therapist_id': 10, 'plan_id': 2, 'is_active': true},
          'plan': {'id': 2, 'name': 'Starter', 'price': 30.0, 'patient_limit': 999999},
          'usage': {'patient_count': 0, 'patient_limit': 999999, 'can_create_patient': true, 'usage_percentage': 0},
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/subscription/verify'),
        );

        when(() => httpClient.post('/subscription/verify', data: any(named: 'data'))).thenAnswer((_) async => response);

        // Act
        final result = await repository.verifyPlayStoreSubscription(
          purchaseToken: 'token123',
          orderId: 'order123',
          productId: 'starter_monthly',
          autoRenewing: true,
        );

        // Assert
        expect(result, isA<SubscriptionStatus>());
        expect(result.plan.name, equals('Starter'));
      });
    });

    group('getUsageInfo', () {
      test('retorna informações de uso', () async {
        // Arrange
        final responseData = {
          'patient_count': 8,
          'patient_limit': 10,
          'can_create_patient': true,
          'usage_percentage': 80,
        };

        final response = Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/subscription/usage'),
        );

        when(() => httpClient.get('/subscription/usage')).thenAnswer((_) async => response);

        // Act
        final result = await repository.getUsageInfo();

        // Assert
        expect(result, isA<SubscriptionUsage>());
        expect(result.patientCount, equals(8));
        expect(result.patientLimit, equals(10));
        expect(result.canCreatePatient, isTrue);
        expect(result.usagePercentage, equals(80));
      });
    });
  });
}
