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
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      receiptNumber: json['receiptNumber'] as String?,
      category: json['category'] as String,
      notes: json['notes'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      invoiceIssued: json['invoiceIssued'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
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
      id: _parseInt(map['id']),
      therapistId: _parseInt(map['therapist_id']) ?? 0,
      patientId: _parseInt(map['patient_id']) ?? 0,
      sessionId: _parseInt(map['session_id']),
      transactionDate: _parseDate(map['transaction_date']) ?? DateTime.now(),
      type: _parseString(map['type']) ?? 'recebimento',
      amount: _parseDouble(map['amount']) ?? 0.0,
      paymentMethod: _parseString(map['payment_method']) ?? 'dinheiro',
      status: _parseString(map['status']) ?? 'pendente',
      dueDate: _parseDate(map['due_date']),
      paidAt: _parseDate(map['paid_at']),
      receiptNumber: _parseString(map['receipt_number']),
      category: _parseString(map['category']) ?? 'sessao',
      notes: _parseString(map['notes']),
      invoiceNumber: _parseString(map['invoice_number']),
      invoiceIssued: _parseBool(map['invoice_issued']) ?? false,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    final str = value.toString();
    final parsed = DateTime.tryParse(str);
    return parsed?.toLocal();
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    // PostgreSQL ENUMs podem vir como UndecodedBytes
    return value.toString();
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    // PostgreSQL NUMERIC pode vir como String ou tipo especial
    return double.tryParse(value.toString());
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    final str = value.toString().toLowerCase();
    return str == 'true' || str == '1' || str == 't';
  }
}
