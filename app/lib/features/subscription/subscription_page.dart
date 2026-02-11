import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/subscription/bloc/subscription_bloc.dart';
import 'package:terafy/features/subscription/bloc/subscription_bloc_models.dart';
import 'package:terafy/features/subscription/widgets/plan_card.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SubscriptionBloc(
              repository: DependencyContainer().subscriptionRepository,
              subscriptionService: DependencyContainer().subscriptionService,
            )
            ..add(const LoadSubscriptionStatus())
            ..add(const LoadAvailablePlans()),
      child: const _SubscriptionPageContent(),
    );
  }
}

class _SubscriptionPageContent extends StatelessWidget {
  const _SubscriptionPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Planos de Assinatura', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.offBlack,
        elevation: 0,
        actions: [
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () {
                context.read<SubscriptionBloc>().add(const RestorePurchases());
              },
              tooltip: 'Restaurar compras',
            ),
        ],
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state.status == SubscriptionStatusEnum.error && state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red));
          } else if (state.status == SubscriptionStatusEnum.purchased) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Assinatura ativada com sucesso!'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state.status == SubscriptionStatusEnum.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == SubscriptionStatusEnum.error && state.plans == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'Erro desconhecido',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SubscriptionBloc>().add(const LoadSubscriptionStatus());
                      context.read<SubscriptionBloc>().add(const LoadAvailablePlans());
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final status = state.subscriptionStatus;
          final plans = state.plans;
          final plansWithProducts = state.plansWithProducts;
          final productDetails = state.productDetails;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status atual
                if (status != null) _buildCurrentStatus(context, status),

                const SizedBox(height: 24),

                if (kIsWeb)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Para assinar ou alterar seu plano, utilize o aplicativo Terafy em seu dispositivo Android ou iOS.',
                            style: TextStyle(color: Colors.blue[900], fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Título dos planos
                const Text(
                  'Escolha seu plano',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.offBlack),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecione o plano que melhor atende suas necessidades',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                // Lista de planos
                if (plans != null)
                  ...plans.map((plan) {
                    ProductDetails? productDetail;

                    // Tenta encontrar o productDetail correspondente
                    if (plansWithProducts != null) {
                      try {
                        final planWithProduct = plansWithProducts.firstWhere((p) => p.plan.id == plan.id);
                        productDetail = planWithProduct.productDetail;
                      } catch (e) {
                        // Produto não encontrado, productDetail fica null
                        productDetail = null;
                      }
                    }

                    // Se não encontrou e há productDetails disponíveis, tenta buscar pelo ID
                    if (productDetail == null && productDetails != null && plan.playStoreProductId != null) {
                      try {
                        productDetail = productDetails.firstWhere((pd) => pd.id == plan.playStoreProductId);
                      } catch (e) {
                        // Produto não encontrado
                        productDetail = null;
                      }
                    }

                    final isCurrentPlan = status?.plan.id == plan.id && (status?.hasActiveSubscription ?? false);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PlanCard(
                        plan: plan,
                        productDetails: productDetail,
                        isCurrentPlan: isCurrentPlan,
                        isPurchasing:
                            state.status == SubscriptionStatusEnum.purchasing &&
                            state.purchasingPlanId == plan.id.toString(),
                        onPurchase: productDetail != null && plan.playStoreProductId != null
                            ? () {
                                context.read<SubscriptionBloc>().add(
                                  PurchasePlan(planId: plan.id.toString(), productDetails: productDetail!),
                                );
                              }
                            : null,
                      ),
                    );
                  })
                else
                  const Center(
                    child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStatus(BuildContext context, dynamic status) {
    final usage = status.usage;
    final plan = status.plan;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Plano Atual', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    plan.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.offBlack),
                  ),
                ],
              ),
              if (status.hasActiveSubscription)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                    'Ativo',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progresso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Uso de Pacientes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
                  ),
                  Text(
                    '${usage.patientCount} / ${usage.patientLimit}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.offBlack),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: usage.patientLimit > 0 ? usage.patientCount / usage.patientLimit : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  usage.usagePercentage >= 80
                      ? Colors.orange
                      : usage.usagePercentage >= 100
                      ? Colors.red
                      : AppColors.primary,
                ),
                minHeight: 8,
              ),
              const SizedBox(height: 4),
              if (usage.usagePercentage >= 80)
                Text(
                  usage.usagePercentage >= 100
                      ? 'Limite atingido! Faça upgrade para adicionar mais pacientes.'
                      : 'Você está próximo do limite. Considere fazer upgrade.',
                  style: TextStyle(fontSize: 12, color: usage.usagePercentage >= 100 ? Colors.red : Colors.orange[700]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
