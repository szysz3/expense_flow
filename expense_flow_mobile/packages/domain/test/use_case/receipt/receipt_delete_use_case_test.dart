import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/receipt/receipt_delete_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../get_autocomplete_suggestions_use_case_test.mocks.dart';

@GenerateMocks([ReceiptRepository])
void main() {
  late ReceiptDeleteUseCase useCase;
  late MockReceiptRepository mockRepository;

  setUp(() {
    mockRepository = MockReceiptRepository();
    useCase = ReceiptDeleteUseCase(mockRepository);
  });

  group('ReceiptDeleteUseCase', () {
    const testReceiptId = 'test-receipt-id-123';

    group('successful deletion', () {
      test('should return true when repository call succeeds', () async {
        when(mockRepository.deleteReceipt(testReceiptId))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: testReceiptId);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, bool>>());
        expect(result.fold((_) => null, (success) => success), equals(true));
        verify(mockRepository.deleteReceipt(testReceiptId)).called(1);
      });

      test('should handle different receipt ID formats', () async {
        final testIds = [
          'simple-id',
          '123456789',
          'uuid-abc123-def456-ghi789',
          'receipt_2023_12_15',
          'UPPERCASE-ID',
          'mixed-Case_ID123',
        ];

        for (final id in testIds) {
          when(mockRepository.deleteReceipt(id))
              .thenAnswer((_) async => const Right(true));

          final params = ReceiptDeleteParams(id: id);
          final result = await useCase.call(params);

          expect(result, isA<Right<Failure, bool>>());
          expect(result.fold((_) => null, (success) => success), equals(true));
          verify(mockRepository.deleteReceipt(id)).called(1);
        }
      });

      test('should handle very long receipt ID', () async {
        final longId = 'very-long-receipt-id-${'a' * 200}';

        when(mockRepository.deleteReceipt(longId))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: longId);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, bool>>());
        expect(result.fold((_) => null, (success) => success), equals(true));
        verify(mockRepository.deleteReceipt(longId)).called(1);
      });

      test('should handle receipt ID with special characters', () async {
        const specialId = 'receipt@domain.com#123\$456';

        when(mockRepository.deleteReceipt(specialId))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: specialId);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, bool>>());
        expect(result.fold((_) => null, (success) => success), equals(true));
        verify(mockRepository.deleteReceipt(specialId)).called(1);
      });
    });

    group('failed deletion', () {
      test('should return ServerFailure when repository returns server error',
          () async {
        const failure = ServerFailure('Failed to delete receipt on server');
        when(mockRepository.deleteReceipt(testReceiptId))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptDeleteParams(id: testReceiptId);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, bool>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.deleteReceipt(testReceiptId)).called(1);
      });

      test(
          'should return ConnectionFailure when repository returns connection error',
          () async {
        const failure = ConnectionFailure();
        when(mockRepository.deleteReceipt(testReceiptId))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptDeleteParams(id: testReceiptId);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, bool>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.deleteReceipt(testReceiptId)).called(1);
      });

      test(
          'should return UnauthorizedFailure when repository returns unauthorized error',
          () async {
        const failure = UnauthorizedFailure();
        when(mockRepository.deleteReceipt(testReceiptId))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptDeleteParams(id: testReceiptId);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, bool>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.deleteReceipt(testReceiptId)).called(1);
      });

      test('should return NotFoundFailure when receipt does not exist',
          () async {
        const failure = NotFoundFailure();
        when(mockRepository.deleteReceipt(testReceiptId))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptDeleteParams(id: testReceiptId);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, bool>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.deleteReceipt(testReceiptId)).called(1);
      });

      test('should return ValidationFailure when validation fails', () async {
        const failure = ValidationFailure([
          {'field': 'id', 'error': 'Receipt ID cannot be empty'},
        ]);
        when(mockRepository.deleteReceipt(testReceiptId))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptDeleteParams(id: testReceiptId);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, bool>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.deleteReceipt(testReceiptId)).called(1);
      });

      test(
          'should return false when deletion is unsuccessful but no error occurs',
          () async {
        when(mockRepository.deleteReceipt(testReceiptId))
            .thenAnswer((_) async => const Right(false));

        final params = ReceiptDeleteParams(id: testReceiptId);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, bool>>());
        expect(result.fold((_) => null, (success) => success), equals(false));
        verify(mockRepository.deleteReceipt(testReceiptId)).called(1);
      });
    });

    group('parameter validation', () {
      test('should handle empty receipt ID', () async {
        const emptyId = '';
        const failure = ValidationFailure([
          {'field': 'id', 'error': 'Receipt ID cannot be empty'}
        ]);

        when(mockRepository.deleteReceipt(emptyId))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptDeleteParams(id: emptyId);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, bool>>());
        verify(mockRepository.deleteReceipt(emptyId)).called(1);
      });

      test('should handle whitespace-only receipt ID', () async {
        const whitespaceId = '   ';
        const failure = ValidationFailure([
          {'field': 'id', 'error': 'Receipt ID cannot be empty or whitespace'}
        ]);

        when(mockRepository.deleteReceipt(whitespaceId))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptDeleteParams(id: whitespaceId);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, bool>>());
        verify(mockRepository.deleteReceipt(whitespaceId)).called(1);
      });

      test('should pass receipt ID exactly as provided', () async {
        const idWithSpaces = ' receipt-id-with-spaces ';

        when(mockRepository.deleteReceipt(idWithSpaces))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: idWithSpaces);
        await useCase.call(params);

        verify(mockRepository.deleteReceipt(idWithSpaces)).called(1);
      });
    });

    group('edge cases', () {
      test('should handle repository throwing exception', () async {
        when(mockRepository.deleteReceipt(testReceiptId))
            .thenThrow(Exception('Unexpected error'));

        final params = ReceiptDeleteParams(id: testReceiptId);

        expect(
          () async => await useCase.call(params),
          throwsException,
        );
      });

      test('should handle unicode characters in receipt ID', () async {
        const unicodeId = 'receipt-🧾-🗑️-123';

        when(mockRepository.deleteReceipt(unicodeId))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: unicodeId);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, bool>>());
        verify(mockRepository.deleteReceipt(unicodeId)).called(1);
      });

      test('should handle numeric-only receipt ID', () async {
        const numericId = '1234567890';

        when(mockRepository.deleteReceipt(numericId))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: numericId);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, bool>>());
        verify(mockRepository.deleteReceipt(numericId)).called(1);
      });

      test('should handle single character receipt ID', () async {
        const singleCharId = 'a';

        when(mockRepository.deleteReceipt(singleCharId))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: singleCharId);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, bool>>());
        verify(mockRepository.deleteReceipt(singleCharId)).called(1);
      });
    });

    group('use case contract', () {
      test('should implement BaseUseCase interface correctly', () {
        expect(useCase,
            isA<BaseUseCase<ReceiptDeleteParams, Either<Failure, bool>>>());
      });

      test('should call repository method exactly once per invocation',
          () async {
        when(mockRepository.deleteReceipt(testReceiptId))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: testReceiptId);

        await useCase.call(params);
        await useCase.call(params);
        await useCase.call(params);

        verify(mockRepository.deleteReceipt(testReceiptId)).called(3);
      });

      test('should pass exact same ID from params to repository', () async {
        when(mockRepository.deleteReceipt(testReceiptId))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: testReceiptId);
        await useCase.call(params);

        final captured =
            verify(mockRepository.deleteReceipt(captureAny)).captured;
        expect(captured.single, equals(testReceiptId));
      });

      test('should handle multiple different IDs in sequence', () async {
        final testIds = ['id1', 'id2', 'id3'];

        for (final id in testIds) {
          when(mockRepository.deleteReceipt(id))
              .thenAnswer((_) async => const Right(true));
        }

        for (final id in testIds) {
          final params = ReceiptDeleteParams(id: id);
          final result = await useCase.call(params);

          expect(result, isA<Right<Failure, bool>>());
          verify(mockRepository.deleteReceipt(id)).called(1);
        }
      });
    });

    group('realistic scenarios', () {
      test('should handle deletion of recent receipt', () async {
        const recentReceiptId = 'receipt-2023-12-15-001';

        when(mockRepository.deleteReceipt(recentReceiptId))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: recentReceiptId);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, bool>>());
        expect(result.fold((_) => null, (success) => success), equals(true));
        verify(mockRepository.deleteReceipt(recentReceiptId)).called(1);
      });

      test('should handle deletion of old receipt', () async {
        const oldReceiptId = 'receipt-2020-01-01-legacy';

        when(mockRepository.deleteReceipt(oldReceiptId))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: oldReceiptId);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, bool>>());
        verify(mockRepository.deleteReceipt(oldReceiptId)).called(1);
      });

      test('should handle attempt to delete non-existent receipt', () async {
        const nonExistentId = 'does-not-exist-123';
        const failure = NotFoundFailure();

        when(mockRepository.deleteReceipt(nonExistentId))
            .thenAnswer((_) async => const Left(failure));

        final params = ReceiptDeleteParams(id: nonExistentId);
        final result = await useCase.call(params);

        expect(result, isA<Left<Failure, bool>>());
        expect(result.fold((f) => f, (_) => null), isA<NotFoundFailure>());
        verify(mockRepository.deleteReceipt(nonExistentId)).called(1);
      });

      test('should handle deletion of receipt with complex UUID', () async {
        const uuidReceiptId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

        when(mockRepository.deleteReceipt(uuidReceiptId))
            .thenAnswer((_) async => const Right(true));

        final params = ReceiptDeleteParams(id: uuidReceiptId);
        final result = await useCase.call(params);

        expect(result, isA<Right<Failure, bool>>());
        verify(mockRepository.deleteReceipt(uuidReceiptId)).called(1);
      });
    });
  });

  group('ReceiptDeleteParams', () {
    test('should create params with required id', () {
      const testId = 'test-receipt-id';
      final params = ReceiptDeleteParams(id: testId);

      expect(params.id, equals(testId));
    });

    test('should handle empty string id', () {
      const emptyId = '';
      final params = ReceiptDeleteParams(id: emptyId);

      expect(params.id, equals(emptyId));
    });

    test('should handle special characters in id', () {
      const specialId = 'receipt@123#\$%^&*()';
      final params = ReceiptDeleteParams(id: specialId);

      expect(params.id, equals(specialId));
    });

    test('should preserve exact id value', () {
      const originalId = '  spaces-and-tabs\t\n  ';
      final params = ReceiptDeleteParams(id: originalId);

      expect(params.id, equals(originalId));
    });
  });
}
