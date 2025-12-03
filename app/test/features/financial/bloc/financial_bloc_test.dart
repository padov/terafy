import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/core/domain/usecases/financial/create_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/delete_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/get_financial_summary_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/get_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/get_transactions_usecase.dart';
import 'package:terafy/core/domain/usecases/financial/update_transaction_usecase.dart';
import 'package:terafy/core/domain/usecases/therapist/get_current_therapist_usecase.dart';
import 'package:terafy/features/financial/bloc/financial_bloc.dart';
import 'package:terafy/features/financial/bloc/financial_bloc_models.dart';

class _MockGetTransactionsUseCase extends Mock implements GetTransactionsUseCase {}

class _MockGetTransactionUseCase extends Mock implements GetTransactionUseCase {}

class _MockCreateTransactionUseCase extends Mock implements CreateTransactionUseCase {}

class _MockUpdateTransactionUseCase extends Mock implements UpdateTransactionUseCase {}

class _MockDeleteTransactionUseCase extends Mock implements DeleteTransactionUseCase {}

class _MockGetFinancialSummaryUseCase extends Mock implements GetFinancialSummaryUseCase {}

class _MockGetCurrentTherapistUseCase extends Mock implements GetCurrentTherapistUseCase {}

void main() {
  group('FinancialBloc', () {
    late _MockGetTransactionsUseCase getTransactionsUseCase;
    late _MockGetTransactionUseCase getTransactionUseCase;
    late _MockCreateTransactionUseCase createTransactionUseCase;
    late _MockUpdateTransactionUseCase updateTransactionUseCase;
    late _MockDeleteTransactionUseCase deleteTransactionUseCase;
    late _MockGetFinancialSummaryUseCase getFinancialSummaryUseCase;
    late _MockGetCurrentTherapistUseCase getCurrentTherapistUseCase;
    late FinancialBloc bloc;

    setUp(() {
      getTransactionsUseCase = _MockGetTransactionsUseCase();
      getTransactionUseCase = _MockGetTransactionUseCase();
      createTransactionUseCase = _MockCreateTransactionUseCase();
      updateTransactionUseCase = _MockUpdateTransactionUseCase();
      deleteTransactionUseCase = _MockDeleteTransactionUseCase();
      getFinancialSummaryUseCase = _MockGetFinancialSummaryUseCase();
      getCurrentTherapistUseCase = _MockGetCurrentTherapistUseCase();
      bloc = FinancialBloc(
        getTransactionsUseCase: getTransactionsUseCase,
        getTransactionUseCase: getTransactionUseCase,
        createTransactionUseCase: createTransactionUseCase,
        updateTransactionUseCase: updateTransactionUseCase,
        deleteTransactionUseCase: deleteTransactionUseCase,
        getFinancialSummaryUseCase: getFinancialSummaryUseCase,
        getCurrentTherapistUseCase: getCurrentTherapistUseCase,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('estado inicial é FinancialInitial', () {
      expect(bloc.state, const FinancialInitial());
    });

    blocTest<FinancialBloc, FinancialState>(
      'emite FinancialSummaryLoaded quando LoadFinancialSummary é adicionado',
      build: () {
        when(() => getCurrentTherapistUseCase()).thenAnswer((_) async => {'id': 1});
        when(() => getFinancialSummaryUseCase(
              therapistId: any(named: 'therapistId'),
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => {
              'totalPaidAmount': 1000.0,
              'totalPendingAmount': 500.0,
              'totalOverdueAmount': 0.0,
              'totalPaidCount': 10,
              'totalPendingCount': 5,
              'totalOverdueCount': 0,
            });
        return bloc;
      },
      act: (bloc) => bloc.add(
        LoadFinancialSummary(
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now(),
        ),
      ),
      expect: () => [
        const FinancialLoading(),
        isA<FinancialSummaryLoaded>(),
      ],
    );

    blocTest<FinancialBloc, FinancialState>(
      'emite FinancialError quando LoadFinancialSummary falha',
      build: () {
        when(() => getCurrentTherapistUseCase()).thenThrow(Exception('Erro'));
        return bloc;
      },
      act: (bloc) => bloc.add(
        LoadFinancialSummary(
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now(),
        ),
      ),
      expect: () => [
        const FinancialLoading(),
        isA<FinancialError>(),
      ],
    );
  });
}

