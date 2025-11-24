import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:terafy/common/app_colors.dart';

class PaymentStatusChart extends StatefulWidget {
  final dynamic summary;

  const PaymentStatusChart({super.key, required this.summary});

  @override
  State<PaymentStatusChart> createState() => _PaymentStatusChartState();
}

class _PaymentStatusChartState extends State<PaymentStatusChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total =
        widget.summary.totalReceived +
        widget.summary.totalPending +
        widget.summary.totalOverdue;

    if (total == 0) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorderColor),
        ),
        child: const Center(
          child: Text(
            'Nenhum pagamento registrado',
            style: TextStyle(color: AppColors.offBlack, fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      child: Row(
        children: [
          // Gráfico de pizza
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _getSections(total),
              ),
            ),
          ),
          // Legenda
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                  'Recebido',
                  Colors.green,
                  widget.summary.totalReceived,
                  total,
                ),
                const SizedBox(height: 12),
                _buildLegendItem(
                  'Pendente',
                  Colors.orange,
                  widget.summary.totalPending,
                  total,
                ),
                const SizedBox(height: 12),
                _buildLegendItem(
                  'Atrasado',
                  Colors.red,
                  widget.summary.totalOverdue,
                  total,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections(double total) {
    final receivedPercent = (widget.summary.totalReceived / total) * 100;
    final pendingPercent = (widget.summary.totalPending / total) * 100;
    final overduePercent = (widget.summary.totalOverdue / total) * 100;

    return [
      PieChartSectionData(
        color: Colors.green,
        value: widget.summary.totalReceived,
        title: '${receivedPercent.toStringAsFixed(0)}%',
        radius: touchedIndex == 0 ? 65 : 55,
        titleStyle: TextStyle(
          fontSize: touchedIndex == 0 ? 16 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: widget.summary.totalPending,
        title: '${pendingPercent.toStringAsFixed(0)}%',
        radius: touchedIndex == 1 ? 65 : 55,
        titleStyle: TextStyle(
          fontSize: touchedIndex == 1 ? 16 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: widget.summary.totalOverdue,
        title: '${overduePercent.toStringAsFixed(0)}%',
        radius: touchedIndex == 2 ? 65 : 55,
        titleStyle: TextStyle(
          fontSize: touchedIndex == 2 ? 16 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    double value,
    double total,
  ) {
    final percentage = (value / total * 100).toStringAsFixed(1);
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.offBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
