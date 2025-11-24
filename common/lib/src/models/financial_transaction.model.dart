class FinancialTransaction {
  final int? id;
  final int therapistId;
  final int patientId;
  final int? sessionId;
  final DateTime transactionDate;
  final String type; // transaction_type enum
  final double amount;
  final String paymentMethod; // financial_payment_method enum
  final String status; // transaction_status enum
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? receiptNumber;
  final String category; // transaction_category enum
  final String? notes;
  final String? invoiceNumber;
  final bool invoiceIssued;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FinancialTransaction({
    this.id,
    required this.therapistId,
    required this.patientId,
    this.sessionId,
    required this.transactionDate,
    required this.type,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.dueDate,
    this.paidAt,
    this.receiptNumber,
    required this.category,
    this.notes,
    this.invoiceNumber,
    this.invoiceIssued = false,
    this.createdAt,
    this.updatedAt,
  });

  FinancialTransaction copyWith({
    int? id,
    int? therapistId,
    int? patientId,
    int? sessionId,
    DateTime? transactionDate,
    String? type,
    double? amount,
    String? paymentMethod,
    String? status,
    DateTime? dueDate,
    DateTime? paidAt,
    String? receiptNumber,
    String? category,
    String? notes,
    String? invoiceNumber,
    bool? invoiceIssued,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      patientId: patientId ?? this.patientId,
      sessionId: sessionId ?? this.sessionId,
      transactionDate: transactionDate ?? this.transactionDate,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceIssued: invoiceIssued ?? this.invoiceIssued,
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
      'transactionDate': transactionDate.toIso8601String(),
      'type': type,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'dueDate': dueDate?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'receiptNumber': receiptNumber,
      'category': category,
      'notes': notes,
      'invoiceNumber': invoiceNumber,
      'invoiceIssued': invoiceIssued,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] as int?,
      therapistId: json['therapistId'] as int,
      patientId: json['patientId'] as int,
      sessionId: json['sessionId'] as int?,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      status: json['status'] as String,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      receiptNumber: json['receiptNumber'] as String?,
      category: json['category'] as String,
      notes: json['notes'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      invoiceIssued: json['invoiceIssued'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'therapist_id': therapistId,
      'patient_id': patientId,
      if (sessionId != null) 'session_id': sessionId,
      'transaction_date': transactionDate.toIso8601String(),
      'type': type,
      'amount': amount,
      'payment_method': paymentMethod,
      'status': status,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      'category': category,
      if (notes != null) 'notes': notes,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      'invoice_issued': invoiceIssued,
    };
  }

  factory FinancialTransaction.fromMap(Map<String, dynamic> map) {
    return FinancialTransaction(
      id: map['id'] as int?,
      therapistId: map['therapist_id'] as int,
      patientId: map['patient_id'] as int,
      sessionId: map['session_id'] as int?,
      transactionDate: (map['transaction_date'] as DateTime)
          .toLocal(), // PostgreSQL retorna TIMESTAMP WITH TIME ZONE
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      status: map['status'] as String,
      dueDate: map['due_date'] != null
          ? (map['due_date'] as DateTime).toLocal()
          : null,
      paidAt: map['paid_at'] != null
          ? (map['paid_at'] as DateTime).toLocal()
          : null,
      receiptNumber: map['receipt_number'] as String?,
      category: map['category'] as String,
      notes: map['notes'] as String?,
      invoiceNumber: map['invoice_number'] as String?,
      invoiceIssued: (map['invoice_issued'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? (map['created_at'] as DateTime).toLocal()
          : null,
      updatedAt: map['updated_at'] != null
          ? (map['updated_at'] as DateTime).toLocal()
          : null,
    );
  }
}

