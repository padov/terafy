import 'package:common/common.dart';
import 'package:terafy/features/financial/models/payment.dart';

class FinancialTransactionMapper {
  /// Converte FinancialTransaction (backend) para Payment (frontend)
  static Payment mapToPayment(FinancialTransaction transaction) {
    return Payment(
      id: transaction.id?.toString() ?? '',
      therapistId: transaction.therapistId.toString(),
      patientId: transaction.patientId.toString(),
      sessionId: transaction.sessionId?.toString(),
      amount: transaction.amount,
      status: _mapStatusFromString(transaction.status),
      method: _mapPaymentMethodFromString(transaction.paymentMethod),
      dueDate: transaction.dueDate ?? transaction.transactionDate,
      paidAt: transaction.paidAt,
      notes: transaction.notes,
      receiptNumber: transaction.receiptNumber,
      invoiceId: transaction.invoiceNumber,
      createdAt: transaction.createdAt ?? DateTime.now(),
      updatedAt: transaction.updatedAt ?? DateTime.now(),
    );
  }

  /// Converte Payment (frontend) para FinancialTransaction (backend)
  static FinancialTransaction mapToFinancialTransaction(Payment payment) {
    return FinancialTransaction(
      id: int.tryParse(payment.id),
      therapistId: int.tryParse(payment.therapistId) ?? 0,
      patientId: int.tryParse(payment.patientId) ?? 0,
      sessionId: payment.sessionId != null
          ? int.tryParse(payment.sessionId!)
          : null,
      transactionDate: payment.dueDate,
      type: 'recebimento', // Default, pode ser ajustado
      amount: payment.amount,
      paymentMethod: mapPaymentMethodToString(payment.method),
      status: _mapStatusToString(payment.status),
      dueDate: payment.dueDate,
      paidAt: payment.paidAt,
      receiptNumber: payment.receiptNumber,
      category: 'sessao', // Default
      notes: payment.notes,
      invoiceNumber: payment.invoiceId,
      invoiceIssued: payment.invoiceId != null,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
    );
  }

  static PaymentStatus _mapStatusFromString(String status) {
    switch (status) {
      case 'pendente':
        return PaymentStatus.pending;
      case 'pago':
        return PaymentStatus.paid;
      case 'atrasado':
        return PaymentStatus.overdue;
      case 'cancelado':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  static String _mapStatusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'pendente';
      case PaymentStatus.paid:
        return 'pago';
      case PaymentStatus.overdue:
        return 'atrasado';
      case PaymentStatus.cancelled:
        return 'cancelado';
      case PaymentStatus.refunded:
        return 'cancelado'; // Mapear refunded para cancelado no backend
    }
  }

  static PaymentMethod? _mapPaymentMethodFromString(String? method) {
    if (method == null) return null;
    switch (method) {
      case 'dinheiro':
        return PaymentMethod.cash;
      case 'pix':
        return PaymentMethod.pix;
      case 'cartao_debito':
        return PaymentMethod.debitCard;
      case 'cartao_credito':
        return PaymentMethod.creditCard;
      case 'transferencia':
        return PaymentMethod.bankTransfer;
      case 'convenio':
        return PaymentMethod.healthInsurance;
      default:
        return PaymentMethod.other;
    }
  }

  static String mapPaymentMethodToString(PaymentMethod? method) {
    if (method == null) return 'pix'; // Default
    switch (method) {
      case PaymentMethod.cash:
        return 'dinheiro';
      case PaymentMethod.pix:
        return 'pix';
      case PaymentMethod.debitCard:
        return 'cartao_debito';
      case PaymentMethod.creditCard:
        return 'cartao_credito';
      case PaymentMethod.bankTransfer:
        return 'transferencia';
      case PaymentMethod.healthInsurance:
        return 'convenio';
      case PaymentMethod.other:
        return 'pix'; // Default para other
    }
  }
}
