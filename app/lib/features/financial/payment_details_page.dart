import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/financial/bloc/financial_bloc.dart';
import 'package:terafy/features/financial/bloc/financial_bloc_models.dart';
import 'package:terafy/features/financial/models/payment.dart';

class PaymentDetailsPage extends StatelessWidget {
  final String paymentId;

  const PaymentDetailsPage({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final container = DependencyContainer();
        return FinancialBloc(
          getTransactionsUseCase: container.getTransactionsUseCase,
          getTransactionUseCase: container.getTransactionUseCase,
          createTransactionUseCase: container.createTransactionUseCase,
          updateTransactionUseCase: container.updateTransactionUseCase,
          deleteTransactionUseCase: container.deleteTransactionUseCase,
          getFinancialSummaryUseCase: container.getFinancialSummaryUseCase,
          getCurrentTherapistUseCase: container.getCurrentTherapistUseCase,
        )..add(LoadPaymentDetails(paymentId));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Detalhes do Pagamento',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: BlocConsumer<FinancialBloc, FinancialState>(
          listener: (context, state) {
            if (state is PaymentMarkedAsPaid) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pagamento marcado como pago!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            } else if (state is PaymentCancelled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pagamento cancelado'),
                  backgroundColor: Colors.orange,
                ),
              );
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            if (state is FinancialLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is FinancialError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              );
            }

            if (state is PaymentDetailsLoaded) {
              return _buildDetails(context, state.payment);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Payment payment) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status Badge e Valor
              _buildHeader(payment, currencyFormat),

              const SizedBox(height: 24),

              // Informações Principais
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'Informações do Pagamento',
                children: [
                  _buildInfoRow('Status', _getStatusLabel(payment.status)),
                  _buildInfoRow('Valor', currencyFormat.format(payment.amount)),
                  _buildInfoRow(
                    'Vencimento',
                    dateFormat.format(payment.dueDate),
                  ),
                  if (payment.isOverdue)
                    _buildInfoRow(
                      'Dias em atraso',
                      '${payment.daysOverdue} dias',
                      valueColor: Colors.red,
                    ),
                  if (payment.paidAt != null)
                    _buildInfoRow(
                      'Pago em',
                      dateFormat.format(payment.paidAt!),
                    ),
                  if (payment.method != null)
                    _buildInfoRow(
                      'Método',
                      _getPaymentMethodLabel(payment.method!),
                    ),
                  if (payment.receiptNumber != null)
                    _buildInfoRow('Nº Recibo', payment.receiptNumber!),
                ],
              ),

              const SizedBox(height: 16),

              // Paciente
              _buildInfoCard(
                icon: Icons.person,
                title: 'Paciente',
                children: [
                  _buildInfoRow('ID', payment.patientId),
                  // TODO: Buscar nome do paciente
                ],
              ),

              const SizedBox(height: 16),

              // Sessão vinculada
              if (payment.sessionId != null)
                _buildInfoCard(
                  icon: Icons.assignment,
                  title: 'Sessão Vinculada',
                  children: [
                    _buildInfoRow('ID da Sessão', payment.sessionId!),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ver detalhes da sessão'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navegar para detalhes da sessão
                      },
                    ),
                  ],
                ),

              if (payment.sessionId != null) const SizedBox(height: 16),

              // Notas
              if (payment.notes != null)
                _buildInfoCard(
                  icon: Icons.notes,
                  title: 'Observações',
                  children: [
                    Text(
                      payment.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.offBlack,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),

        // Ações na parte inferior
        _buildBottomActions(context, payment),
      ],
    );
  }

  Widget _buildHeader(Payment payment, NumberFormat currencyFormat) {
    final colors = _getStatusColors(payment.status);

    return Column(
      children: [
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: colors['background'],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors['border']!, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getStatusIcon(payment.status),
                color: colors['border'],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusLabel(payment.status),
                style: TextStyle(
                  color: colors['text'],
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Valor
        Text(
          currencyFormat.format(payment.amount),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.offBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.offBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.offBlack,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, Payment payment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Marcar como pago
            if (payment.status == PaymentStatus.pending ||
                payment.status == PaymentStatus.overdue) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showMarkAsPaidDialog(context, payment);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Marcar como Pago',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Ações secundárias
            if (payment.canBeCancelled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showCancelDialog(context, payment);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancelar Pagamento'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMarkAsPaidDialog(BuildContext context, Payment payment) {
    PaymentMethod? selectedMethod = PaymentMethod.pix;
    DateTime selectedDate = DateTime.now();
    final receiptController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Marcar como Pago'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Método de Pagamento'),
                const SizedBox(height: 8),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(_getPaymentMethodLabel(method)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedMethod = value);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Data do Pagamento'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: payment.dueDate.subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lightBorderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: receiptController,
                  decoration: const InputDecoration(
                    labelText: 'Nº do Recibo (opcional)',
                    hintText: 'Ex: REC-001',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedMethod == null
                  ? null
                  : () {
                      context.read<FinancialBloc>().add(
                        MarkPaymentAsPaid(
                          paymentId: payment.id,
                          method: selectedMethod!,
                          paidAt: selectedDate,
                          receiptNumber: receiptController.text.trim().isEmpty
                              ? null
                              : receiptController.text.trim(),
                        ),
                      );
                      Navigator.of(dialogContext).pop();
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Payment payment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tem certeza que deseja cancelar este pagamento?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ex: Paciente desistiu do tratamento',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<FinancialBloc>().add(
                CancelPayment(
                  paymentId: payment.id,
                  reason: reasonController.text.trim().isEmpty
                      ? null
                      : reasonController.text.trim(),
                ),
              );
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Cancelar Pagamento',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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

  Map<String, Color> _getStatusColors(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return {
          'background': Colors.orange.withOpacity(0.1),
          'border': Colors.orange,
          'text': Colors.orange.shade700,
        };
      case PaymentStatus.paid:
        return {
          'background': Colors.green.withOpacity(0.1),
          'border': Colors.green,
          'text': Colors.green.shade700,
        };
      case PaymentStatus.overdue:
        return {
          'background': Colors.red.withOpacity(0.1),
          'border': Colors.red,
          'text': Colors.red.shade700,
        };
      case PaymentStatus.cancelled:
        return {
          'background': Colors.grey.withOpacity(0.1),
          'border': Colors.grey,
          'text': Colors.grey.shade700,
        };
      case PaymentStatus.refunded:
        return {
          'background': Colors.blue.withOpacity(0.1),
          'border': Colors.blue,
          'text': Colors.blue.shade700,
        };
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
}
