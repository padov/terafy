import 'package:common/common.dart';
import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/core/database/rls_context.dart';

class FinancialRepository {
  FinancialRepository(this._dbConnection);

  final DBConnection _dbConnection;

  Future<FinancialTransaction> createTransaction({
    required FinancialTransaction transaction,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(
          conn: conn,
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? transaction.therapistId,
        );
      }

      final data = transaction.toDatabaseMap();

      final result = await conn.execute(
        Sql.named('''
        INSERT INTO financial_transactions (
          therapist_id,
          patient_id,
          session_id,
          transaction_date,
          type,
          amount,
          payment_method,
          status,
          due_date,
          paid_at,
          receipt_number,
          category,
          notes,
          invoice_number,
          invoice_issued
        ) VALUES (
          @therapist_id,
          @patient_id,
          @session_id,
          @transaction_date::date,
          @type::transaction_type,
          @amount,
          @payment_method::financial_payment_method,
          @status::transaction_status,
          @due_date::date,
          @paid_at::timestamp with time zone,
          @receipt_number,
          @category::transaction_category,
          @notes,
          @invoice_number,
          @invoice_issued
        )
        RETURNING id,
                  therapist_id,
                  patient_id,
                  session_id,
                  transaction_date,
                  type::text AS type,
                  amount,
                  payment_method::text AS payment_method,
                  status::text AS status,
                  due_date,
                  paid_at,
                  receipt_number,
                  category::text AS category,
                  notes,
                  invoice_number,
                  invoice_issued,
                  created_at,
                  updated_at
      '''),
        parameters: {
          'therapist_id': data['therapist_id'],
          'patient_id': data['patient_id'],
          'session_id': data['session_id'],
          'transaction_date': data['transaction_date'],
          'type': data['type'],
          'amount': data['amount'],
          'payment_method': data['payment_method'],
          'status': data['status'],
          'due_date': data['due_date'],
          'paid_at': data['paid_at'],
          'receipt_number': data['receipt_number'],
          'category': data['category'],
          'notes': data['notes'],
          'invoice_number': data['invoice_number'],
          'invoice_issued': data['invoice_issued'],
        },
      );

      if (result.isEmpty) {
        throw Exception('Erro ao criar transação financeira');
      }

      return FinancialTransaction.fromMap(result.first.toColumnMap());
    });
  }

  Future<FinancialTransaction?> getTransactionById({
    required int transactionId,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: accountId);
      }

      final result = await conn.execute(
        Sql.named('''
        SELECT id,
               therapist_id,
               patient_id,
               session_id,
               transaction_date,
               type::text AS type,
               amount,
               payment_method::text AS payment_method,
               status::text AS status,
               due_date,
               paid_at,
               receipt_number,
               category::text AS category,
               notes,
               invoice_number,
               invoice_issued,
               created_at,
               updated_at
        FROM financial_transactions
        WHERE id = @id
      '''),
        parameters: {'id': transactionId},
      );

      if (result.isEmpty) {
        return null;
      }

      return FinancialTransaction.fromMap(result.first.toColumnMap());
    });
  }

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
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(
          conn: conn,
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? therapistId,
        );
      }

      final conditions = <String>[];
      final parameters = <String, dynamic>{};

      if (therapistId != null) {
        conditions.add('therapist_id = @therapist_id');
        parameters['therapist_id'] = therapistId;
      }

      if (patientId != null) {
        conditions.add('patient_id = @patient_id');
        parameters['patient_id'] = patientId;
      }

      if (sessionId != null) {
        conditions.add('session_id = @session_id');
        parameters['session_id'] = sessionId;
      }

      if (status != null) {
        conditions.add('status = @status::transaction_status');
        parameters['status'] = status;
      }

      if (category != null) {
        conditions.add('category = @category::transaction_category');
        parameters['category'] = category;
      }

      if (startDate != null) {
        conditions.add('transaction_date >= @start_date::date');
        parameters['start_date'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        conditions.add('transaction_date <= @end_date::date');
        parameters['end_date'] = endDate.toIso8601String();
      }

      final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

      final result = await conn.execute(
        Sql.named('''
        SELECT id,
               therapist_id,
               patient_id,
               session_id,
               transaction_date,
               type::text AS type,
               amount,
               payment_method::text AS payment_method,
               status::text AS status,
               due_date,
               paid_at,
               receipt_number,
               category::text AS category,
               notes,
               invoice_number,
               invoice_issued,
               created_at,
               updated_at
        FROM financial_transactions
        $whereClause
        ORDER BY transaction_date DESC, created_at DESC
      '''),
        parameters: parameters,
      );

      return result.map((row) => FinancialTransaction.fromMap(row.toColumnMap())).toList();
    });
  }

  Future<FinancialTransaction> updateTransaction({
    required int transactionId,
    required FinancialTransaction transaction,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(
          conn: conn,
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? transaction.therapistId,
        );
      }

      final data = transaction.toDatabaseMap();
      // Remove campos que não devem ser atualizados diretamente
      data.remove('therapist_id');
      data.remove('patient_id');
      data.remove('session_id');

      final setClauses = <String>[];
      final parameters = <String, dynamic>{'id': transactionId};

      if (data.containsKey('transaction_date')) {
        setClauses.add('transaction_date = @transaction_date::date');
        parameters['transaction_date'] = data['transaction_date'];
      }

      if (data.containsKey('type')) {
        setClauses.add('type = @type::transaction_type');
        parameters['type'] = data['type'];
      }

      if (data.containsKey('amount')) {
        setClauses.add('amount = @amount');
        parameters['amount'] = data['amount'];
      }

      if (data.containsKey('payment_method')) {
        setClauses.add('payment_method = @payment_method::financial_payment_method');
        parameters['payment_method'] = data['payment_method'];
      }

      if (data.containsKey('status')) {
        setClauses.add('status = @status::transaction_status');
        parameters['status'] = data['status'];
      }

      if (data.containsKey('due_date')) {
        setClauses.add('due_date = @due_date::date');
        parameters['due_date'] = data['due_date'];
      }

      if (data.containsKey('paid_at')) {
        setClauses.add('paid_at = @paid_at::timestamp with time zone');
        parameters['paid_at'] = data['paid_at'];
      }

      if (data.containsKey('receipt_number')) {
        setClauses.add('receipt_number = @receipt_number');
        parameters['receipt_number'] = data['receipt_number'];
      }

      if (data.containsKey('category')) {
        setClauses.add('category = @category::transaction_category');
        parameters['category'] = data['category'];
      }

      if (data.containsKey('notes')) {
        setClauses.add('notes = @notes');
        parameters['notes'] = data['notes'];
      }

      if (data.containsKey('invoice_number')) {
        setClauses.add('invoice_number = @invoice_number');
        parameters['invoice_number'] = data['invoice_number'];
      }

      if (data.containsKey('invoice_issued')) {
        setClauses.add('invoice_issued = @invoice_issued');
        parameters['invoice_issued'] = data['invoice_issued'];
      }

      if (setClauses.isEmpty) {
        // Nada para atualizar, retorna o registro atual
        // Usa a mesma conexão que já está em uso
        final existingResult = await conn.execute(
          Sql.named('''
          SELECT id,
                 therapist_id,
                 patient_id,
                 session_id,
                 transaction_date,
                 type::text AS type,
                 amount,
                 payment_method::text AS payment_method,
                 status::text AS status,
                 due_date,
                 paid_at,
                 receipt_number,
                 category::text AS category,
                 notes,
                 invoice_number,
                 invoice_issued,
                 created_at,
                 updated_at
          FROM financial_transactions
          WHERE id = @id
        '''),
          parameters: {'id': transactionId},
        );

        if (existingResult.isEmpty) {
          throw Exception('Transação não encontrada');
        }

        return FinancialTransaction.fromMap(existingResult.first.toColumnMap());
      }

      final result = await conn.execute(
        Sql.named('''
        UPDATE financial_transactions
        SET ${setClauses.join(', ')}
        WHERE id = @id
        RETURNING id,
                  therapist_id,
                  patient_id,
                  session_id,
                  transaction_date,
                  type::text AS type,
                  amount,
                  payment_method::text AS payment_method,
                  status::text AS status,
                  due_date,
                  paid_at,
                  receipt_number,
                  category::text AS category,
                  notes,
                  invoice_number,
                  invoice_issued,
                  created_at,
                  updated_at
      '''),
        parameters: parameters,
      );

      if (result.isEmpty) {
        throw Exception('Transação não encontrada ou não foi possível atualizar');
      }

      return FinancialTransaction.fromMap(result.first.toColumnMap());
    });
  }

  Future<void> deleteTransaction({
    required int transactionId,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(conn: conn, userId: userId, userRole: userRole, accountId: accountId);
      }

      final result = await conn.execute(
        Sql.named('''
          DELETE FROM financial_transactions
          WHERE id = @id
        '''),
        parameters: {'id': transactionId},
      );

      if (result.affectedRows == 0) {
        throw Exception('Transação não encontrada');
      }
    });
  }

  Future<Map<String, dynamic>> getFinancialSummary({
    required int therapistId,
    required int userId,
    String? userRole,
    int? accountId,
    DateTime? startDate,
    DateTime? endDate,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    return await _dbConnection.withConnection((conn) async {
      if (bypassRLS) {
        await RLSContext.clearContext(conn);
      } else {
        await RLSContext.setContext(
          conn: conn,
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? therapistId,
        );
      }

      final conditions = <String>['therapist_id = @therapist_id'];
      final parameters = <String, dynamic>{'therapist_id': therapistId};

      if (startDate != null) {
        conditions.add('transaction_date >= @start_date::date');
        parameters['start_date'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        conditions.add('transaction_date <= @end_date::date');
        parameters['end_date'] = endDate.toIso8601String();
      }

      final whereClause = conditions.join(' AND ');

      final result = await conn.execute(
        Sql.named('''
        SELECT 
          COUNT(*) FILTER (WHERE status = 'pago') AS total_paid_count,
          COALESCE(SUM(amount) FILTER (WHERE status = 'pago'), 0) AS total_paid_amount,
          COUNT(*) FILTER (WHERE status = 'pendente') AS total_pending_count,
          COALESCE(SUM(amount) FILTER (WHERE status = 'pendente'), 0) AS total_pending_amount,
          COUNT(*) FILTER (WHERE status = 'atrasado') AS total_overdue_count,
          COALESCE(SUM(amount) FILTER (WHERE status = 'atrasado'), 0) AS total_overdue_amount,
          COUNT(*) AS total_count,
          COALESCE(SUM(amount), 0) AS total_amount
        FROM financial_transactions
        WHERE $whereClause
      '''),
        parameters: parameters,
      );

      if (result.isEmpty) {
        return {
          'totalPaidCount': 0,
          'totalPaidAmount': 0.0,
          'totalPendingCount': 0,
          'totalPendingAmount': 0.0,
          'totalOverdueCount': 0,
          'totalOverdueAmount': 0.0,
          'totalCount': 0,
          'totalAmount': 0.0,
        };
      }

      final row = result.first;
      return {
        'totalPaidCount': row[0] as int,
        'totalPaidAmount': (row[1] as num).toDouble(),
        'totalPendingCount': row[2] as int,
        'totalPendingAmount': (row[3] as num).toDouble(),
        'totalOverdueCount': row[4] as int,
        'totalOverdueAmount': (row[5] as num).toDouble(),
        'totalCount': row[6] as int,
        'totalAmount': (row[7] as num).toDouble(),
      };
    });
  }
}
