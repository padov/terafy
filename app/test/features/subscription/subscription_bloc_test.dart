import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:terafy/core/domain/repositories/subscription_repository.dart';
import 'package:terafy/core/subscription/subscription_models.dart';
import 'package:terafy/core/subscription/subscription_service.dart';
import 'package:terafy/features/subscription/bloc/subscription_bloc.dart';
import 'package:terafy/features/subscription/bloc/subscription_bloc_models.dart';

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

class _MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSubscriptionRepository repository;
  late _MockSubscriptionService service;
  late SubscriptionBloc bloc;

  setUp(() {
    repository = _MockSubscriptionRepository();
    service = _MockSubscriptionService();
    bloc = SubscriptionBloc(repository: repository, subscriptionService: service);
  });

  tearDown(() {
    bloc.close();
  });

  group('SubscriptionBloc', () {
    group('LoadSubscriptionStatus', () {
      final subscriptionStatus = SubscriptionStatus(
        subscription: Subscription(
          therapistId: 10,
          planId: 2,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          paymentMethod: 'credit_card',
          isActive: true,
          autoRenewing: true,
        ),
        plan: const SubscriptionPlan(
          id: 2,
          name: 'Starter',
          description: 'Plano Starter',
          price: 30.0,
          patientLimit: 999999,
          features: ['Pacientes ilimitados'],
          playStoreProductId: 'starter_monthly',
          billingPeriod: 'monthly',
        ),
        usage: const SubscriptionUsage(
          patientCount: 5,
          patientLimit: 999999,
          canCreatePatient: true,
          usagePercentage: 0,
        ),
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emite SubscriptionLoaded quando carrega status com sucesso',
        build: () {
          when(() => repository.getSubscriptionStatus()).thenAnswer((_) async => subscriptionStatus);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSubscriptionStatus()),
        expect: () => [const SubscriptionLoading(), SubscriptionLoaded(status: subscriptionStatus)],
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emite SubscriptionError quando ocorre erro',
        build: () {
          when(() => repository.getSubscriptionStatus()).thenThrow(Exception('Erro ao carregar'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSubscriptionStatus()),
        expect: () => [const SubscriptionLoading(), const SubscriptionError(message: 'Exception: Erro ao carregar')],
      );
    });

    group('LoadAvailablePlans', () {
      final plans = [
        const SubscriptionPlan(
          id: 1,
          name: 'Free',
          description: 'Plano gratuito',
          price: 0.0,
          patientLimit: 10,
          features: ['Até 10 pacientes'],
          billingPeriod: 'monthly',
        ),
        const SubscriptionPlan(
          id: 2,
          name: 'Starter',
          description: 'Plano Starter',
          price: 30.0,
          patientLimit: 999999,
          features: ['Pacientes ilimitados'],
          playStoreProductId: 'starter_monthly',
          billingPeriod: 'monthly',
        ),
      ];

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emite PlansLoaded quando carrega planos com sucesso',
        build: () {
          when(() => repository.getAvailablePlans()).thenAnswer((_) async => plans);
          when(() => service.checkAvailability()).thenAnswer((_) async => false);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAvailablePlans()),
        expect: () => [PlansLoaded(plans: plans)],
      );
    });

    group('RestorePurchases', () {
      final subscriptionStatus = SubscriptionStatus(
        plan: const SubscriptionPlan(
          id: 2,
          name: 'Starter',
          description: 'Plano Starter',
          price: 30.0,
          patientLimit: 999999,
          features: [],
          billingPeriod: 'monthly',
        ),
        usage: const SubscriptionUsage(
          patientCount: 0,
          patientLimit: 999999,
          canCreatePatient: true,
          usagePercentage: 0,
        ),
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emite SubscriptionRestoring e recarrega status quando restaura com sucesso',
        build: () {
          when(() => service.restorePurchases()).thenAnswer((_) async => true);
          when(() => repository.getSubscriptionStatus()).thenAnswer((_) async => subscriptionStatus);
          return bloc;
        },
        act: (bloc) => bloc.add(const RestorePurchases()),
        expect: () => [
          const SubscriptionRestoring(),
          const SubscriptionLoading(),
          SubscriptionLoaded(status: subscriptionStatus),
        ],
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emite SubscriptionError quando restauração falha',
        build: () {
          when(() => service.restorePurchases()).thenAnswer((_) async => false);
          return bloc;
        },
        act: (bloc) => bloc.add(const RestorePurchases()),
        expect: () => [const SubscriptionRestoring(), const SubscriptionError(message: 'Erro ao restaurar compras')],
      );
    });
  });
}
