import 'package:equatable/equatable.dart';
import 'package:terafy/features/financial/models/payment.dart';
import 'package:terafy/features/financial/models/invoice.dart';

// ==================== EVENTS ====================

abstract class FinancialEvent extends Equatable {
  const FinancialEvent();

  @override
  List<Object?> get props => [];
}

/// Carregar resumo financeiro
class LoadFinancialSummary extends FinancialEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadFinancialSummary({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}

/// Carregar pagamentos
class LoadPayments extends FinancialEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final PaymentStatus? statusFilter;
  final String? patientIdFilter;

  const LoadPayments({
    this.startDate,
    this.endDate,
    this.statusFilter,
    this.patientIdFilter,
  });

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    statusFilter,
    patientIdFilter,
  ];
}

/// Carregar detalhes de um pagamento
class LoadPaymentDetails extends FinancialEvent {
  final String paymentId;

  const LoadPaymentDetails(this.paymentId);

  @override
  List<Object> get props => [paymentId];
}

/// Criar pagamento
class CreatePayment extends FinancialEvent {
  final Payment payment;

  const CreatePayment(this.payment);

  @override
  List<Object> get props => [payment];
}

/// Atualizar pagamento
class UpdatePayment extends FinancialEvent {
  final Payment payment;

  const UpdatePayment(this.payment);

  @override
  List<Object> get props => [payment];
}

/// Marcar pagamento como pago
class MarkPaymentAsPaid extends FinancialEvent {
  final String paymentId;
  final PaymentMethod method;
  final DateTime paidAt;
  final String? receiptNumber;

  const MarkPaymentAsPaid({
    required this.paymentId,
    required this.method,
    required this.paidAt,
    this.receiptNumber,
  });

  @override
  List<Object?> get props => [paymentId, method, paidAt, receiptNumber];
}

/// Cancelar pagamento
class CancelPayment extends FinancialEvent {
  final String paymentId;
  final String? reason;

  const CancelPayment({required this.paymentId, this.reason});

  @override
  List<Object?> get props => [paymentId, reason];
}

/// Carregar faturas
class LoadInvoices extends FinancialEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final InvoiceStatus? statusFilter;

  const LoadInvoices({this.startDate, this.endDate, this.statusFilter});

  @override
  List<Object?> get props => [startDate, endDate, statusFilter];
}

/// Criar fatura
class CreateInvoice extends FinancialEvent {
  final Invoice invoice;

  const CreateInvoice(this.invoice);

  @override
  List<Object> get props => [invoice];
}

/// Emitir fatura
class IssueInvoice extends FinancialEvent {
  final String invoiceId;

  const IssueInvoice(this.invoiceId);

  @override
  List<Object> get props => [invoiceId];
}

// ==================== STATES ====================

abstract class FinancialState extends Equatable {
  const FinancialState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class FinancialInitial extends FinancialState {
  const FinancialInitial();
}

/// Carregando
class FinancialLoading extends FinancialState {
  const FinancialLoading();
}

/// Resumo financeiro carregado
class FinancialSummaryLoaded extends FinancialState {
  final FinancialSummary summary;
  final DateTime startDate;
  final DateTime endDate;

  const FinancialSummaryLoaded({
    required this.summary,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [summary, startDate, endDate];
}

/// Pagamentos carregados
class PaymentsLoaded extends FinancialState {
  final List<Payment> payments;
  final DateTime? startDate;
  final DateTime? endDate;
  final PaymentStatus? statusFilter;

  const PaymentsLoaded({
    required this.payments,
    this.startDate,
    this.endDate,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [payments, startDate, endDate, statusFilter];

  /// Pagamentos por status
  List<Payment> getPaymentsByStatus(PaymentStatus status) {
    return payments.where((p) => p.status == status).toList();
  }

  /// Total por status
  double getTotalByStatus(PaymentStatus status) {
    return payments
        .where((p) => p.status == status)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Pagamentos atrasados
  List<Payment> get overduePayments {
    return payments.where((p) => p.isOverdue).toList();
  }
}

/// Detalhes do pagamento carregado
class PaymentDetailsLoaded extends FinancialState {
  final Payment payment;

  const PaymentDetailsLoaded(this.payment);

  @override
  List<Object> get props => [payment];
}

/// Pagamento criado
class PaymentCreated extends FinancialState {
  final Payment payment;

  const PaymentCreated(this.payment);

  @override
  List<Object> get props => [payment];
}

/// Pagamento atualizado
class PaymentUpdated extends FinancialState {
  final Payment payment;

  const PaymentUpdated(this.payment);

  @override
  List<Object> get props => [payment];
}

/// Pagamento marcado como pago
class PaymentMarkedAsPaid extends FinancialState {
  final Payment payment;

  const PaymentMarkedAsPaid(this.payment);

  @override
  List<Object> get props => [payment];
}

/// Pagamento cancelado
class PaymentCancelled extends FinancialState {
  final String paymentId;

  const PaymentCancelled(this.paymentId);

  @override
  List<Object> get props => [paymentId];
}

/// Faturas carregadas
class InvoicesLoaded extends FinancialState {
  final List<Invoice> invoices;
  final DateTime? startDate;
  final DateTime? endDate;

  const InvoicesLoaded({required this.invoices, this.startDate, this.endDate});

  @override
  List<Object?> get props => [invoices, startDate, endDate];
}

/// Fatura criada
class InvoiceCreated extends FinancialState {
  final Invoice invoice;

  const InvoiceCreated(this.invoice);

  @override
  List<Object> get props => [invoice];
}

/// Fatura emitida
class InvoiceIssued extends FinancialState {
  final Invoice invoice;

  const InvoiceIssued(this.invoice);

  @override
  List<Object> get props => [invoice];
}

/// Erro
class FinancialError extends FinancialState {
  final String message;

  const FinancialError(this.message);

  @override
  List<Object> get props => [message];
}
