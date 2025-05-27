import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/receipt_get_response.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/receipt/receipt_get_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../utils/test_data_factory.dart';
import '../get_autocomplete_suggestions_use_case_test.mocks.dart';

@GenerateMocks([ReceiptRepository])
void main() {
  late ReceiptGetUseCase useCase;
  late MockReceiptRepository mockRepository;

  setUp(() {
    mockRepository = MockReceiptRepository();
    useCase = ReceiptGetUseCase(mockRepository);
  });

  group('ReceiptGetUseCase', () {
    const testPage = 1;
    const testPageSize = 10;

    final testResponse = TestDataFactory.createReceiptGetResponse(
      totalCount: 25,
    );

    group('successful retrieval', () {
      test('should return receipt response when repository call succeeds',
          () async {
        when(mockRepository.getReceipts(testPage, testPageSize))
            .thenAnswer((_) async => Right(testResponse));

        final params = ReceiptGetParams(page: testPage, pageSize: testPageSize);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, ReceiptGetResponse>>());
        expect(result.fold((_) => null, (response) => response),
            equals(testResponse));
        verify(mockRepository.getReceipts(testPage, testPageSize)).called(1);
      });

      test('should handle first page request', () async {
        final firstPageResponse = TestDataFactory.createReceiptGetResponse(
          receipts: TestDataFactory.createReceiptsList(count: 20),
          totalCount: 100,
        );

        when(mockRepository.getReceipts(1, 20))
            .thenAnswer((_) async => Right(firstPageResponse));

        final params = ReceiptGetParams(page: 1, pageSize: 20);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, ReceiptGetResponse>>());
        final response = result.fold((_) => null, (r) => r)!;
        expect(response.receipts.length, equals(20));
        expect(response.totalCount, equals(100));
        verify(mockRepository.getReceipts(1, 20)).called(1);
      });

      test('should handle last page request', () async {
        final lastPageResponse = TestDataFactory.createReceiptGetResponse(
          receipts: TestDataFactory.createReceiptsList(count: 5),
          totalCount: 45,
        );

        when(mockRepository.getReceipts(5, 10))
            .thenAnswer((_) async => Right(lastPageResponse));

        final params = ReceiptGetParams(page: 5, pageSize: 10);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, ReceiptGetResponse>>());
        final response = result.fold((_) => null, (r) => r)!;
        expect(response.receipts.length, equals(5));
        expect(response.totalCount, equals(45));
        verify(mockRepository.getReceipts(5, 10)).called(1);
      });

      test('should handle empty results', () async {
        final emptyResponse = TestDataFactory.createReceiptGetResponse(
          receipts: [],
          totalCount: 0,
        );

        when(mockRepository.getReceipts(1, 10))
            .thenAnswer((_) async => Right(emptyResponse));

        final params = ReceiptGetParams(page: 1, pageSize: 10);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, ReceiptGetResponse>>());
        final response = result.fold((_) => null, (r) => r)!;
        expect(response.receipts, isEmpty);
        expect(response.totalCount, equals(0));
        verify(mockRepository.getReceipts(1, 10)).called(1);
      });

      test('should handle large page sizes', () async {
        final largePageResponse = TestDataFactory.createReceiptGetResponse(
          receipts: TestDataFactory.createReceiptsList(count: 50),
          totalCount: 50,
        );

        when(mockRepository.getReceipts(1, 100))
            .thenAnswer((_) async => Right(largePageResponse));

        final params = ReceiptGetParams(page: 1, pageSize: 100);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, ReceiptGetResponse>>());
        final response = result.fold((_) => null, (r) => r)!;
        expect(response.receipts.length, equals(50));
        expect(response.totalCount, equals(50));
        verify(mockRepository.getReceipts(1, 100)).called(1);
      });
    });

    group('failed retrieval', () {
      test('should return ServerFailure when repository returns server error',
          () async {
        const failure = ServerFailure('Failed to fetch receipts from server');
        when(mockRepository.getReceipts(testPage, testPageSize))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptGetParams(page: testPage, pageSize: testPageSize);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, ReceiptGetResponse>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.getReceipts(testPage, testPageSize)).called(1);
      });

      test(
          'should return ConnectionFailure when repository returns connection error',
          () async {
        const failure = ConnectionFailure();
        when(mockRepository.getReceipts(testPage, testPageSize))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptGetParams(page: testPage, pageSize: testPageSize);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, ReceiptGetResponse>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.getReceipts(testPage, testPageSize)).called(1);
      });

      test(
          'should return UnauthorizedFailure when repository returns unauthorized error',
          () async {
        const failure = UnauthorizedFailure();
        when(mockRepository.getReceipts(testPage, testPageSize))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptGetParams(page: testPage, pageSize: testPageSize);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, ReceiptGetResponse>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.getReceipts(testPage, testPageSize)).called(1);
      });

      test('should return ValidationFailure when validation fails', () async {
        const failure = ValidationFailure([
          {'field': 'page', 'error': 'Page must be greater than 0'},
          {'field': 'pageSize', 'error': 'Page size must be between 1 and 100'}
        ]);
        when(mockRepository.getReceipts(testPage, testPageSize))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptGetParams(page: testPage, pageSize: testPageSize);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, ReceiptGetResponse>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.getReceipts(testPage, testPageSize)).called(1);
      });
    });

    group('parameter validation', () {
      test('should handle zero page number', () async {
        const failure = ValidationFailure([
          {'field': 'page', 'error': 'Page must be greater than 0'}
        ]);

        when(mockRepository.getReceipts(0, testPageSize))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptGetParams(page: 0, pageSize: testPageSize);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, ReceiptGetResponse>>());
        verify(mockRepository.getReceipts(0, testPageSize)).called(1);
      });

      test('should handle negative page number', () async {
        const failure = ValidationFailure([
          {'field': 'page', 'error': 'Page must be greater than 0'}
        ]);

        when(mockRepository.getReceipts(-1, testPageSize))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptGetParams(page: -1, pageSize: testPageSize);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, ReceiptGetResponse>>());
        verify(mockRepository.getReceipts(-1, testPageSize)).called(1);
      });

      test('should handle zero page size', () async {
        const failure = ValidationFailure([
          {'field': 'pageSize', 'error': 'Page size must be greater than 0'}
        ]);

        when(mockRepository.getReceipts(testPage, 0))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptGetParams(page: testPage, pageSize: 0);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, ReceiptGetResponse>>());
        verify(mockRepository.getReceipts(testPage, 0)).called(1);
      });

      test('should handle negative page size', () async {
        const failure = ValidationFailure([
          {'field': 'pageSize', 'error': 'Page size must be greater than 0'}
        ]);

        when(mockRepository.getReceipts(testPage, -5))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptGetParams(page: testPage, pageSize: -5);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, ReceiptGetResponse>>());
        verify(mockRepository.getReceipts(testPage, -5)).called(1);
      });

      test('should handle very large page numbers', () async {
        const largePage = 999999;
        final largePageResponse = TestDataFactory.createReceiptGetResponse(
          receipts: [],
          totalCount: 100,
        );

        when(mockRepository.getReceipts(largePage, testPageSize))
            .thenAnswer((_) async => Right(largePageResponse));

        final params =
            ReceiptGetParams(page: largePage, pageSize: testPageSize);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, ReceiptGetResponse>>());
        expect(result.fold((_) => null, (r) => r)!.receipts, isEmpty);
        verify(mockRepository.getReceipts(largePage, testPageSize)).called(1);
      });

      test('should handle very large page sizes', () async {
        const largePageSize = 1000;
        const failure = ValidationFailure([
          {'field': 'pageSize', 'error': 'Page size too large'}
        ]);

        when(mockRepository.getReceipts(testPage, largePageSize))
            .thenAnswer((_) async => const Left(failure));

        final params =
            ReceiptGetParams(page: testPage, pageSize: largePageSize);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, ReceiptGetResponse>>());
        verify(mockRepository.getReceipts(testPage, largePageSize)).called(1);
      });
    });

    group('edge cases', () {
      test('should handle repository throwing exception', () async {
        when(mockRepository.getReceipts(testPage, testPageSize))
            .thenThrow(Exception('Unexpected error'));

        final params = ReceiptGetParams(page: testPage, pageSize: testPageSize);

        expect(
          () async => await useCase.call(params),
          throwsException,
        );
      });

      test('should handle single page size', () async {
        final singleItemResponse = TestDataFactory.createReceiptGetResponse(
          receipts: [TestDataFactory.createReceipt()],
          totalCount: 50,
        );

        when(mockRepository.getReceipts(1, 1))
            .thenAnswer((_) async => Right(singleItemResponse));

        final params = ReceiptGetParams(page: 1, pageSize: 1);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, ReceiptGetResponse>>());
        final response = result.fold((_) => null, (r) => r)!;
        expect(response.receipts.length, equals(1));
        expect(response.totalCount, equals(50));
        verify(mockRepository.getReceipts(1, 1)).called(1);
      });

      test('should handle maximum integer values', () async {
        const maxPage = 2147483647;
        const maxPageSize = 2147483647;
        const failure = ValidationFailure([
          {'field': 'pageSize', 'error': 'Page size too large'}
        ]);

        when(mockRepository.getReceipts(maxPage, maxPageSize))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptGetParams(page: maxPage, pageSize: maxPageSize);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, ReceiptGetResponse>>());
        verify(mockRepository.getReceipts(maxPage, maxPageSize)).called(1);
      });
    });

    group('pagination scenarios', () {
      test('should handle typical pagination flow', () async {
        final paginationScenarios = [
          {'page': 1, 'pageSize': 10, 'receipts': 10, 'total': 25},
          {'page': 2, 'pageSize': 10, 'receipts': 10, 'total': 25},
          {'page': 3, 'pageSize': 10, 'receipts': 5, 'total': 25},
        ];

        for (final scenario in paginationScenarios) {
          final page = scenario['page'] as int;
          final pageSize = scenario['pageSize'] as int;
          final receiptsCount = scenario['receipts'] as int;
          final total = scenario['total'] as int;

          final response = TestDataFactory.createReceiptGetResponse(
            receipts: TestDataFactory.createReceiptsList(count: receiptsCount),
            totalCount: total,
          );

          when(mockRepository.getReceipts(page, pageSize))
              .thenAnswer((_) async => Right(response));

          final params = ReceiptGetParams(page: page, pageSize: pageSize);
          final result = await useCase.call(params);

          expect(result, isA<Right<Failure, ReceiptGetResponse>>());
          final resultResponse = result.fold((_) => null, (r) => r)!;
          expect(resultResponse.receipts.length, equals(receiptsCount));
          expect(resultResponse.totalCount, equals(total));
          verify(mockRepository.getReceipts(page, pageSize)).called(1);
        }
      });

      test('should handle different page sizes', () async {
        final pageSizes = [5, 10, 20, 50, 100];

        for (final pageSize in pageSizes) {
          final receiptsCount = pageSize <= 100 ? pageSize : 100;
          final response = TestDataFactory.createReceiptGetResponse(
            receipts: TestDataFactory.createReceiptsList(count: receiptsCount),
            totalCount: 100,
          );

          when(mockRepository.getReceipts(1, pageSize))
              .thenAnswer((_) async => Right(response));

          final params = ReceiptGetParams(page: 1, pageSize: pageSize);
          final result = await useCase.call(params);

          expect(result, isA<Right<Failure, ReceiptGetResponse>>());
          final resultResponse = result.fold((_) => null, (r) => r)!;
          expect(resultResponse.receipts.length, equals(receiptsCount));
          expect(resultResponse.totalCount, equals(100));
          verify(mockRepository.getReceipts(1, pageSize)).called(1);
        }
      });
    });

    group('use case contract', () {
      test('should implement BaseUseCase interface correctly', () {
        expect(
            useCase,
            isA<
                BaseUseCase<ReceiptGetParams,
                    Either<Failure, ReceiptGetResponse>>>());
      });

      test('should call repository method exactly once per invocation',
          () async {
        when(mockRepository.getReceipts(testPage, testPageSize))
            .thenAnswer((_) async => Right(testResponse));

        final params = ReceiptGetParams(page: testPage, pageSize: testPageSize);

        await useCase.call(params);
        await useCase.call(params);
        await useCase.call(params);

        verify(mockRepository.getReceipts(testPage, testPageSize)).called(3);
      });

      test('should pass exact same parameters from params to repository',
          () async {
        when(mockRepository.getReceipts(testPage, testPageSize))
            .thenAnswer((_) async => Right(testResponse));

        final params = ReceiptGetParams(page: testPage, pageSize: testPageSize);
        await useCase.call(params);

        final captured =
            verify(mockRepository.getReceipts(captureAny, captureAny)).captured;
        expect(captured[0], equals(testPage));
        expect(captured[1], equals(testPageSize));
      });

      test('should handle concurrent requests with different parameters',
          () async {
        final scenarios = [
          {'page': 1, 'pageSize': 10},
          {'page': 2, 'pageSize': 20},
          {'page': 3, 'pageSize': 5},
        ];

        for (final scenario in scenarios) {
          final page = scenario['page'] as int;
          final pageSize = scenario['pageSize'] as int;

          final response = TestDataFactory.createReceiptGetResponse(
            receipts: TestDataFactory.createReceiptsList(
                count: pageSize <= 10 ? pageSize : 10),
            totalCount: 100,
          );

          when(mockRepository.getReceipts(page, pageSize))
              .thenAnswer((_) async => Right(response));
        }

        final futures = scenarios.map((scenario) {
          final page = scenario['page'] as int;
          final pageSize = scenario['pageSize'] as int;
          final params = ReceiptGetParams(page: page, pageSize: pageSize);
          return useCase.call(params);
        });

        final results = await Future.wait(futures);

        for (final result in results) {
          expect(result, isA<Right<Failure, ReceiptGetResponse>>());
        }

        for (final scenario in scenarios) {
          final page = scenario['page'] as int;
          final pageSize = scenario['pageSize'] as int;
          verify(mockRepository.getReceipts(page, pageSize)).called(1);
        }
      });
    });

    group('realistic scenarios', () {
      test('should handle mobile app pagination (small pages)', () async {
        final mobileResponse = TestDataFactory.createReceiptGetResponse(
          receipts: TestDataFactory.createReceiptsList(count: 5),
          totalCount: 100,
        );

        when(mockRepository.getReceipts(1, 5))
            .thenAnswer((_) async => Right(mobileResponse));

        final params = ReceiptGetParams(page: 1, pageSize: 5);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, ReceiptGetResponse>>());
        final response = result.fold((_) => null, (r) => r)!;
        expect(response.receipts.length, equals(5));
        expect(response.totalCount, equals(100));
        verify(mockRepository.getReceipts(1, 5)).called(1);
      });

      test('should handle web dashboard pagination (larger pages)', () async {
        final webResponse = TestDataFactory.createReceiptGetResponse(
          receipts: TestDataFactory.createReceiptsList(count: 25),
          totalCount: 100,
        );

        when(mockRepository.getReceipts(1, 25))
            .thenAnswer((_) async => Right(webResponse));

        final params = ReceiptGetParams(page: 1, pageSize: 25);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, ReceiptGetResponse>>());
        final response = result.fold((_) => null, (r) => r)!;
        expect(response.receipts.length, equals(25));
        expect(response.totalCount, equals(100));
        verify(mockRepository.getReceipts(1, 25)).called(1);
      });

      test('should handle export scenario (large pages)', () async {
        final exportResponse = TestDataFactory.createReceiptGetResponse(
          receipts: TestDataFactory.createReceiptsList(count: 500),
          totalCount: 500,
        );

        when(mockRepository.getReceipts(1, 1000))
            .thenAnswer((_) async => Right(exportResponse));

        final params = ReceiptGetParams(page: 1, pageSize: 1000);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, ReceiptGetResponse>>());
        final response = result.fold((_) => null, (r) => r)!;
        expect(response.receipts.length, equals(500));
        expect(response.totalCount, equals(500));
        verify(mockRepository.getReceipts(1, 1000)).called(1);
      });
    });
  });

  group('ReceiptGetParams', () {
    test('should create params with required page and pageSize', () {
      const page = 5;
      const pageSize = 20;
      final params = ReceiptGetParams(page: page, pageSize: pageSize);

      expect(params.page, equals(page));
      expect(params.pageSize, equals(pageSize));
    });

    test('should handle zero values', () {
      const page = 0;
      const pageSize = 0;
      final params = ReceiptGetParams(page: page, pageSize: pageSize);

      expect(params.page, equals(page));
      expect(params.pageSize, equals(pageSize));
    });

    test('should handle negative values', () {
      const page = -1;
      const pageSize = -10;
      final params = ReceiptGetParams(page: page, pageSize: pageSize);

      expect(params.page, equals(page));
      expect(params.pageSize, equals(pageSize));
    });

    test('should handle large values', () {
      const page = 1000000;
      const pageSize = 50000;
      final params = ReceiptGetParams(page: page, pageSize: pageSize);

      expect(params.page, equals(page));
      expect(params.pageSize, equals(pageSize));
    });
  });
}
