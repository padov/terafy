import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1000,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: AppColors.lightBorderColor, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _getMonthLabel(value.toInt()),
                      style: const TextStyle(
                        color: AppColors.offBlack,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 32,
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    'R\$${(value / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  );
                },
                reservedSize: 48,
                interval: 1000,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: AppColors.lightBorderColor),
              left: BorderSide(color: AppColors.lightBorderColor),
            ),
          ),
          minX: 0,
          maxX: 11,
          minY: 0,
          maxY: 5000,
          lineBarsData: [
            // Linha de receitas
            LineChartBarData(
              spots: _getRevenueSpots(),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.green,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green.withOpacity(0.3),
                    Colors.green.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            // Linha de pendentes
            LineChartBarData(
              spots: _getPendingSpots(),
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.orange,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.orange.withOpacity(0.3),
                    Colors.orange.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            // Linha de atrasados
            LineChartBarData(
              spots: _getOverdueSpots(),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.red,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.red.withOpacity(0.3),
                    Colors.red.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final label = barSpot.barIndex == 0
                      ? 'Recebido'
                      : barSpot.barIndex == 1
                      ? 'Pendente'
                      : 'Atrasado';
                  return LineTooltipItem(
                    '$label\nR\$ ${barSpot.y.toStringAsFixed(0)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getRevenueSpots() {
    // Mock data: Receitas mensais
    final revenues = [
      1800.0,
      2400.0,
      4200.0,
      3600.0,
      3200.0,
      2800.0,
      3400.0,
      3800.0,
      3000.0,
      3600.0,
      4000.0,
      3400.0,
    ];
    return List.generate(
      revenues.length,
      (index) => FlSpot(index.toDouble(), revenues[index]),
    );
  }

  List<FlSpot> _getPendingSpots() {
    // Mock data: Pendentes mensais
    final pending = [
      400.0,
      600.0,
      800.0,
      400.0,
      600.0,
      400.0,
      600.0,
      800.0,
      400.0,
      600.0,
      800.0,
      600.0,
    ];
    return List.generate(
      pending.length,
      (index) => FlSpot(index.toDouble(), pending[index]),
    );
  }

  List<FlSpot> _getOverdueSpots() {
    // Mock data: Atrasados mensais
    final overdue = [
      200.0,
      200.0,
      400.0,
      200.0,
      400.0,
      200.0,
      400.0,
      200.0,
      200.0,
      400.0,
      400.0,
      200.0,
    ];
    return List.generate(
      overdue.length,
      (index) => FlSpot(index.toDouble(), overdue[index]),
    );
  }

  String _getMonthLabel(int monthIndex) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return monthIndex >= 0 && monthIndex < months.length
        ? months[monthIndex]
        : '';
  }
}
