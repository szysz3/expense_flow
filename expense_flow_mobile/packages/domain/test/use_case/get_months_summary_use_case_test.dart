import 'package:dartz/dartz.dart';
import 'package:domain/model/category_summary.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/month_summary.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_months_summary_use_case_test.mocks.dart';

@GenerateMocks([ReceiptRepository])
void main() {
  late GetMonthsSummaryUseCase useCase;
  late MockReceiptRepository mockRepository;

  setUp(() {
    mockRepository = MockReceiptRepository();
    useCase = GetMonthsSummaryUseCase(mockRepository);
  });

  final testCategories = [
    const CategorySummary(
        id: 'cat1',
        name: 'Groceries',
        iconName: 'shopping_cart',
        amount: 75.0,
        previousMonthAmount: 65.0),
    const CategorySummary(
        id: 'cat2',
        name: 'Entertainment',
        iconName: 'movie',
        amount: 25.0,
        previousMonthAmount: 30.0),
  ];

  final testMonthsSummary = [
    MonthSummary(
      id: 'jan2023',
      monthNumber: 1,
      year: 2023,
      previousMonthTotal: 0.0,
      categories: testCategories,
    ),
    MonthSummary(
      id: 'feb2023',
      monthNumber: 2,
      year: 2023,
      previousMonthTotal: 100.0,
      categories: testCategories,
    ),
  ];

  group('GetMonthsSummaryUseCase', () {
    test('should get months summary from the repository', () async {
      // arrange
      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => Right(testMonthsSummary));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, Right(testMonthsSummary));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository returns ServerFailure',
        () async {
      // arrange
      const failure = ServerFailure('Server error occurred');
      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, const Left(failure));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return ConnectionFailure when repository returns ConnectionFailure',
        () async {
      // arrange
      const failure = ConnectionFailure();
      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, const Left(failure));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return UnauthorizedFailure when repository returns UnauthorizedFailure',
        () async {
      // arrange
      const failure = UnauthorizedFailure();
      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, const Left(failure));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return NotFoundFailure when repository returns NotFoundFailure',
        () async {
      // arrange
      const failure = NotFoundFailure();
      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, const Left(failure));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when repository returns empty list',
        () async {
      // arrange
      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await useCase(const NoParams());

      // assert
      expect(result, const Right(<MonthSummary>[]));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
