import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/domain/usecases/financial/create_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/delete_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/get_financial_summary_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/get_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/get_transactions_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/update_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/therapist/get_current_therapist_usecase.dart';
import 'package:terafy/features/financial/bloc/financial_bloc_models.dart';
import 'package:terafy/features/financial/models/financial_transaction_mapper.dart';
import 'package:terafy/features/financial/models/payment.dart';
import 'package:terafy/features/financial/models/invoice.dart';

class FinancialBloc extends Bloc<FinancialEvent, FinancialState> {
  final GetTransactionsUseCase _getTransactionsUseCase;
  final GetTransactionUseCase _getTransactionUseCase;
  final CreateTransactionUseCase _createTransactionUseCase;
  final UpdateTransactionUseCase _updateTransactionUseCase;
  final DeleteTransactionUseCase _deleteTransactionUseCase;
  final GetFinancialSummaryUseCase _getFinancialSummaryUseCase;
  final GetCurrentTherapistUseCase _getCurrentTherapistUseCase;

  // Mock data apenas para invoices (não implementado no backend ainda)
  final List<Invoice> _mockInvoices = [];

  FinancialBloc({
    required GetTransactionsUseCase getTransactionsUseCase,
    required GetTransactionUseCase getTransactionUseCase,
    required CreateTransactionUseCase createTransactionUseCase,
    required UpdateTransactionUseCase updateTransactionUseCase,
    required DeleteTransactionUseCase deleteTransactionUseCase,
    required GetFinancialSummaryUseCase getFinancialSummaryUseCase,
    required GetCurrentTherapistUseCase getCurrentTherapistUseCase,
  }) : _getTransactionsUseCase = getTransactionsUseCase,
       _getTransactionUseCase = getTransactionUseCase,
       _createTransactionUseCase = createTransactionUseCase,
       _updateTransactionUseCase = updateTransactionUseCase,
       _deleteTransactionUseCase = deleteTransactionUseCase,
       _getFinancialSummaryUseCase = getFinancialSummaryUseCase,
       _getCurrentTherapistUseCase = getCurrentTherapistUseCase,
       super(const FinancialInitial()) {
    on<LoadFinancialSummary>(_onLoadFinancialSummary);
    on<LoadPayments>(_onLoadPayments);
    on<LoadPaymentDetails>(_onLoadPaymentDetails);
    on<CreatePayment>(_onCreatePayment);
    on<UpdatePayment>(_onUpdatePayment);
    on<MarkPaymentAsPaid>(_onMarkPaymentAsPaid);
    on<CancelPayment>(_onCancelPayment);
    on<LoadInvoices>(_onLoadInvoices);
    on<CreateInvoice>(_onCreateInvoice);
    on<IssueInvoice>(_onIssueInvoice);
  }

