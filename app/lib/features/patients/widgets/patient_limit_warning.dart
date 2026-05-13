import 'package:flutter/material.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/routes/app_routes.dart';

class PatientLimitWarning extends StatelessWidget {
  final int patientCount;
  final int patientLimit;
  final int usagePercentage;
  final bool isAtLimit;

  const PatientLimitWarning({
    super.key,
    required this.patientCount,
    required this.patientLimit,
    required this.usagePercentage,
    required this.isAtLimit,
  });

  @override
  Widget build(BuildContext context) {
    if (usagePercentage < 80) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAtLimit ? Colors.red[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAtLimit ? Colors.red[300]! : Colors.orange[300]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isAtLimit ? Icons.error : Icons.warning, color: isAtLimit ? Colors.red : Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAtLimit ? 'Limite de pacientes atingido!' : 'Você está próximo do limite',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAtLimit ? Colors.red[900] : Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAtLimit
                ? 'Você possui $patientCount de $patientLimit pacientes permitidos no seu plano atual. Faça upgrade para adicionar mais pacientes.'
                : 'Você possui $patientCount de $patientLimit pacientes (${usagePercentage}% do limite). Considere fazer upgrade antes de atingir o limite.',
            style: TextStyle(fontSize: 14, color: isAtLimit ? Colors.red[800] : Colors.orange[800]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.subscriptionRoute);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAtLimit ? Colors.red : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ver Planos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
