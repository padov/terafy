import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:terafy/common/app_colors.dart';

class MonthlyComparisonChart extends StatelessWidget {
  final int year;

  const MonthlyComparisonChart({super.key, required this.year});

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
      child: LineChart(
        LineChartData(
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
  List<FlSpot> _getRevenueSpots() {
    // Mock data: Receitas mensais
    final revenues = [1800.0, 2400.0, 4200.0, 3600.0, 3200.0, 2800.0, 3400.0, 3800.0, 3000.0, 3600.0, 4000.0, 3400.0];
    return List.generate(revenues.length, (index) => FlSpot(index.toDouble(), revenues[index]));
  }

  List<FlSpot> _getPendingSpots() {
    // Mock data: Pendentes mensais
    final pending = [400.0, 600.0, 800.0, 400.0, 600.0, 400.0, 600.0, 800.0, 400.0, 600.0, 800.0, 600.0];
    return List.generate(pending.length, (index) => FlSpot(index.toDouble(), pending[index]));
  }

  List<FlSpot> _getOverdueSpots() {
    // Mock data: Atrasados mensais
    final overdue = [200.0, 200.0, 400.0, 200.0, 400.0, 200.0, 400.0, 200.0, 200.0, 400.0, 400.0, 200.0];
    return List.generate(overdue.length, (index) => FlSpot(index.toDouble(), overdue[index]));
  }

  String _getMonthLabel(int monthIndex) {
    const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return monthIndex >= 0 && monthIndex < months.length ? months[monthIndex] : '';
  }
  */
}
