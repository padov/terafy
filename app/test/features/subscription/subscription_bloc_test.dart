import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:terafy/core/domain/repositories/subscription_repository.dart';
import 'package:terafy/core/subscription/subscription_models.dart';
import 'package:terafy/features/subscription/bloc/subscription_bloc.dart';
import 'package:terafy/features/subscription/bloc/subscription_bloc_models.dart';

class _MockSubscriptionRepository extends Mock implements SubscriptionRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSubscriptionRepository repository;
  late SubscriptionBloc bloc;

  setUp(() {
    repository = _MockSubscriptionRepository();
    bloc = SubscriptionBloc(repository: repository);
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
          customAnamnesisLimit: 2,
        ),
        usage: const SubscriptionUsage(
          patientCount: 5,
          patientLimit: 999999,
          canCreatePatient: true,
          usagePercentage: 0,
          customAnamnesisCount: 1,
          customAnamnesisLimit: 2,
          canCreateAnamnesis: true,
        ),
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emite SubscriptionLoaded quando carrega status com sucesso',
        build: () {
          when(() => repository.getSubscriptionStatus()).thenAnswer((_) async => subscriptionStatus);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSubscriptionStatus()),
        expect: () => [
          const SubscriptionState(status: SubscriptionStatusEnum.loading),
          SubscriptionState(status: SubscriptionStatusEnum.loaded, subscriptionStatus: subscriptionStatus),
        ],
      );

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emite SubscriptionError quando ocorre erro',
        build: () {
          when(() => repository.getSubscriptionStatus()).thenThrow(Exception('Erro ao carregar'));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadSubscriptionStatus()),
        expect: () => [
          const SubscriptionState(status: SubscriptionStatusEnum.loading),
          const SubscriptionState(status: SubscriptionStatusEnum.error, errorMessage: 'Exception: Erro ao carregar'),
        ],
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
          customAnamnesisLimit: 0,
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
          customAnamnesisLimit: 2,
        ),
      ];

      blocTest<SubscriptionBloc, SubscriptionState>(
        'emite PlansLoaded quando carrega planos com sucesso',
        build: () {
          when(() => repository.getAvailablePlans()).thenAnswer((_) async => plans);
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadAvailablePlans()),
        expect: () => [SubscriptionState(status: SubscriptionStatusEnum.loaded, plans: plans)],
      );
    });
  });
}
