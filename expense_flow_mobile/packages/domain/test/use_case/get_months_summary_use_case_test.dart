import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/month_summary.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/get_months_summary_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../utils/test_data_factory.dart';
import 'get_months_summary_use_case_test.mocks.dart';

@GenerateMocks([ReceiptRepository])
void main() {
  late GetMonthsSummaryUseCase useCase;
  late MockReceiptRepository mockRepository;

  setUp(() {
    mockRepository = MockReceiptRepository();
    useCase = GetMonthsSummaryUseCase(mockRepository);
  });

  group('GetMonthsSummaryUseCase', () {
    test('should get months summary from the repository', () async {
      final testMonthsSummary = TestDataFactory.createMonthsSummary();

      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => Right(testMonthsSummary));

      final result = await useCase(const NoParams());

      expect(result, Right(testMonthsSummary));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository returns ServerFailure',
        () async {
      const failure = ServerFailure('Server error occurred');
      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(const NoParams());

      expect(result, const Left(failure));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return ConnectionFailure when repository returns ConnectionFailure',
        () async {
      const failure = ConnectionFailure();
      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(const NoParams());

      expect(result, const Left(failure));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return UnauthorizedFailure when repository returns UnauthorizedFailure',
        () async {
      const failure = UnauthorizedFailure();
      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(const NoParams());

      expect(result, const Left(failure));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return NotFoundFailure when repository returns NotFoundFailure',
        () async {
      const failure = NotFoundFailure();
      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(const NoParams());

      expect(result, const Left(failure));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when repository returns empty list',
        () async {
      when(mockRepository.getMonthsSummary())
          .thenAnswer((_) async => const Right([]));

      final result = await useCase(const NoParams());

      expect(result, const Right(<MonthSummary>[]));
      verify(mockRepository.getMonthsSummary());
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
