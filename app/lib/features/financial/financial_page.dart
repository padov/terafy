import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/financial/bloc/financial_bloc.dart';
import 'package:terafy/features/financial/bloc/financial_bloc_models.dart';
import 'package:terafy/features/financial/models/payment.dart';
import 'package:terafy/routes/app_routes.dart';

class FinancialPage extends StatelessWidget {
  const FinancialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final container = DependencyContainer();
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, 1);
        final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

        return FinancialBloc(
            getTransactionsUseCase: container.getTransactionsUseCase,
            getTransactionUseCase: container.getTransactionUseCase,
            createTransactionUseCase: container.createTransactionUseCase,
            updateTransactionUseCase: container.updateTransactionUseCase,
            deleteTransactionUseCase: container.deleteTransactionUseCase,
            getFinancialSummaryUseCase: container.getFinancialSummaryUseCase,
            getCurrentTherapistUseCase: container.getCurrentTherapistUseCase,
          )
          ..add(LoadFinancialSummary(startDate: startDate, endDate: endDate))
          ..add(const LoadPayments());
      },
      child: const _FinancialPageContent(),
    );
  }
}

class _FinancialPageContent extends StatefulWidget {
  const _FinancialPageContent();

  @override
  State<_FinancialPageContent> createState() => _FinancialPageContentState();
}

