import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:terafy/common/app_colors.dart';

class RevenueChart extends StatelessWidget {
  final dynamic summary;
  final String period;
  final DateTime selectedDate;

  const RevenueChart({super.key, required this.summary, required this.period, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      /*
      child: BarChart(
        BarChartData(
          // ... (existing code) ...
        ),
      ),
      */
      child: const Center(
        child: Text(
          'Gráfico indisponível.\nAguardando implementação de dados históricos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  /*
  List<BarChartGroupData> _getBarGroups() {
    // Mock data - 7 dias da semana ou meses do ano
    if (period == 'month') {
      // Últimos 7 dias
      return List.generate(7, (index) {
        final revenue = _getMockDailyRevenue(index);
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: revenue,
              color: AppColors.primary,
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.primary.withOpacity(0.7), AppColors.primary],
              ),
            ),
          ],
        );
      });
    } else {
      // 12 meses do ano
      return List.generate(12, (index) {
        final revenue = _getMockMonthlyRevenue(index);
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: revenue,
              color: AppColors.primary,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.primary.withOpacity(0.7), AppColors.primary],
              ),
            ),
          ],
        );
      });
    }
  }

  double _getMockDailyRevenue(int dayIndex) {
    // Mock data para receita diária (últimos 7 dias)
    final revenues = [400.0, 600.0, 200.0, 800.0, 600.0, 1000.0, 400.0];
    return revenues[dayIndex];
  }

  double _getMockMonthlyRevenue(int monthIndex) {
    // Mock data para receita mensal
    final revenues = [
      1800.0, // Jan
      2400.0, // Fev
      4200.0, // Mar
      3600.0, // Abr
      3200.0, // Mai
      2800.0, // Jun
      3400.0, // Jul
      3800.0, // Ago
      3000.0, // Set
      3600.0, // Out
      4000.0, // Nov
      3400.0, // Dez
    ];
    return revenues[monthIndex];
  }

  double _getMaxY() {
    if (period == 'month') {
      return 1200.0; // Máximo para gráfico diário
    } else {
      return 5000.0; // Máximo para gráfico mensal
    }
  }

  String _getBottomTitle(int value) {
    if (period == 'month') {
      // Dias da semana
      final days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      return value < days.length ? days[value] : '';
    } else {
      // Meses
      final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      return value < months.length ? months[value] : '';
    }
  }
  */
}
