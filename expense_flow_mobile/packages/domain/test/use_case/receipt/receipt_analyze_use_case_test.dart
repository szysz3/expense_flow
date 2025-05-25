import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/receipt/receipt_analyze_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../utils/test_data_factory.dart';
import '../get_autocomplete_suggestions_use_case_test.mocks.dart';

@GenerateMocks([ReceiptRepository])
void main() {
  late ReceiptAnalyzeUseCase useCase;
  late MockReceiptRepository mockRepository;

  setUp(() {
    mockRepository = MockReceiptRepository();
    useCase = ReceiptAnalyzeUseCase(mockRepository);
  });

  group('ReceiptAnalyzeUseCase', () {
    const testFilePath = '/path/to/receipt.jpg';
    const testLlmType = 'openai';

    final testReceipt = TestDataFactory.createReceipt(
      id: 'test-receipt-id',
      total: 125.50,
      transactionDateTime: DateTime(2023, 12, 15, 14, 30),
      addedDateTime: DateTime(2023, 12, 15, 15, 0),
    );

    group('successful analysis', () {
      test(
          'should return receipt when repository call succeeds with default llmType',
          () async {
        when(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .thenAnswer((_) async => Right(testReceipt));

        final params = ReceiptAnalyzeParams(filePath: testFilePath);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, Receipt>>());
        expect(result.fold((_) => null, (receipt) => receipt),
            equals(testReceipt));
        verify(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .called(1);
      });

      test(
          'should return receipt when repository call succeeds with custom llmType',
          () async {
        when(mockRepository.analyzeReceipt(testFilePath, llmType: testLlmType))
            .thenAnswer((_) async => Right(testReceipt));

        final params = ReceiptAnalyzeParams(
          filePath: testFilePath,
          llmType: testLlmType,
        );
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, Receipt>>());
        expect(result.fold((_) => null, (receipt) => receipt),
            equals(testReceipt));
        verify(mockRepository.analyzeReceipt(testFilePath,
                llmType: testLlmType))
            .called(1);
      });
    });

    group('failed analysis', () {
      test('should return ServerFailure when repository returns server error',
          () async {
        const failure = ServerFailure('Analysis failed on server');
        when(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptAnalyzeParams(filePath: testFilePath);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .called(1);
      });

      test(
          'should return ConnectionFailure when repository returns connection error',
          () async {
        const failure = ConnectionFailure();
        when(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptAnalyzeParams(filePath: testFilePath);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .called(1);
      });

      test('should return NotFoundFailure when file is not found', () async {
        const failure = NotFoundFailure();
        when(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptAnalyzeParams(filePath: testFilePath);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .called(1);
      });

      test('should return ValidationFailure when validation fails', () async {
        const failure = ValidationFailure([
          {'field': 'filePath', 'error': 'Invalid file format'}
        ]);
        when(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptAnalyzeParams(filePath: testFilePath);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .called(1);
      });
    });

    group('parameter validation', () {
      test('should use default llmType when not provided', () async {
        when(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .thenAnswer((_) async => Right(testReceipt));

        final params = ReceiptAnalyzeParams(filePath: testFilePath);

        expect(params.llmType, equals('local'));

        await useCase.call(params);
        verify(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .called(1);
      });

      test('should handle empty file path', () async {
        const emptyFilePath = '';
        const failure = ValidationFailure([
          {'field': 'filePath', 'error': 'File path cannot be empty'}
        ]);

        when(mockRepository.analyzeReceipt(emptyFilePath, llmType: 'local'))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptAnalyzeParams(filePath: emptyFilePath);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, Receipt>>());
        verify(mockRepository.analyzeReceipt(emptyFilePath, llmType: 'local'))
            .called(1);
      });

      test('should handle different llmType values', () async {
        const llmTypes = ['local', 'openai', 'anthropic', 'custom'];

        for (final llmType in llmTypes) {
          when(mockRepository.analyzeReceipt(testFilePath, llmType: llmType))
              .thenAnswer((_) async => Right(testReceipt));

          final params = ReceiptAnalyzeParams(
            filePath: testFilePath,
            llmType: llmType,
          );
          final result = await useCase.call(params);

          expect(result, isA<Right<Failure, Receipt>>());
          verify(mockRepository.analyzeReceipt(testFilePath, llmType: llmType))
              .called(1);
        }
      });
    });

    group('edge cases', () {
      test('should handle repository throwing exception', () async {
        when(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .thenThrow(Exception('Unexpected error'));

        final params = ReceiptAnalyzeParams(filePath: testFilePath);

        expect(
          () async => await useCase.call(params),
          throwsException,
        );
      });

      test('should handle very long file paths', () async {
        final longFilePath = '/very/long/path/${'a' * 1000}/receipt.jpg';

        when(mockRepository.analyzeReceipt(longFilePath, llmType: 'local'))
            .thenAnswer((_) async => Right(testReceipt));

        final params = ReceiptAnalyzeParams(filePath: longFilePath);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.analyzeReceipt(longFilePath, llmType: 'local'))
            .called(1);
      });

      test('should handle special characters in file path', () async {
        const specialFilePath = '/path/with spaces/special@chars#receipt\$.jpg';

        when(mockRepository.analyzeReceipt(specialFilePath, llmType: 'local'))
            .thenAnswer((_) async => Right(testReceipt));

        final params = ReceiptAnalyzeParams(filePath: specialFilePath);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.analyzeReceipt(specialFilePath, llmType: 'local'))
            .called(1);
      });
    });

    group('use case contract', () {
      test('should implement BaseUseCase interface correctly', () {
        expect(useCase,
            isA<BaseUseCase<ReceiptAnalyzeParams, Either<Failure, Receipt>>>());
      });

      test('should call repository method exactly once per invocation',
          () async {
        when(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .thenAnswer((_) async => Right(testReceipt));

        final params = ReceiptAnalyzeParams(filePath: testFilePath);

        await useCase.call(params);
        await useCase.call(params);
        await useCase.call(params);

        verify(mockRepository.analyzeReceipt(testFilePath, llmType: 'local'))
            .called(3);
      });
    });
  });

  group('ReceiptAnalyzeParams', () {
    test('should create params with required filePath', () {
      const filePath = '/test/path.jpg';
      final params = ReceiptAnalyzeParams(filePath: filePath);

      expect(params.filePath, equals(filePath));
      expect(params.llmType, equals('local'));
    });

    test('should create params with custom llmType', () {
      const filePath = '/test/path.jpg';
      const llmType = 'openai';
      final params = ReceiptAnalyzeParams(
        filePath: filePath,
        llmType: llmType,
      );

      expect(params.filePath, equals(filePath));
      expect(params.llmType, equals(llmType));
    });

    test('should handle null llmType by using default', () {
      const filePath = '/test/path.jpg';
      final params = ReceiptAnalyzeParams(filePath: filePath);

      expect(params.llmType, equals('local'));
    });
  });
}