class _FinancialPageContentState extends State<_FinancialPageContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PaymentStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Financeiro', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Pagamentos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: TabBarView(controller: _tabController, children: [_buildDashboardTab(), _buildPaymentsTab()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navegar para criar pagamento
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Criar pagamento em desenvolvimento')));
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Novo Pagamento', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return BlocBuilder<FinancialBloc, FinancialState>(
      builder: (context, state) {
        if (state is FinancialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FinancialData && state.summary != null) {
          return _buildDashboard(context, state.summary!);
        }

        return const Center(child: Text('Nenhum dado disponível'));
      },
    );
  }

  Widget _buildDashboard(BuildContext context, FinancialSummary summary) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return RefreshIndicator(
      onRefresh: () async {
        context.read<FinancialBloc>().add(LoadFinancialSummary(startDate: summary.startDate, endDate: summary.endDate));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Período
          Text(
            'Período: ${DateFormat('dd/MM/yyyy').format(summary.startDate)} - ${DateFormat('dd/MM/yyyy').format(summary.endDate)}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Cards de resumo
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                  title: 'Recebido',
                  value: currencyFormat.format(summary.totalReceived),
                  backgroundColor: Colors.green.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.schedule,
                  iconColor: Colors.orange,
                  title: 'Pendente',
                  value: currencyFormat.format(summary.totalPending),
                  backgroundColor: Colors.orange.withOpacity(0.1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.warning,
                  iconColor: Colors.red,
                  title: 'Atrasado',
                  value: currencyFormat.format(summary.totalOverdue),
                  backgroundColor: Colors.red.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.attach_money,
                  iconColor: AppColors.primary,
                  title: 'Total',
                  value: currencyFormat.format(summary.total),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Gráficos
          _buildCharts(context, summary),

          const SizedBox(height: 24),

          // Estatísticas de sessões
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sessões',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.offBlack),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Realizadas', summary.sessionsCompleted.toString(), Colors.green),
                    Container(width: 1, height: 40, color: AppColors.lightBorderColor),
                    _buildStatItem('Pendentes', summary.sessionsPending.toString(), Colors.orange),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botão para ver relatórios
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.financialReportsRoute);
            },
            icon: const Icon(Icons.bar_chart),
            label: const Text('Ver Relatórios Detalhados'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(BuildContext context, FinancialSummary summary) {
    return Column(
      children: [
        // Gráfico de Inadimplência
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inadimplência',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.offBlack),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: Colors.red,
                        value: summary.overduePercentage,
                        title: '${summary.overduePercentage.toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        color: Colors.green,
                        value: 100 - summary.overduePercentage,
                        title: '',
                        radius: 50,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildChartLegend(color: Colors.green, label: 'Em dia'),
                  const SizedBox(width: 24),
                  _buildChartLegend(color: Colors.red, label: 'Atrasado'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Gráfico de Métodos de Pagamento
        if (summary.paymentMethodDistribution.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Métodos de Pagamento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.offBlack),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: summary.paymentMethodDistribution.map((item) {
                        final index = summary.paymentMethodDistribution.indexOf(item);
                        final colors = [
                          Colors.blue,
                          Colors.purple,
                          Colors.orange,
                          Colors.teal,
                          Colors.indigo,
                          Colors.pink,
                        ];
                        final color = colors[index % colors.length];
                        return PieChartSectionData(color: color, value: item.amount, title: '', radius: 50);
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: summary.paymentMethodDistribution.map((item) {
                    final index = summary.paymentMethodDistribution.indexOf(item);
                    final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.teal, Colors.indigo, Colors.pink];
                    return _buildChartLegend(
                      color: colors[index % colors.length],
                      label:
                          '${_getPaymentMethodLabelFromString(item.method)} (${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(item.amount)})',
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChartLegend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
        ),
      ],
    );
  }

  String _getPaymentMethodLabelFromString(String method) {
    switch (method) {
      case 'cash':
        return 'Dinheiro';
      case 'creditCard':
      case 'credit_card':
        return 'Crédito';
      case 'debitCard':
      case 'debit_card':
        return 'Débito';
      case 'pix':
        return 'PIX';
      case 'bankTransfer':
      case 'transfer':
        return 'Transferência';
      case 'healthInsurance':
      case 'insurance':
        return 'Convênio';
      default:
        return 'Outro';
    }
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.offBlack),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab() {
    return BlocBuilder<FinancialBloc, FinancialState>(
      builder: (context, state) {
        if (state is FinancialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FinancialData && state.payments != null) {
          if (state.payments!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Nenhum pagamento encontrado', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<FinancialBloc>().add(const LoadPayments());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.payments!.length,
              itemBuilder: (context, index) {
                final payment = state.payments![index];
                return _buildPaymentCard(context, payment);
              },
            ),
          );
        }

        return const Center(child: Text('Nenhum dado disponível'));
      },
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment payment) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final colors = _getStatusColors(payment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).pushNamed(AppRouter.paymentDetailsRoute, arguments: payment.id);

          if (context.mounted) {
            final bloc = context.read<FinancialBloc>();
            final state = bloc.state;

            // Reload based on current state parameters to ensure data is fresh
            if (state is FinancialData) {
              if (state.summaryStartDate != null && state.summaryEndDate != null) {
                bloc.add(LoadFinancialSummary(startDate: state.summaryStartDate!, endDate: state.summaryEndDate!));
              }
              // For payments, we use the default LoadPayments which uses bloc's internal filtering logic
              // or passing explicit filters if they were stored.
              // LoadPayments in FinancialBloc seems to just take new params?
              // The event constructor has params.
              // In _onLoadPayments, we used event params.
              // In the UI, we just called const LoadPayments().
              // Let's call pure LoadPayments() again, assuming it defaults correctly or reuse state params if we stored them in UI?
              // Wait, LoadPayments has optional params.
              // If we pass nothing, what dates/filters does it use?
              // The original bloc _onLoadPayments took event.statusFilter.
              // If event.statusFilter is null, it uses none?
              // FinancialData stores the current statusFilter.
              bloc.add(
                LoadPayments(
                  statusFilter: state.statusFilter,
                  startDate: state.paymentsStartDate,
                  endDate: state.paymentsEndDate,
                  patientIdFilter: state.patientIdFilter,
                ),
              );
            } else {
              // Fallback if not FinancialData (unlikely if we just tapped a card)
              bloc.add(const LoadPayments());
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Valor
                  Text(
                    currencyFormat.format(payment.amount),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.offBlack),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors['background'],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors['border']!, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(payment.status), size: 14, color: colors['border']),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusLabel(payment.status),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors['text']),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Paciente ID (temporário)
              Text(
                'Paciente: ${payment.patientId}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.offBlack),
              ),

              const SizedBox(height: 8),

              // Data de vencimento
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Vencimento: ${dateFormat.format(payment.dueDate)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  if (payment.isOverdue) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${payment.daysOverdue} dias)',
                      style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),

              // Método de pagamento (se pago)
              if (payment.method != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.payment, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      _getPaymentMethodLabel(payment.method!),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Filtrar Pagamentos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todos'),
              leading: Radio<PaymentStatus?>(
                value: null,
                groupValue: _selectedStatusFilter,
                onChanged: (value) {
                  setState(() => _selectedStatusFilter = value);
                  Navigator.of(dialogContext).pop();
                  context.read<FinancialBloc>().add(LoadPayments(statusFilter: value));
                },
              ),
            ),
            ListTile(
              title: const Text('Pagos'),
              leading: Radio<PaymentStatus?>(
                value: PaymentStatus.paid,
                groupValue: _selectedStatusFilter,
                onChanged: (value) {
                  setState(() => _selectedStatusFilter = value);
                  Navigator.of(dialogContext).pop();
                  context.read<FinancialBloc>().add(LoadPayments(statusFilter: value));
                },
              ),
            ),
            ListTile(
              title: const Text('Pendentes'),
              leading: Radio<PaymentStatus?>(
                value: PaymentStatus.pending,
                groupValue: _selectedStatusFilter,
                onChanged: (value) {
                  setState(() => _selectedStatusFilter = value);
                  Navigator.of(dialogContext).pop();
                  context.read<FinancialBloc>().add(LoadPayments(statusFilter: value));
                },
              ),
            ),
            ListTile(
              title: const Text('Atrasados'),
              leading: Radio<PaymentStatus?>(
                value: PaymentStatus.overdue,
                groupValue: _selectedStatusFilter,
                onChanged: (value) {
                  setState(() => _selectedStatusFilter = value);
                  Navigator.of(dialogContext).pop();
                  context.read<FinancialBloc>().add(LoadPayments(statusFilter: value));
                },
              ),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Fechar'))],
      ),
    );
  }

  Map<String, Color> _getStatusColors(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return {'background': Colors.orange.withOpacity(0.1), 'border': Colors.orange, 'text': Colors.orange.shade700};
      case PaymentStatus.paid:
        return {'background': Colors.green.withOpacity(0.1), 'border': Colors.green, 'text': Colors.green.shade700};
      case PaymentStatus.overdue:
        return {'background': Colors.red.withOpacity(0.1), 'border': Colors.red, 'text': Colors.red.shade700};
      case PaymentStatus.cancelled:
        return {'background': Colors.grey.withOpacity(0.1), 'border': Colors.grey, 'text': Colors.grey.shade700};
      case PaymentStatus.refunded:
        return {'background': Colors.blue.withOpacity(0.1), 'border': Colors.blue, 'text': Colors.blue.shade700};
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.overdue:
        return Icons.warning;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.refunded:
        return Icons.refresh;
    }
  }

  String _getStatusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pendente';
      case PaymentStatus.paid:
        return 'Pago';
      case PaymentStatus.overdue:
        return 'Atrasado';
      case PaymentStatus.cancelled:
        return 'Cancelado';
      case PaymentStatus.refunded:
        return 'Reembolsado';
    }
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Dinheiro';
      case PaymentMethod.creditCard:
        return 'Cartão de Crédito';
      case PaymentMethod.debitCard:
        return 'Cartão de Débito';
      case PaymentMethod.pix:
        return 'PIX';
      case PaymentMethod.bankTransfer:
        return 'Transferência';
      case PaymentMethod.healthInsurance:
        return 'Convênio';
      case PaymentMethod.other:
        return 'Outro';
    }
  }
}
