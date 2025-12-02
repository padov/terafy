import 'package:common/common.dart';
import 'package:server/features/financial/financial.repository.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:postgres/postgres.dart';

// Mock do DBConnection para testes
class MockDBConnection extends DBConnection {
  @override
  Future<Connection> getConnection() async {
    throw UnimplementedError('Use TestFinancialRepository para testes com dados mockados');
  }
}

// Classe auxiliar para testes que simula o comportamento do FinancialRepository
class TestFinancialRepository extends FinancialRepository {
  final List<FinancialTransaction> _transactions = [];
  int _lastId = 0;
  int? _currentUserId;
  bool _bypassRLS = false;

  TestFinancialRepository() : super(MockDBConnection());

  void _setRLSContext({int? userId, String? userRole, int? accountId, bool bypassRLS = false}) {
    _currentUserId = userId;
    _bypassRLS = bypassRLS;
  }

  List<FinancialTransaction> _filterByRLS(List<FinancialTransaction> transactions) {
    if (_bypassRLS) {
      return transactions;
    }
    if (_currentUserId == null) {
      return [];
    }
    return transactions; // Simplificado para testes
  }

  @override
  Future<FinancialTransaction> createTransaction({
    required FinancialTransaction transaction,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    if (transaction.amount <= 0) {
      throw Exception('Valor deve ser maior que zero');
    }

    final now = DateTime.now();
    final newTransaction = FinancialTransaction(
      id: ++_lastId,
      therapistId: transaction.therapistId,
      patientId: transaction.patientId,
      sessionId: transaction.sessionId,
      transactionDate: transaction.transactionDate,
      type: transaction.type,
      amount: transaction.amount,
      paymentMethod: transaction.paymentMethod,
      status: transaction.status,
      dueDate: transaction.dueDate,
      paidAt: transaction.paidAt,
      receiptNumber: transaction.receiptNumber,
      category: transaction.category,
      notes: transaction.notes,
      invoiceNumber: transaction.invoiceNumber,
      invoiceIssued: transaction.invoiceIssued,
      createdAt: now,
      updatedAt: now,
    );
    _transactions.add(newTransaction);
    return newTransaction;
  }

  @override
  Future<FinancialTransaction?> getTransactionById({
    required int transactionId,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);
    try {
      final transaction = _transactions.firstWhere((t) => t.id == transactionId);
      final filtered = _filterByRLS([transaction]);
      return filtered.isEmpty ? null : filtered.first;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<FinancialTransaction>> listTransactions({
    required int userId,
    String? userRole,
    int? accountId,
    int? therapistId,
    int? patientId,
    int? sessionId,
    String? status,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    var filtered = List<FinancialTransaction>.from(_transactions);

    if (therapistId != null) {
      filtered = filtered.where((t) => t.therapistId == therapistId).toList();
    }
    if (patientId != null) {
      filtered = filtered.where((t) => t.patientId == patientId).toList();
    }
    if (sessionId != null) {
      filtered = filtered.where((t) => t.sessionId == sessionId).toList();
    }
    if (status != null) {
      filtered = filtered.where((t) => t.status == status).toList();
    }
    if (category != null) {
      filtered = filtered.where((t) => t.category == category).toList();
    }
    if (startDate != null) {
      filtered = filtered
          .where((t) => t.transactionDate.isAfter(startDate) || t.transactionDate.isAtSameMomentAs(startDate))
          .toList();
    }
    if (endDate != null) {
      filtered = filtered
          .where((t) => t.transactionDate.isBefore(endDate) || t.transactionDate.isAtSameMomentAs(endDate))
          .toList();
    }

    // Ordena por transaction_date DESC e created_at DESC (mais recente primeiro)
    filtered.sort((a, b) {
      final dateCompare = b.transactionDate.compareTo(a.transactionDate);
      if (dateCompare != 0) return dateCompare;
      final aCreatedAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bCreatedAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bCreatedAt.compareTo(aCreatedAt);
    });

    return _filterByRLS(filtered);
  }

  @override
  Future<FinancialTransaction> updateTransaction({
    required int transactionId,
    required FinancialTransaction transaction,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) {
      throw Exception('Transação não encontrada');
    }

    final existing = _transactions[index];
    final filtered = _filterByRLS([existing]);
    if (filtered.isEmpty) {
      throw Exception('Transação não encontrada ou acesso negado');
    }

    final updated = transaction.copyWith(
      id: existing.id,
      therapistId: existing.therapistId, // Não pode mudar
      patientId: existing.patientId, // Não pode mudar
      sessionId: existing.sessionId, // Não pode mudar
      updatedAt: DateTime.now(),
    );
    _transactions[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTransaction({
    required int transactionId,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index == -1) {
      throw Exception('Transação não encontrada');
    }

    final existing = _transactions[index];
    final filtered = _filterByRLS([existing]);
    if (filtered.isEmpty) {
      throw Exception('Transação não encontrada ou acesso negado');
    }

    _transactions.removeAt(index);
  }

  @override
  Future<Map<String, dynamic>> getFinancialSummary({
    required int therapistId,
    required int userId,
    String? userRole,
    int? accountId,
    DateTime? startDate,
    DateTime? endDate,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    var filtered = _transactions.where((t) => t.therapistId == therapistId).toList();

    if (startDate != null) {
      filtered = filtered
          .where((t) => t.transactionDate.isAfter(startDate) || t.transactionDate.isAtSameMomentAs(startDate))
          .toList();
    }
    if (endDate != null) {
      filtered = filtered
          .where((t) => t.transactionDate.isBefore(endDate) || t.transactionDate.isAtSameMomentAs(endDate))
          .toList();
    }

    final paid = filtered.where((t) => t.status == 'pago').toList();
    final pending = filtered.where((t) => t.status == 'pendente').toList();
    final overdue = filtered.where((t) => t.status == 'atrasado').toList();

    return {
      'totalPaidCount': paid.length,
      'totalPaidAmount': paid.fold<double>(0.0, (sum, t) => sum + t.amount),
      'totalPendingCount': pending.length,
      'totalPendingAmount': pending.fold<double>(0.0, (sum, t) => sum + t.amount),
      'totalOverdueCount': overdue.length,
      'totalOverdueAmount': overdue.fold<double>(0.0, (sum, t) => sum + t.amount),
      'totalCount': filtered.length,
      'totalAmount': filtered.fold<double>(0.0, (sum, t) => sum + t.amount),
    };
  }

  void clear() {
    _transactions.clear();
    _lastId = 0;
    _currentUserId = null;
    _bypassRLS = false;
  }
}
