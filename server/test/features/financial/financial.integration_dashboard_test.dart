// Integration test for Financial Dashboard Metrics
//
// This test is kept separate from financial.integration_test.dart because:
// 1. It tests complex aggregation logic specific to dashboard metrics
// 2. The main integration test file is already very large (939 lines)
// 3. Dashboard metrics require specific test data setup with multiple transaction types
// 4. getDashboardMetrics provides richer metrics than /financial/summary endpoint:
//    - Income vs Expense breakdown
//    - Overdue percentage calculation
//    - Payment method distribution
//
import 'package:test/test.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:postgres/postgres.dart';
import 'package:server/features/financial/financial.repository.dart';
import 'package:common/common.dart';
import '../../helpers/integration_test_db.dart';

void main() {
  late DBConnection dbConnection;
  late FinancialRepository repository;

  setUpAll(() async {
    // Force cleanup
    try {
      final conn = await IntegrationTestDB.createTestConnection();
      await conn.execute('DROP TABLE IF EXISTS financial_transactions CASCADE');
      await conn.close();
    } catch (e) {
      print('Cleanup error (ignored): $e');
    }

    await IntegrationTestDB.setup();
    dbConnection = TestDBConnection();
    await dbConnection.initialize();
    repository = FinancialRepository(dbConnection);
  });

  tearDownAll(() async {
    await dbConnection.closeAll();
  });

  test('should return correct dashboard metrics', () async {
    // 0. Setup: Create Therapist and Patient
    final conn = await dbConnection.getConnection();

    // Create Therapist
    final therapistResult = await conn.execute(
      Sql.named('''
        INSERT INTO therapists (user_id, name, email, professional_registry_number, professional_registry_type)
        VALUES (NULL, 'Dr. Money', 'money@example.com', '99999', 'CRP')
        RETURNING id
      '''),
    );
    final therapistId = therapistResult.first[0] as int;

    // Create Patient
    final patientResult = await conn.execute(
      Sql.named('''
        INSERT INTO patients (therapist_id, full_name, phones)
        VALUES (@therapistId, 'Rich Patient', ARRAY['11999999999'])
        RETURNING id
      '''),
      parameters: {'therapistId': therapistId},
    );
    final patientId = patientResult.first[0] as int;

    // 1. Create transactions
    // - 2 Income Paid (100, 200) -> Total Income 300
    // - 1 Expense Paid (50) -> Total Expense 50
    // - 1 Income Overdue (300) -> Overdue Count 1, Total Active 4 (below)
    // - 1 Income Pending (400) -> Total Active 5 (aggregated)

    await repository.createTransaction(
      transaction: FinancialTransaction(
        therapistId: therapistId,
        patientId: patientId,
        transactionDate: DateTime.now(),
        type: 'income',
        amount: 100,
        paymentMethod: 'cash',
        status: 'paid',
        category: 'session',
      ),
      userId: 1,
      userRole: 'therapist',
    );

    await repository.createTransaction(
      transaction: FinancialTransaction(
        therapistId: therapistId,
        patientId: patientId,
        transactionDate: DateTime.now(),
        type: 'income',
        amount: 200,
        paymentMethod: 'credit_card',
        status: 'paid',
        category: 'session',
      ),
      userId: 1,
      userRole: 'therapist',
    );

    await repository.createTransaction(
      transaction: FinancialTransaction(
        therapistId: therapistId,
        patientId: patientId,
        transactionDate: DateTime.now().subtract(Duration(days: 5)),
        type: 'income',
        amount: 300,
        paymentMethod: 'cash',
        status: 'overdue', // overdue
        category: 'session',
      ),
      userId: 1,
      userRole: 'therapist',
    );

    await repository.createTransaction(
      transaction: FinancialTransaction(
        therapistId: therapistId,
        patientId: patientId,
        transactionDate: DateTime.now(),
        type: 'income',
        amount: 400,
        paymentMethod: 'pix',
        status: 'pending',
        category: 'session',
      ),
      userId: 1,
      userRole: 'therapist',
    );

    // 2. Fetch metrics
    final metrics = await repository.getDashboardMetrics(therapistId: therapistId, userId: 1);

    // 3. Verify
    // Paid Income: 100 + 200 = 300
    expect(metrics['totalIncome'], equals(300.0));
    expect(metrics['totalExpense'], equals(0.0));

    // Check extended summary fields
    expect(metrics['totalPendingAmount'], equals(400.0)); // 400 Pix
    expect(metrics['totalOverdueAmount'], equals(300.0)); // 300 Cash

    expect(metrics['totalPaidCount'], equals(2)); // 100 Cash + 200 CC
    expect(metrics['totalPendingCount'], equals(1)); // 400 Pix
    expect(metrics['totalOverdueCount'], equals(1)); // 300 Cash

    // Total active = 4 (2 paid income + 1 overdue + 1 pending)
    // Overdue count = 1
    // Percentage = (1 / 4) * 100 = 25.0
    expect(metrics['overduePercentage'], equals(25.0));

    final distribution = metrics['paymentMethodDistribution'] as List;
    // Income Transactions (Paid Only):
    // - cash: 100 (paid). The 300 overdue is excluded.
    // - credit_card: 200 (paid).
    // - pix: 400 (pending - excluded)

    // Check cash
    final cash = distribution.firstWhere((e) => e['method'] == 'cash');
    expect(cash['count'], equals(1)); // Only the paid one
    expect(cash['amount'], equals(100.0));

    // Check credit_card
    final cc = distribution.firstWhere((e) => e['method'] == 'credit_card');
    expect(cc['count'], equals(1));
    expect(cc['amount'], equals(200.0));

    // Pix should not be in the list (or have 0 count/amount if returned)
    // Actually the query groups by payment_method where status='paid'. Pix is pending.
    // So distinct payment methods of paid transactions are only cash and credit_card.
    expect(distribution.any((e) => e['method'] == 'pix'), isFalse);
  });
}
