import 'package:equatable/equatable.dart';

/// Status da fatura
enum InvoiceStatus {
  draft, // Rascunho
  issued, // Emitida
  sent, // Enviada
  paid, // Paga
  overdue, // Vencida
  cancelled, // Cancelada
}

/// Item da fatura
class InvoiceItem extends Equatable {
  final String description;
  final int quantity;
  final double unitPrice;
  final double discount;

  const InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
  });

  double get subtotal => quantity * unitPrice;
  double get total => subtotal - discount;

  @override
  List<Object> get props => [description, quantity, unitPrice, discount];

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discount': discount,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Modelo de Fatura
class Invoice extends Equatable {
  final String id;
  final String therapistId;
  final String patientId;
  final String invoiceNumber;
  final InvoiceStatus status;
  final List<InvoiceItem> items;
  final double discount;
  final double tax;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? notes;
  final String? paymentInstructions;
  final List<String> paymentIds; // Pagamentos vinculados
  final DateTime createdAt;
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    required this.therapistId,
    required this.patientId,
    required this.invoiceNumber,
    required this.status,
    required this.items,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.issueDate,
    required this.dueDate,
    this.paidAt,
    this.notes,
    this.paymentInstructions,
    this.paymentIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    therapistId,
    patientId,
    invoiceNumber,
    status,
    items,
    discount,
    tax,
    issueDate,
    dueDate,
    paidAt,
    notes,
    paymentInstructions,
    paymentIds,
    createdAt,
    updatedAt,
  ];

  /// Subtotal dos itens
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Total com desconto e impostos
  double get total => subtotal - discount + tax;

  /// Verifica se está vencida
  bool get isOverdue {
    if (status == InvoiceStatus.paid || status == InvoiceStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(dueDate);
  }

  /// Dias de atraso
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  /// Verifica se pode ser editada
  bool get canBeEdited {
    return status == InvoiceStatus.draft;
  }

  /// Verifica se pode ser cancelada
  bool get canBeCancelled {
    return status != InvoiceStatus.paid && status != InvoiceStatus.cancelled;
  }

  Invoice copyWith({
    String? id,
    String? therapistId,
    String? patientId,
    String? invoiceNumber,
    InvoiceStatus? status,
    List<InvoiceItem>? items,
    double? discount,
    double? tax,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? paidAt,
    String? notes,
    String? paymentInstructions,
    List<String>? paymentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      patientId: patientId ?? this.patientId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      status: status ?? this.status,
      items: items ?? this.items,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      paymentIds: paymentIds ?? this.paymentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'therapistId': therapistId,
      'patientId': patientId,
      'invoiceNumber': invoiceNumber,
      'status': status.name,
      'items': items.map((item) => item.toJson()).toList(),
      'discount': discount,
      'tax': tax,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'notes': notes,
      'paymentInstructions': paymentInstructions,
      'paymentIds': paymentIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      therapistId: json['therapistId'] as String,
      patientId: json['patientId'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      status: InvoiceStatus.values.firstWhere((e) => e.name == json['status']),
      items: (json['items'] as List)
          .map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      notes: json['notes'] as String?,
      paymentInstructions: json['paymentInstructions'] as String?,
      paymentIds: (json['paymentIds'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
