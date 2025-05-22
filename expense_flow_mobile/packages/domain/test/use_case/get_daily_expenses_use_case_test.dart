import 'package:dartz/dartz.dart';
import 'package:domain/model/daily_expense.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/get_daily_expenses_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../utils/test_data_factory.dart';
import 'get_autocomplete_suggestions_use_case_test.mocks.dart';

@GenerateMocks([ReceiptRepository])
void main() {
  late GetDailyExpensesUseCase useCase;
  late MockReceiptRepository mockRepository;

  setUp(() {
    mockRepository = MockReceiptRepository();
    useCase = GetDailyExpensesUseCase(mockRepository);
  });

  group('GetDailyExpensesUseCase', () {
    test('should get daily expenses from the repository', () async {
      var params = GetDailyExpensesParams(year: 2023, month: 5);
      final testDailyExpenses = TestDataFactory.createDailyExpenses();

      when(mockRepository.getDailyExpenses(params.year, params.month))
          .thenAnswer((_) async => Right(testDailyExpenses));

      final result = await useCase(params);

      expect(result, Right(testDailyExpenses));
      verify(mockRepository.getDailyExpenses(params.year, params.month));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass correct year and month parameters to repository',
        () async {
      var params = GetDailyExpensesParams(year: 2024, month: 12);
      final testDailyExpenses = TestDataFactory.createDailyExpenses();

      when(mockRepository.getDailyExpenses(2024, 12))
          .thenAnswer((_) async => Right(testDailyExpenses));

      final result = await useCase(params);

      expect(result, Right(testDailyExpenses));
      verify(mockRepository.getDailyExpenses(2024, 12));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when repository returns empty list',
        () async {
      var params = GetDailyExpensesParams(year: 2023, month: 6);

      when(mockRepository.getDailyExpenses(params.year, params.month))
          .thenAnswer((_) async => const Right([]));

      final result = await useCase(params);

      expect(result, const Right(<DailyExpense>[]));
      verify(mockRepository.getDailyExpenses(params.year, params.month));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle single day expense correctly', () async {
      var params = GetDailyExpensesParams(year: 2023, month: 1);
      final singleExpense = [
        TestDataFactory.createSingleDailyExpense(
          day: 15,
          total: 99.99,
          transactionDatetime: DateTime(2023, 1, 15, 14, 30),
        )
      ];

      when(mockRepository.getDailyExpenses(params.year, params.month))
          .thenAnswer((_) async => Right(singleExpense));

      final result = await useCase(params);

      expect(result, Right(singleExpense));
      verify(mockRepository.getDailyExpenses(params.year, params.month));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle edge case months correctly', () async {
      var paramsJanuary = GetDailyExpensesParams(year: 2023, month: 1);
      var paramsDecember = GetDailyExpensesParams(year: 2023, month: 12);
      final testDailyExpenses = TestDataFactory.createDailyExpenses();

      when(mockRepository.getDailyExpenses(2023, 1))
          .thenAnswer((_) async => Right(testDailyExpenses));
      when(mockRepository.getDailyExpenses(2023, 12))
          .thenAnswer((_) async => Right(testDailyExpenses));

      final resultJanuary = await useCase(paramsJanuary);
      final resultDecember = await useCase(paramsDecember);

      expect(resultJanuary, Right(testDailyExpenses));
      expect(resultDecember, Right(testDailyExpenses));
      verify(mockRepository.getDailyExpenses(2023, 1));
      verify(mockRepository.getDailyExpenses(2023, 12));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository returns ServerFailure',
        () async {
      var params = GetDailyExpensesParams(year: 2023, month: 5);
      const failure = ServerFailure('Server error occurred');

      when(mockRepository.getDailyExpenses(params.year, params.month))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params);

      expect(result, const Left(failure));
      verify(mockRepository.getDailyExpenses(params.year, params.month));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return ConnectionFailure when repository returns ConnectionFailure',
        () async {
      var params = GetDailyExpensesParams(year: 2023, month: 5);
      const failure = ConnectionFailure();

      when(mockRepository.getDailyExpenses(params.year, params.month))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params);

      expect(result, const Left(failure));
      verify(mockRepository.getDailyExpenses(params.year, params.month));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return UnauthorizedFailure when repository returns UnauthorizedFailure',
        () async {
      var params = GetDailyExpensesParams(year: 2023, month: 5);
      const failure = UnauthorizedFailure();

      when(mockRepository.getDailyExpenses(params.year, params.month))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params);

      expect(result, const Left(failure));
      verify(mockRepository.getDailyExpenses(params.year, params.month));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return NotFoundFailure when repository returns NotFoundFailure',
        () async {
      var params = GetDailyExpensesParams(year: 2023, month: 5);
      const failure = NotFoundFailure();

      when(mockRepository.getDailyExpenses(params.year, params.month))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params);

      expect(result, const Left(failure));
      verify(mockRepository.getDailyExpenses(params.year, params.month));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return ValidationFailure when repository returns ValidationFailure',
        () async {
      var params = GetDailyExpensesParams(year: 2023, month: 5);
      const failure = ValidationFailure([
        {'field': 'year', 'message': 'Invalid year'},
        {'field': 'month', 'message': 'Invalid month'}
      ]);

      when(mockRepository.getDailyExpenses(params.year, params.month))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params);

      expect(result, const Left(failure));
      verify(mockRepository.getDailyExpenses(params.year, params.month));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