  Future<int> _getCurrentTherapistId() async {
    try {
      final therapistData = await _getCurrentTherapistUseCase();
      return therapistData['id'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _onLoadFinancialSummary(LoadFinancialSummary event, Emitter<FinancialState> emit) async {
    emit(const FinancialLoading());

    try {
      final therapistId = await _getCurrentTherapistId();
      if (therapistId == 0) {
        emit(const FinancialError('Terapeuta não encontrado'));
        return;
      }

      final summaryData = await _getFinancialSummaryUseCase(
        therapistId: therapistId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      final summary = FinancialSummary(
        totalReceived: (summaryData['totalPaidAmount'] as num?)?.toDouble() ?? 0.0,
        totalPending: (summaryData['totalPendingAmount'] as num?)?.toDouble() ?? 0.0,
        totalOverdue: (summaryData['totalOverdueAmount'] as num?)?.toDouble() ?? 0.0,
        sessionsCompleted: summaryData['totalPaidCount'] as int? ?? 0,
        sessionsPending:
            (summaryData['totalPendingCount'] as int? ?? 0) + (summaryData['totalOverdueCount'] as int? ?? 0),
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(FinancialSummaryLoaded(summary: summary, startDate: event.startDate, endDate: event.endDate));
    } catch (e) {
      emit(FinancialError('Erro ao carregar resumo: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPayments(LoadPayments event, Emitter<FinancialState> emit) async {
    emit(const FinancialLoading());

    try {
      final therapistId = await _getCurrentTherapistId();
      if (therapistId == 0) {
        emit(const FinancialError('Terapeuta não encontrado'));
        return;
      }

      String? statusFilter;
      if (event.statusFilter != null) {
        switch (event.statusFilter!) {
          case PaymentStatus.pending:
            statusFilter = 'pendente';
            break;
          case PaymentStatus.paid:
            statusFilter = 'pago';
            break;
          case PaymentStatus.overdue:
            statusFilter = 'atrasado';
            break;
          case PaymentStatus.cancelled:
            statusFilter = 'cancelado';
            break;
          case PaymentStatus.refunded:
            statusFilter = 'cancelado'; // Mapear refunded para cancelado
            break;
        }
      }

      int? patientIdFilter;
      if (event.patientIdFilter != null) {
        patientIdFilter = int.tryParse(event.patientIdFilter!);
      }

      final transactions = await _getTransactionsUseCase(
        therapistId: therapistId,
        patientId: patientIdFilter,
        status: statusFilter,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      final payments = transactions.map((t) => FinancialTransactionMapper.mapToPayment(t)).toList();

      // Ordenar por data de vencimento (mais recentes primeiro)
      payments.sort((a, b) => b.dueDate.compareTo(a.dueDate));

      emit(
        PaymentsLoaded(
          payments: payments,
          startDate: event.startDate,
          endDate: event.endDate,
          statusFilter: event.statusFilter,
        ),
      );
    } catch (e) {
      emit(FinancialError('Erro ao carregar pagamentos: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPaymentDetails(LoadPaymentDetails event, Emitter<FinancialState> emit) async {
    emit(const FinancialLoading());

    try {
      final transactionId = int.tryParse(event.paymentId);
      if (transactionId == null) {
        emit(const FinancialError('ID de pagamento inválido'));
        return;
      }

      final transaction = await _getTransactionUseCase(transactionId);
      if (transaction == null) {
        emit(const FinancialError('Pagamento não encontrado'));
        return;
      }

      final payment = FinancialTransactionMapper.mapToPayment(transaction);
      emit(PaymentDetailsLoaded(payment));
    } catch (e) {
      emit(FinancialError('Erro ao carregar detalhes: ${e.toString()}'));
    }
  }

  Future<void> _onCreatePayment(CreatePayment event, Emitter<FinancialState> emit) async {
    try {
      final transaction = FinancialTransactionMapper.mapToFinancialTransaction(event.payment);
      final created = await _createTransactionUseCase(transaction);
      final payment = FinancialTransactionMapper.mapToPayment(created);

      emit(PaymentCreated(payment));

      // Recarregar lista
      add(const LoadPayments());
    } catch (e) {
      emit(FinancialError('Erro ao criar pagamento: ${e.toString()}'));
    }
  }

  Future<void> _onUpdatePayment(UpdatePayment event, Emitter<FinancialState> emit) async {
    try {
      final transactionId = int.tryParse(event.payment.id);
      if (transactionId == null) {
        emit(const FinancialError('ID de pagamento inválido'));
        return;
      }

      final transaction = FinancialTransactionMapper.mapToFinancialTransaction(event.payment);
      final updated = await _updateTransactionUseCase(transactionId, transaction);
      final payment = FinancialTransactionMapper.mapToPayment(updated);

      emit(PaymentUpdated(payment));

      // Recarregar lista
      add(const LoadPayments());
    } catch (e) {
      emit(FinancialError('Erro ao atualizar pagamento: ${e.toString()}'));
    }
  }

  Future<void> _onMarkPaymentAsPaid(MarkPaymentAsPaid event, Emitter<FinancialState> emit) async {
    try {
      final transactionId = int.tryParse(event.paymentId);
      if (transactionId == null) {
        emit(const FinancialError('ID de pagamento inválido'));
        return;
      }

      final currentTransaction = await _getTransactionUseCase(transactionId);
      if (currentTransaction == null) {
        emit(const FinancialError('Pagamento não encontrado'));
        return;
      }

      final updatedTransaction = currentTransaction.copyWith(
        status: 'pago',
        paymentMethod: FinancialTransactionMapper.mapPaymentMethodToString(event.method),
        paidAt: event.paidAt.toUtc(),
        receiptNumber: event.receiptNumber,
        updatedAt: DateTime.now().toUtc(),
      );

      final updated = await _updateTransactionUseCase(transactionId, updatedTransaction);
      final payment = FinancialTransactionMapper.mapToPayment(updated);

      emit(PaymentMarkedAsPaid(payment));

      // Recarregar lista
      add(const LoadPayments());
    } catch (e) {
      emit(FinancialError('Erro ao marcar como pago: ${e.toString()}'));
    }
  }

  Future<void> _onCancelPayment(CancelPayment event, Emitter<FinancialState> emit) async {
    try {
      final transactionId = int.tryParse(event.paymentId);
      if (transactionId == null) {
        emit(const FinancialError('ID de pagamento inválido'));
        return;
      }

      final currentTransaction = await _getTransactionUseCase(transactionId);
      if (currentTransaction == null) {
        emit(const FinancialError('Pagamento não encontrado'));
        return;
      }

      final updatedTransaction = currentTransaction.copyWith(
        status: 'cancelado',
        notes: event.reason != null
            ? '${currentTransaction.notes ?? ''}\nMotivo: ${event.reason}'
            : currentTransaction.notes,
        updatedAt: DateTime.now().toUtc(),
      );

      await _updateTransactionUseCase(transactionId, updatedTransaction);

      emit(PaymentCancelled(event.paymentId));

      // Recarregar lista
      add(const LoadPayments());
    } catch (e) {
      emit(FinancialError('Erro ao cancelar pagamento: ${e.toString()}'));
    }
  }

  Future<void> _onLoadInvoices(LoadInvoices event, Emitter<FinancialState> emit) async {
    emit(const FinancialLoading());

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      var filteredInvoices = _mockInvoices;

      // Filtrar por data
      if (event.startDate != null && event.endDate != null) {
        filteredInvoices = filteredInvoices.where((invoice) {
          return invoice.issueDate.isAfter(event.startDate!) && invoice.issueDate.isBefore(event.endDate!);
        }).toList();
      }

      // Filtrar por status
      if (event.statusFilter != null) {
        filteredInvoices = filteredInvoices.where((invoice) => invoice.status == event.statusFilter).toList();
      }

      emit(InvoicesLoaded(invoices: filteredInvoices, startDate: event.startDate, endDate: event.endDate));
    } catch (e) {
      emit(FinancialError('Erro ao carregar faturas: ${e.toString()}'));
    }
  }

  Future<void> _onCreateInvoice(CreateInvoice event, Emitter<FinancialState> emit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      _mockInvoices.add(event.invoice);

      emit(InvoiceCreated(event.invoice));

      // Recarregar lista
      add(const LoadInvoices());
    } catch (e) {
      emit(FinancialError('Erro ao criar fatura: ${e.toString()}'));
    }
  }

  Future<void> _onIssueInvoice(IssueInvoice event, Emitter<FinancialState> emit) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final index = _mockInvoices.indexWhere((i) => i.id == event.invoiceId);
      if (index != -1) {
        _mockInvoices[index] = _mockInvoices[index].copyWith(status: InvoiceStatus.issued, updatedAt: DateTime.now());

        emit(InvoiceIssued(_mockInvoices[index]));

        // Recarregar lista
        add(const LoadInvoices());
      } else {
        emit(const FinancialError('Fatura não encontrada'));
      }
    } catch (e) {
      emit(FinancialError('Erro ao emitir fatura: ${e.toString()}'));
    }
  }
}
