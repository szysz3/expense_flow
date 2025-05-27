import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/receipt/receipt_update_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../utils/test_data_factory.dart';
import '../get_autocomplete_suggestions_use_case_test.mocks.dart';

@GenerateMocks([ReceiptRepository])
void main() {
  late ReceiptUpdateUseCase useCase;
  late MockReceiptRepository mockRepository;

  setUp(() {
    mockRepository = MockReceiptRepository();
    useCase = ReceiptUpdateUseCase(mockRepository);
  });

  group('ReceiptUpdateUseCase', () {
    final testReceipt = TestDataFactory.createReceipt(
      id: 'existing-receipt-id',
      total: 89.50,
      transactionDateTime: DateTime(2023, 12, 10, 15, 30),
      addedDateTime: DateTime(2023, 12, 10, 16, 0),
    );

    final updatedReceipt = TestDataFactory.createReceipt(
      id: 'existing-receipt-id',
      total: 95.75,
      transactionDateTime: DateTime(2023, 12, 10, 15, 30),
      addedDateTime: DateTime(2023, 12, 15, 10, 30), // Updated timestamp
    );

    group('successful update', () {
      test('should return updated receipt when repository call succeeds',
          () async {
        when(mockRepository.updateReceipt(testReceipt))
            .thenAnswer((_) async => Right(updatedReceipt));

        final result = await useCase.call(testReceipt);

        expect(result, isA<Right<Failure, Receipt>>());
        expect(result.fold((_) => null, (receipt) => receipt),
            equals(updatedReceipt));
        verify(mockRepository.updateReceipt(testReceipt)).called(1);
      });

      test('should handle receipt with all fields updated', () async {
        final originalReceipt = TestDataFactory.createReceipt(
          id: 'receipt-123',
          merchant: TestDataFactory.createMerchant(
              name: 'Old Store', address: '123 Old St'),
          items: [
            TestDataFactory.createReceiptItem(
                description: 'Old Item', totalPrice: 10.0),
          ],
          total: 10.0,
          transactionDateTime: DateTime(2023, 12, 1, 10, 0),
          addedDateTime: DateTime(2023, 12, 1, 11, 0),
        );

        final fullyUpdatedReceipt = TestDataFactory.createReceipt(
          id: 'receipt-123',
          merchant: TestDataFactory.createMerchant(
              name: 'New Store', address: '456 New Ave'),
          items: [
            TestDataFactory.createReceiptItem(
                description: 'New Item 1', totalPrice: 15.0),
            TestDataFactory.createReceiptItem(
                description: 'New Item 2', totalPrice: 25.0),
          ],
          total: 40.0,
          transactionDateTime: DateTime(2023, 12, 2, 14, 30),
          addedDateTime: DateTime(2023, 12, 15, 12, 0),
        );

        when(mockRepository.updateReceipt(originalReceipt))
            .thenAnswer((_) async => Right(fullyUpdatedReceipt));

        final result = await useCase.call(originalReceipt);

        expect(result, isA<Right<Failure, Receipt>>());
        final resultReceipt = result.fold((_) => null, (r) => r)!;
        expect(resultReceipt.merchant.name, equals('New Store'));
        expect(resultReceipt.items.length, equals(2));
        expect(resultReceipt.total, equals(40.0));
        verify(mockRepository.updateReceipt(originalReceipt)).called(1);
      });

      test('should handle receipt with updated items only', () async {
        final receiptWithUpdatedItems = TestDataFactory.createReceipt(
          id: 'receipt-456',
          items: [
            TestDataFactory.createReceiptItem(
              description: 'Updated Coffee',
              quantity: 2.0,
              totalPrice: 8.50,
              category: 'Food & Dining',
            ),
            TestDataFactory.createReceiptItem(
              description: 'Added Pastry',
              quantity: 1.0,
              totalPrice: 4.25,
              category: 'Food & Dining',
            ),
          ],
          total: 12.75,
        );

        when(mockRepository.updateReceipt(receiptWithUpdatedItems))
            .thenAnswer((_) async => Right(receiptWithUpdatedItems));

        final result = await useCase.call(receiptWithUpdatedItems);

        expect(result, isA<Right<Failure, Receipt>>());
        final resultReceipt = result.fold((_) => null, (r) => r)!;
        expect(resultReceipt.items.length, equals(2));
        expect(resultReceipt.total, equals(12.75));
        verify(mockRepository.updateReceipt(receiptWithUpdatedItems)).called(1);
      });

      test('should handle receipt with updated total only', () async {
        final receiptWithUpdatedTotal = testReceipt.copyWith(total: 99.99);

        when(mockRepository.updateReceipt(receiptWithUpdatedTotal))
            .thenAnswer((_) async => Right(receiptWithUpdatedTotal));

        final result = await useCase.call(receiptWithUpdatedTotal);

        expect(result, isA<Right<Failure, Receipt>>());
        final resultReceipt = result.fold((_) => null, (r) => r)!;
        expect(resultReceipt.total, equals(99.99));
        verify(mockRepository.updateReceipt(receiptWithUpdatedTotal)).called(1);
      });

      test('should handle receipt with updated transaction datetime', () async {
        final newTransactionDateTime = DateTime(2023, 12, 20, 18, 45);
        final receiptWithUpdatedDateTime = testReceipt.copyWith(
          transactionDateTime: newTransactionDateTime,
        );

        when(mockRepository.updateReceipt(receiptWithUpdatedDateTime))
            .thenAnswer((_) async => Right(receiptWithUpdatedDateTime));

        final result = await useCase.call(receiptWithUpdatedDateTime);

        expect(result, isA<Right<Failure, Receipt>>());
        final resultReceipt = result.fold((_) => null, (r) => r)!;
        expect(
            resultReceipt.transactionDateTime, equals(newTransactionDateTime));
        verify(mockRepository.updateReceipt(receiptWithUpdatedDateTime))
            .called(1);
      });

      test('should handle receipt with null id', () async {
        final receiptWithoutId = TestDataFactory.createReceipt(
          id: null,
          total: 25.00,
        );

        final createdReceipt =
            receiptWithoutId.copyWith(id: 'newly-created-id');

        when(mockRepository.updateReceipt(receiptWithoutId))
            .thenAnswer((_) async => Right(createdReceipt));

        final result = await useCase.call(receiptWithoutId);

        expect(result, isA<Right<Failure, Receipt>>());
        final resultReceipt = result.fold((_) => null, (r) => r)!;
        expect(resultReceipt.id, equals('newly-created-id'));
        verify(mockRepository.updateReceipt(receiptWithoutId)).called(1);
      });
    });

    group('failed update', () {
      test('should return ServerFailure when repository returns server error',
          () async {
        const failure = ServerFailure('Failed to update receipt on server');
        when(mockRepository.updateReceipt(testReceipt))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(testReceipt);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.updateReceipt(testReceipt)).called(1);
      });

      test(
          'should return ConnectionFailure when repository returns connection error',
          () async {
        const failure = ConnectionFailure();
        when(mockRepository.updateReceipt(testReceipt))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(testReceipt);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.updateReceipt(testReceipt)).called(1);
      });

      test(
          'should return UnauthorizedFailure when repository returns unauthorized error',
          () async {
        const failure = UnauthorizedFailure();
        when(mockRepository.updateReceipt(testReceipt))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(testReceipt);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.updateReceipt(testReceipt)).called(1);
      });

      test('should return NotFoundFailure when receipt does not exist',
          () async {
        const failure = NotFoundFailure();
        when(mockRepository.updateReceipt(testReceipt))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(testReceipt);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.updateReceipt(testReceipt)).called(1);
      });

      test('should return ValidationFailure when validation fails', () async {
        const failure = ValidationFailure([
          {'field': 'total', 'error': 'Total must be greater than 0'},
          {'field': 'items', 'error': 'Receipt must have at least one item'}
        ]);
        when(mockRepository.updateReceipt(testReceipt))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(testReceipt);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.updateReceipt(testReceipt)).called(1);
      });
    });

    group('validation scenarios', () {
      test('should handle receipt with empty items list', () async {
        final receiptWithEmptyItems = TestDataFactory.createReceipt(
          id: 'receipt-empty-items',
          items: [],
          total: 0.0,
        );

        const failure = ValidationFailure([
          {'field': 'items', 'error': 'Receipt must have at least one item'}
        ]);

        when(mockRepository.updateReceipt(receiptWithEmptyItems))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(receiptWithEmptyItems);

        expect(result, isA<Left<Failure, Receipt>>());
        verify(mockRepository.updateReceipt(receiptWithEmptyItems)).called(1);
      });

      test('should handle receipt with negative total', () async {
        final receiptWithNegativeTotal = testReceipt.copyWith(total: -50.0);

        const failure = ValidationFailure([
          {'field': 'total', 'error': 'Total cannot be negative'}
        ]);

        when(mockRepository.updateReceipt(receiptWithNegativeTotal))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(receiptWithNegativeTotal);

        expect(result, isA<Left<Failure, Receipt>>());
        verify(mockRepository.updateReceipt(receiptWithNegativeTotal))
            .called(1);
      });

      test('should handle receipt with zero total', () async {
        final receiptWithZeroTotal = testReceipt.copyWith(total: 0.0);

        when(mockRepository.updateReceipt(receiptWithZeroTotal))
            .thenAnswer((_) async => Right(receiptWithZeroTotal));

        final result = await useCase.call(receiptWithZeroTotal);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.updateReceipt(receiptWithZeroTotal)).called(1);
      });

      test('should handle receipt with future transaction date', () async {
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final receiptWithFutureDate = testReceipt.copyWith(
          transactionDateTime: futureDate,
        );

        const failure = ValidationFailure([
          {
            'field': 'transactionDateTime',
            'error': 'Transaction date cannot be in the future'
          }
        ]);

        when(mockRepository.updateReceipt(receiptWithFutureDate))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(receiptWithFutureDate);

        expect(result, isA<Left<Failure, Receipt>>());
        verify(mockRepository.updateReceipt(receiptWithFutureDate)).called(1);
      });

      test('should handle receipt with very old transaction date', () async {
        final veryOldDate = DateTime(1900, 1, 1);
        final receiptWithOldDate = testReceipt.copyWith(
          transactionDateTime: veryOldDate,
        );

        when(mockRepository.updateReceipt(receiptWithOldDate))
            .thenAnswer((_) async => Right(receiptWithOldDate));

        final result = await useCase.call(receiptWithOldDate);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.updateReceipt(receiptWithOldDate)).called(1);
      });
    });

    group('edge cases', () {
      test('should handle repository throwing exception', () async {
        when(mockRepository.updateReceipt(testReceipt))
            .thenThrow(Exception('Unexpected error'));

        expect(
          () async => await useCase.call(testReceipt),
          throwsException,
        );
      });

      test('should handle receipt with very large total', () async {
        final receiptWithLargeTotal = testReceipt.copyWith(total: 999999999.99);

        when(mockRepository.updateReceipt(receiptWithLargeTotal))
            .thenAnswer((_) async => Right(receiptWithLargeTotal));

        final result = await useCase.call(receiptWithLargeTotal);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.updateReceipt(receiptWithLargeTotal)).called(1);
      });

      test('should handle receipt with many items', () async {
        final manyItems = List.generate(
          100,
          (index) => TestDataFactory.createReceiptItem(
            description: 'Item ${index + 1}',
            totalPrice: 1.0 + index,
          ),
        );

        final receiptWithManyItems = testReceipt.copyWith(
          items: manyItems,
          total: manyItems.fold(0.0, (sum, item) => sum + item.totalPrice),
        );

        when(mockRepository.updateReceipt(receiptWithManyItems))
            .thenAnswer((_) async => Right(receiptWithManyItems));

        final result = await useCase.call(receiptWithManyItems);

        expect(result, isA<Right<Failure, Receipt>>());
        final resultReceipt = result.fold((_) => null, (r) => r)!;
        expect(resultReceipt.items.length, equals(100));
        verify(mockRepository.updateReceipt(receiptWithManyItems)).called(1);
      });

      test('should handle receipt with very long merchant name', () async {
        final longMerchantName = 'Very Long Merchant Name ${'A' * 500}';
        final merchantWithLongName = TestDataFactory.createMerchant(
          name: longMerchantName,
        );
        final receiptWithLongMerchantName = testReceipt.copyWith(
          merchant: merchantWithLongName,
        );

        when(mockRepository.updateReceipt(receiptWithLongMerchantName))
            .thenAnswer((_) async => Right(receiptWithLongMerchantName));

        final result = await useCase.call(receiptWithLongMerchantName);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.updateReceipt(receiptWithLongMerchantName))
            .called(1);
      });

      test('should handle receipt with special characters in merchant address',
          () async {
        final specialAddress = '123 Main St. @#\$%^&*()_+-=[]{}|;:,.<>?';
        final merchantWithSpecialAddress = TestDataFactory.createMerchant(
          address: specialAddress,
        );
        final receiptWithSpecialAddress = testReceipt.copyWith(
          merchant: merchantWithSpecialAddress,
        );

        when(mockRepository.updateReceipt(receiptWithSpecialAddress))
            .thenAnswer((_) async => Right(receiptWithSpecialAddress));

        final result = await useCase.call(receiptWithSpecialAddress);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.updateReceipt(receiptWithSpecialAddress))
            .called(1);
      });

      test('should handle receipt with unicode characters', () async {
        final unicodeMerchant = TestDataFactory.createMerchant(
          name: 'Café ñoño 🍕🍔',
          address: '123 Ümlaut Strasse ñ',
        );
        final unicodeItem = TestDataFactory.createReceiptItem(
          description: 'Crème brûlée 🍮',
          totalPrice: 12.50,
        );
        final receiptWithUnicode = testReceipt.copyWith(
          merchant: unicodeMerchant,
          items: [unicodeItem],
          total: 12.50,
        );

        when(mockRepository.updateReceipt(receiptWithUnicode))
            .thenAnswer((_) async => Right(receiptWithUnicode));

        final result = await useCase.call(receiptWithUnicode);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.updateReceipt(receiptWithUnicode)).called(1);
      });

      test('should handle receipt with precise decimal values', () async {
        final preciseItem1 = TestDataFactory.createReceiptItem(
          description: 'Precise Item 1',
          totalPrice: 1.234567,
        );
        final preciseItem2 = TestDataFactory.createReceiptItem(
          description: 'Precise Item 2',
          totalPrice: 2.345678,
        );
        final receiptWithPreciseDecimals = testReceipt.copyWith(
          items: [preciseItem1, preciseItem2],
          total: 3.580245,
        );

        when(mockRepository.updateReceipt(receiptWithPreciseDecimals))
            .thenAnswer((_) async => Right(receiptWithPreciseDecimals));

        final result = await useCase.call(receiptWithPreciseDecimals);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.updateReceipt(receiptWithPreciseDecimals))
            .called(1);
      });
    });

    group('use case contract', () {
      test('should implement BaseUseCase interface correctly', () {
        expect(useCase, isA<BaseUseCase<Receipt, Either<Failure, Receipt>>>());
      });

      test('should call repository method exactly once per invocation',
          () async {
        when(mockRepository.updateReceipt(testReceipt))
            .thenAnswer((_) async => Right(updatedReceipt));

        await useCase.call(testReceipt);
        await useCase.call(testReceipt);
        await useCase.call(testReceipt);

        verify(mockRepository.updateReceipt(testReceipt)).called(3);
      });

      test('should pass exact same Receipt instance to repository', () async {
        when(mockRepository.updateReceipt(testReceipt))
            .thenAnswer((_) async => Right(updatedReceipt));

        await useCase.call(testReceipt);

        final captured =
            verify(mockRepository.updateReceipt(captureAny)).captured;
        expect(captured.single, same(testReceipt));
      });

      test('should handle concurrent update requests', () async {
        final receipts = [
          TestDataFactory.createReceipt(id: 'receipt-1', total: 10.0),
          TestDataFactory.createReceipt(id: 'receipt-2', total: 20.0),
          TestDataFactory.createReceipt(id: 'receipt-3', total: 30.0),
        ];

        for (final receipt in receipts) {
          when(mockRepository.updateReceipt(receipt))
              .thenAnswer((_) async => Right(receipt));
        }

        final futures = receipts.map((receipt) => useCase.call(receipt));
        final results = await Future.wait(futures);

        for (final result in results) {
          expect(result, isA<Right<Failure, Receipt>>());
        }

        for (final receipt in receipts) {
          verify(mockRepository.updateReceipt(receipt)).called(1);
        }
      });
    });

    group('realistic scenarios', () {
      test('should handle updating receipt after manual correction', () async {
        final originalReceipt = TestDataFactory.createReceipt(
          id: 'receipt-correction',
          items: [
            TestDataFactory.createReceiptItem(
              description: 'Coffe', // Typo
              totalPrice: 5.00,
            ),
          ],
          total: 5.00,
        );

        final correctedReceipt = originalReceipt.copyWith(
          items: [
            TestDataFactory.createReceiptItem(
              description: 'Coffee', // Fixed typo
              totalPrice: 5.00,
            ),
          ],
        );

        when(mockRepository.updateReceipt(correctedReceipt))
            .thenAnswer((_) async => Right(correctedReceipt));

        final result = await useCase.call(correctedReceipt);

        expect(result, isA<Right<Failure, Receipt>>());
        final resultReceipt = result.fold((_) => null, (r) => r)!;
        expect(resultReceipt.items.first.description, equals('Coffee'));
        verify(mockRepository.updateReceipt(correctedReceipt)).called(1);
      });

      test('should handle updating receipt with added items', () async {
        final originalReceipt = TestDataFactory.createReceipt(
          id: 'receipt-add-items',
          items: [
            TestDataFactory.createReceiptItem(
              description: 'Original Item',
              totalPrice: 10.00,
            ),
          ],
          total: 10.00,
        );

        final updatedReceipt = originalReceipt.copyWith(
          items: [
            TestDataFactory.createReceiptItem(
              description: 'Original Item',
              totalPrice: 10.00,
            ),
            TestDataFactory.createReceiptItem(
              description: 'Additional Item',
              totalPrice: 5.00,
            ),
          ],
          total: 15.00,
        );

        when(mockRepository.updateReceipt(updatedReceipt))
            .thenAnswer((_) async => Right(updatedReceipt));

        final result = await useCase.call(updatedReceipt);

        expect(result, isA<Right<Failure, Receipt>>());
        final resultReceipt = result.fold((_) => null, (r) => r)!;
        expect(resultReceipt.items.length, equals(2));
        expect(resultReceipt.total, equals(15.00));
        verify(mockRepository.updateReceipt(updatedReceipt)).called(1);
      });

      test('should handle updating receipt with removed items', () async {
        final originalReceipt = TestDataFactory.createReceipt(
          id: 'receipt-remove-items',
          items: [
            TestDataFactory.createReceiptItem(
              description: 'Keep Item',
              totalPrice: 10.00,
            ),
            TestDataFactory.createReceiptItem(
              description: 'Remove Item',
              totalPrice: 5.00,
            ),
          ],
          total: 15.00,
        );

        final updatedReceipt = originalReceipt.copyWith(
          items: [
            TestDataFactory.createReceiptItem(
              description: 'Keep Item',
              totalPrice: 10.00,
            ),
          ],
          total: 10.00,
        );

        when(mockRepository.updateReceipt(updatedReceipt))
            .thenAnswer((_) async => Right(updatedReceipt));

        final result = await useCase.call(updatedReceipt);

        expect(result, isA<Right<Failure, Receipt>>());
        final resultReceipt = result.fold((_) => null, (r) => r)!;
        expect(resultReceipt.items.length, equals(1));
        expect(resultReceipt.total, equals(10.00));
        verify(mockRepository.updateReceipt(updatedReceipt)).called(1);
      });

      test('should handle updating receipt merchant information', () async {
        final originalReceipt = TestDataFactory.createReceipt(
          id: 'receipt-merchant-update',
          merchant: TestDataFactory.createMerchant(
            name: 'Old Store Name',
            address: '123 Old Address',
          ),
        );

        final updatedReceipt = originalReceipt.copyWith(
          merchant: TestDataFactory.createMerchant(
            name: 'New Store Name',
            address: '456 New Address',
          ),
        );

        when(mockRepository.updateReceipt(updatedReceipt))
            .thenAnswer((_) async => Right(updatedReceipt));

        final result = await useCase.call(updatedReceipt);

        expect(result, isA<Right<Failure, Receipt>>());
        final resultReceipt = result.fold((_) => null, (r) => r)!;
        expect(resultReceipt.merchant.name, equals('New Store Name'));
        expect(resultReceipt.merchant.address, equals('456 New Address'));
        verify(mockRepository.updateReceipt(updatedReceipt)).called(1);
      });
    });
  });
}
