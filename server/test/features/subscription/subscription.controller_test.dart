import 'package:mocktail/mocktail.dart';
import 'package:server/features/subscription/subscription.controller.dart';
import 'package:server/features/subscription/subscription.repository.dart';
import 'package:server/features/therapist/therapist.repository.dart';
import 'package:test/test.dart';

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

class _MockTherapistRepository extends Mock implements TherapistRepository {}

void main() {
  late _MockSubscriptionRepository subscriptionRepository;
  late _MockTherapistRepository therapistRepository;
  late SubscriptionController controller;

  setUp(() {
    subscriptionRepository = _MockSubscriptionRepository();
    therapistRepository = _MockTherapistRepository();
    controller = SubscriptionController(subscriptionRepository, therapistRepository);
  });

  group('SubscriptionController', () {
    group('getSubscriptionStatus', () {
      test('retorna status com assinatura ativa', () async {
        // Arrange
        const userId = 1;
        final therapistData = {'id': 10, 'name': 'Terapeuta Teste'};

        final subscriptionData = {
          'subscription': {
            'id': 1,
            'therapist_id': 10,
            'plan_id': 2,
            'start_date': DateTime.now().toIso8601String(),
            'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
            'is_active': true,
            'auto_renewing': true,
          },
          'plan': {
            'id': 2,
            'name': 'Starter',
            'price': 30.0,
            'patient_limit': 999999,
            'features': ['Pacientes ilimitados'],
          },
        };

        when(() => therapistRepository.getTherapistByUserIdWithPlan(userId)).thenAnswer((_) async => therapistData);
        when(() => subscriptionRepository.getActiveSubscription(10)).thenAnswer((_) async => subscriptionData);
        when(() => subscriptionRepository.countActivePatients(10)).thenAnswer((_) async => 5);

        // Act
        final result = await controller.getSubscriptionStatus(userId);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['plan'], isNotNull);
        expect(result['usage'], isNotNull);
        expect(result['usage']['patient_count'], equals(5));
        expect(result['usage']['can_create_patient'], isTrue);
      });

      test('retorna status com plano padrão quando não há assinatura', () async {
        // Arrange
        const userId = 1;
        final therapistData = {'id': 10, 'name': 'Terapeuta Teste'};

        final defaultPlan = {
          'plan': {'id': 1, 'name': 'Free', 'price': 0.0, 'patient_limit': 10, 'features': []},
        };

        when(() => therapistRepository.getTherapistByUserIdWithPlan(userId)).thenAnswer((_) async => therapistData);
        when(() => subscriptionRepository.getActiveSubscription(10)).thenAnswer((_) async => null);
        when(() => subscriptionRepository.getDefaultPlan()).thenAnswer((_) async => defaultPlan);
        when(() => subscriptionRepository.countActivePatients(10)).thenAnswer((_) async => 3);

        // Act
        final result = await controller.getSubscriptionStatus(userId);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['plan']['name'], equals('Free'));
        expect(result['usage']['patient_limit'], equals(10));
        expect(result['usage']['can_create_patient'], isTrue);
      });

      test('lança exceção quando terapeuta não encontrado', () async {
        // Arrange
        const userId = 999;

        when(() => therapistRepository.getTherapistByUserIdWithPlan(userId)).thenAnswer((_) async => null);

        // Act & Assert
        expect(() => controller.getSubscriptionStatus(userId), throwsA(isA<SubscriptionException>()));
      });
    });

    group('canCreatePatient', () {
      test('retorna true quando pode criar paciente', () async {
        // Arrange
        const userId = 1;
        final therapistData = {'id': 10};

        when(() => therapistRepository.getTherapistByUserIdWithPlan(userId)).thenAnswer((_) async => therapistData);
        when(() => subscriptionRepository.canCreatePatient(10)).thenAnswer((_) async => true);

        // Act
        final result = await controller.canCreatePatient(userId);

        // Assert
        expect(result, isTrue);
      });

      test('retorna false quando limite atingido', () async {
        // Arrange
        const userId = 1;
        final therapistData = {'id': 10};

        when(() => therapistRepository.getTherapistByUserIdWithPlan(userId)).thenAnswer((_) async => therapistData);
        when(() => subscriptionRepository.canCreatePatient(10)).thenAnswer((_) async => false);

        // Act
        final result = await controller.canCreatePatient(userId);

        // Assert
        expect(result, isFalse);
      });
    });

    group('getAvailablePlans', () {
      test('retorna lista de planos disponíveis', () async {
        // Arrange
        final plans = [
          {'id': 1, 'name': 'Free', 'price': 0.0, 'patient_limit': 10},
          {'id': 2, 'name': 'Starter', 'price': 30.0, 'patient_limit': 999999},
        ];

        when(() => subscriptionRepository.getAvailablePlans()).thenAnswer((_) async => plans);

        // Act
        final result = await controller.getAvailablePlans();

        // Assert
        expect(result, hasLength(2));
        expect(result.first['name'], equals('Free'));
        expect(result.last['name'], equals('Starter'));
      });
    });

    group('verifyPlayStoreSubscription', () {
      test('sincroniza assinatura do Play Store com sucesso', () async {
        // Arrange
        const userId = 1;
        final therapistData = {'id': 10};

        final planData = {'id': 2, 'name': 'Starter'};

        final subscriptionData = {
          'subscription': {'id': 1, 'therapist_id': 10, 'plan_id': 2, 'is_active': true},
          'plan': {'id': 2, 'name': 'Starter', 'price': 30.0, 'patient_limit': 999999},
        };

        when(() => therapistRepository.getTherapistByUserIdWithPlan(userId)).thenAnswer((_) async => therapistData);
        when(() => subscriptionRepository.getPlanByProductId('starter_monthly')).thenAnswer((_) async => planData);
        when(() => subscriptionRepository.getSubscriptionByOrderId('order123')).thenAnswer((_) async => null);
        when(
          () => subscriptionRepository.syncPlayStoreSubscription(
            therapistId: 10,
            planId: 2,
            purchaseToken: 'token123',
            orderId: 'order123',
            autoRenewing: true,
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => {});
        when(() => subscriptionRepository.getActiveSubscription(10)).thenAnswer((_) async => subscriptionData);
        when(() => subscriptionRepository.countActivePatients(10)).thenAnswer((_) async => 0);

        // Act
        final result = await controller.verifyPlayStoreSubscription(
          userId: userId,
          purchaseToken: 'token123',
          orderId: 'order123',
          productId: 'starter_monthly',
          autoRenewing: true,
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['plan']['name'], equals('Starter'));
      });

      test('lança exceção quando plano não encontrado', () async {
        // Arrange
        const userId = 1;
        final therapistData = {'id': 10};

        when(() => therapistRepository.getTherapistByUserIdWithPlan(userId)).thenAnswer((_) async => therapistData);
        when(() => subscriptionRepository.getPlanByProductId('invalid_product')).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => controller.verifyPlayStoreSubscription(
            userId: userId,
            purchaseToken: 'token123',
            orderId: 'order123',
            productId: 'invalid_product',
            autoRenewing: true,
          ),
          throwsA(isA<SubscriptionException>()),
        );
      });
    });
  });
}
