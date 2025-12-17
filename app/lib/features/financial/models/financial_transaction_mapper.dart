import 'package:common/common.dart';
import 'package:terafy/features/financial/models/payment.dart';

class FinancialTransactionMapper {
  /// Converte FinancialTransaction (backend) para Payment (frontend)
  static Payment mapToPayment(FinancialTransaction transaction) {
    return Payment(
      id: transaction.id?.toString() ?? '',
      therapistId: transaction.therapistId.toString(),
      patientId: transaction.patientId.toString(),
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
      transactionDate: payment.dueDate,
      type: 'income', // Default, pode ser ajustado
      amount: payment.amount,
      paymentMethod: mapPaymentMethodToString(payment.method),
      status: _mapStatusToString(payment.status),
      dueDate: payment.dueDate,
      paidAt: payment.paidAt,
      receiptNumber: payment.receiptNumber,
      category: 'session', // Default
      notes: payment.notes,
      invoiceNumber: payment.invoiceId,
      invoiceIssued: payment.invoiceId != null,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
    );
  }

  static PaymentStatus _mapStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return PaymentStatus.pending;
      case 'paid':
        return PaymentStatus.paid;
      case 'overdue':
        return PaymentStatus.overdue;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  static String _mapStatusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.overdue:
        return 'overdue';
      case PaymentStatus.cancelled:
        return 'cancelled';
      case PaymentStatus.refunded:
        return 'cancelled'; // Mapear refunded para cancelado no backend
    }
  }

  static PaymentMethod? _mapPaymentMethodFromString(String? method) {
    if (method == null) return null;
    switch (method) {
      case 'cash':
        return PaymentMethod.cash;
      case 'pix':
        return PaymentMethod.pix;
      case 'debit_card':
        return PaymentMethod.debitCard;
      case 'credit_card':
        return PaymentMethod.creditCard;
      case 'transfer':
        return PaymentMethod.bankTransfer;
      case 'insurance':
        return PaymentMethod.healthInsurance;
      default:
        return PaymentMethod.other;
    }
  }

  static String mapPaymentMethodToString(PaymentMethod? method) {
    if (method == null) return 'pix'; // Default
    switch (method) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.pix:
        return 'pix';
      case PaymentMethod.debitCard:
        return 'debit_card';
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.bankTransfer:
        return 'transfer';
      case PaymentMethod.healthInsurance:
        return 'insurance';
      case PaymentMethod.other:
        return 'others'; // Default para other
    }
  }
}
