import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/financial/bloc/financial_bloc.dart';
import 'package:terafy/features/financial/bloc/financial_bloc_models.dart';
import 'package:terafy/features/financial/reports/widgets/revenue_chart.dart';
import 'package:terafy/features/financial/reports/widgets/payment_status_chart.dart';
import 'package:terafy/features/financial/reports/widgets/monthly_comparison_chart.dart';

class FinancialReportsPage extends StatefulWidget {
  const FinancialReportsPage({super.key});

  @override
  State<FinancialReportsPage> createState() => _FinancialReportsPageState();
}

class _FinancialReportsPageState extends State<FinancialReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _period = 'month'; // 'month' ou 'year'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    DateTime startDate;
    DateTime endDate;

    if (_period == 'month') {
      startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    } else {
      startDate = DateTime(_selectedDate.year, 1, 1);
      endDate = DateTime(_selectedDate.year, 12, 31);
    }

    context.read<FinancialBloc>().add(
      LoadFinancialSummary(startDate: startDate, endDate: endDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relatórios Financeiros',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Receitas'),
            Tab(text: 'Status'),
            Tab(text: 'Comparativo'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: BlocProvider(
              create: (context) {
                final container = DependencyContainer();
                return FinancialBloc(
                  getTransactionsUseCase: container.getTransactionsUseCase,
                  getTransactionUseCase: container.getTransactionUseCase,
                  createTransactionUseCase: container.createTransactionUseCase,
                  updateTransactionUseCase: container.updateTransactionUseCase,
                  deleteTransactionUseCase: container.deleteTransactionUseCase,
                  getFinancialSummaryUseCase:
                      container.getFinancialSummaryUseCase,
                  getCurrentTherapistUseCase:
                      container.getCurrentTherapistUseCase,
                );
              },
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRevenueTab(),
                  _buildStatusTab(),
                  _buildComparisonTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Seletor Mês/Ano
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPeriodButton('Mês', 'month'),
              const SizedBox(width: 12),
              _buildPeriodButton('Ano', 'year'),
            ],
          ),
          const SizedBox(height: 12),
          // Navegação de período
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_period == 'month') {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month - 1,
                      );
                    } else {
                      _selectedDate = DateTime(_selectedDate.year - 1);
                    }
                  });
                  _loadData();
                },
                icon: const Icon(Icons.chevron_left),
                color: AppColors.primary,
              ),
              const SizedBox(width: 16),
              Text(
                _getPeriodLabel(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.offBlack,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_period == 'month') {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month + 1,
                      );
                    } else {
                      _selectedDate = DateTime(_selectedDate.year + 1);
                    }
                  });
                  _loadData();
                },
                icon: const Icon(Icons.chevron_right),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _period == value;
    return InkWell(
      onTap: () {
        setState(() => _period = value);
        _loadData();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.offBlack,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _getPeriodLabel() {
    if (_period == 'month') {
      return DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate);
    } else {
      return _selectedDate.year.toString();
    }
  }

  Widget _buildRevenueTab() {
    return BlocBuilder<FinancialBloc, FinancialState>(
      builder: (context, state) {
        if (state is FinancialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FinancialSummaryLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(state.summary),
                const SizedBox(height: 24),
                const Text(
                  'Receita por Dia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.offBlack,
                  ),
                ),
                const SizedBox(height: 16),
                RevenueChart(
                  summary: state.summary,
                  period: _period,
                  selectedDate: _selectedDate,
                ),
              ],
            ),
          );
        }

        return const Center(child: Text('Nenhum dado disponível'));
      },
    );
  }

  Widget _buildStatusTab() {
    return BlocBuilder<FinancialBloc, FinancialState>(
      builder: (context, state) {
        if (state is FinancialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FinancialSummaryLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distribuição por Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.offBlack,
                  ),
                ),
                const SizedBox(height: 16),
                PaymentStatusChart(summary: state.summary),
                const SizedBox(height: 24),
                _buildStatusList(state.summary),
              ],
            ),
          );
        }

        return const Center(child: Text('Nenhum dado disponível'));
      },
    );
  }

  Widget _buildComparisonTab() {
    return BlocBuilder<FinancialBloc, FinancialState>(
      builder: (context, state) {
        if (state is FinancialLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FinancialSummaryLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comparativo Mensal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.offBlack,
                  ),
                ),
                const SizedBox(height: 16),
                MonthlyComparisonChart(year: _selectedDate.year),
                const SizedBox(height: 24),
                _buildComparisonInsights(),
              ],
            ),
          );
        }

        return const Center(child: Text('Nenhum dado disponível'));
      },
    );
  }

  Widget _buildSummaryCards(dynamic summary) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniCard(
                'Recebido',
                currencyFormat.format(summary.totalReceived),
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniCard(
                'Pendente',
                currencyFormat.format(summary.totalPending),
                Colors.orange,
                Icons.schedule,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniCard(
                'Atrasado',
                currencyFormat.format(summary.totalOverdue),
                Colors.red,
                Icons.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniCard(
                'Total',
                currencyFormat.format(
                  summary.totalReceived +
                      summary.totalPending +
                      summary.totalOverdue,
                ),
                AppColors.primary,
                Icons.attach_money,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusList(dynamic summary) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final total =
        summary.totalReceived + summary.totalPending + summary.totalOverdue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Column(
        children: [
          _buildStatusRow(
            'Pagamentos Recebidos',
            currencyFormat.format(summary.totalReceived),
            Colors.green,
            summary.totalReceived / total,
          ),
          const Divider(height: 24),
          _buildStatusRow(
            'Pagamentos Pendentes',
            currencyFormat.format(summary.totalPending),
            Colors.orange,
            summary.totalPending / total,
          ),
          const Divider(height: 24),
          _buildStatusRow(
            'Pagamentos Atrasados',
            currencyFormat.format(summary.totalOverdue),
            Colors.red,
            summary.totalOverdue / total,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    String value,
    Color color,
    double percentage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.offBlack,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage.isNaN ? 0 : percentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonInsights() {
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
          const Row(
            children: [
              Icon(Icons.insights, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.offBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.trending_up,
            'Melhor Mês',
            'Março - R\$ 4.200,00',
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildInsightItem(
            Icons.trending_down,
            'Pior Mês',
            'Janeiro - R\$ 1.800,00',
            Colors.red,
          ),
          const SizedBox(height: 8),
          _buildInsightItem(
            Icons.show_chart,
            'Média Mensal',
            'R\$ 3.000,00',
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
