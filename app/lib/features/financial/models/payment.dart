import 'package:equatable/equatable.dart';

/// Status do pagamento
enum PaymentStatus {
  pending, // Pendente
  paid, // Pago
  overdue, // Atrasado
  cancelled, // Cancelado
  refunded, // Reembolsado
}

/// Método de pagamento
enum PaymentMethod {
  cash, // Dinheiro
  creditCard, // Cartão de Crédito
  debitCard, // Cartão de Débito
  pix, // PIX
  bankTransfer, // Transferência Bancária
  healthInsurance, // Convênio
  other, // Outro
}

/// Modelo de Pagamento
class Payment extends Equatable {
  final String id;
  final String therapistId;
  final String patientId;
  final String? sessionId; // Vinculado a uma sessão
  final double amount;
  final PaymentStatus status;
  final PaymentMethod? method;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? notes;
  final String? receiptNumber;
  final String? invoiceId; // Link para fatura
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payment({
    required this.id,
    required this.therapistId,
    required this.patientId,
    this.sessionId,
    required this.amount,
    required this.status,
    this.method,
    required this.dueDate,
    this.paidAt,
    this.notes,
    this.receiptNumber,
    this.invoiceId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    therapistId,
    patientId,
    sessionId,
    amount,
    status,
    method,
    dueDate,
    paidAt,
    notes,
    receiptNumber,
    invoiceId,
    createdAt,
    updatedAt,
  ];

  /// Verifica se está atrasado
  bool get isOverdue {
    if (status == PaymentStatus.paid || status == PaymentStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(dueDate);
  }

  /// Dias de atraso
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  /// Verifica se pode ser editado
  bool get canBeEdited {
    return status == PaymentStatus.pending || status == PaymentStatus.overdue;
  }

  /// Verifica se pode ser cancelado
  bool get canBeCancelled {
    return status == PaymentStatus.pending || status == PaymentStatus.overdue;
  }

  Payment copyWith({
    String? id,
    String? therapistId,
    String? patientId,
    String? sessionId,
    double? amount,
    PaymentStatus? status,
    PaymentMethod? method,
    DateTime? dueDate,
    DateTime? paidAt,
    String? notes,
    String? receiptNumber,
    String? invoiceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      patientId: patientId ?? this.patientId,
      sessionId: sessionId ?? this.sessionId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      method: method ?? this.method,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      invoiceId: invoiceId ?? this.invoiceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'therapistId': therapistId,
      'patientId': patientId,
      'sessionId': sessionId,
      'amount': amount,
      'status': status.name,
      'method': method?.name,
      'dueDate': dueDate.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'notes': notes,
      'receiptNumber': receiptNumber,
      'invoiceId': invoiceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      therapistId: json['therapistId'] as String,
      patientId: json['patientId'] as String,
      sessionId: json['sessionId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      status: PaymentStatus.values.firstWhere((e) => e.name == json['status']),
      method: json['method'] != null
          ? PaymentMethod.values.firstWhere((e) => e.name == json['method'])
          : null,
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      notes: json['notes'] as String?,
      receiptNumber: json['receiptNumber'] as String?,
      invoiceId: json['invoiceId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Resumo financeiro
class FinancialSummary extends Equatable {
  final double totalReceived;
  final double totalPending;
  final double totalOverdue;
  final int sessionsCompleted;
  final int sessionsPending;
  final DateTime startDate;
  final DateTime endDate;

  const FinancialSummary({
    required this.totalReceived,
    required this.totalPending,
    required this.totalOverdue,
    required this.sessionsCompleted,
    required this.sessionsPending,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [
    totalReceived,
    totalPending,
    totalOverdue,
    sessionsCompleted,
    sessionsPending,
    startDate,
    endDate,
  ];

  double get total => totalReceived + totalPending + totalOverdue;
}
