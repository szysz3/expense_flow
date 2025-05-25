import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/receipt/receipt_create_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../utils/test_data_factory.dart';
import '../get_autocomplete_suggestions_use_case_test.mocks.dart';

@GenerateMocks([ReceiptRepository])
void main() {
  late ReceiptCreateUseCase useCase;
  late MockReceiptRepository mockRepository;

  setUp(() {
    mockRepository = MockReceiptRepository();
    useCase = ReceiptCreateUseCase(mockRepository);
  });

  group('ReceiptCreateUseCase', () {
    final testReceiptItem = TestDataFactory.createReceiptItem(
      description: 'Test Coffee',
      quantity: 2.0,
      totalPrice: 8.50,
      category: 'Food & Dining',
    );

    final testReceipt = TestDataFactory.createReceipt(
      id: 'created-receipt-id',
      total: 8.50,
      transactionDateTime: DateTime(2023, 12, 15, 14, 30),
      addedDateTime: DateTime(2023, 12, 15, 15, 0),
    );

    group('successful creation', () {
      test('should return receipt when repository call succeeds', () async {
        when(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .thenAnswer((_) async => Right(testReceipt));

        final result = await useCase.call(testReceiptItem);

        expect(result, isA<Right<Failure, Receipt>>());
        expect(result.fold((_) => null, (receipt) => receipt),
            equals(testReceipt));
        verify(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .called(1);
      });

      test('should handle receipt item with all fields populated', () async {
        final fullReceiptItem = TestDataFactory.createReceiptItem(
          description: 'Premium Coffee Beans',
          quantity: 1.5,
          totalPrice: 24.99,
          category: 'Groceries',
        );

        final expectedReceipt = TestDataFactory.createReceipt(
          id: 'full-receipt-id',
          total: 24.99,
        );

        when(mockRepository.createReceipt(receiptItem: fullReceiptItem))
            .thenAnswer((_) async => Right(expectedReceipt));

        final result = await useCase.call(fullReceiptItem);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: fullReceiptItem))
            .called(1);
      });

      test('should handle receipt item with null category', () async {
        final receiptItemWithoutCategory = TestDataFactory.createReceiptItem(
          description: 'Mystery Item',
          quantity: 1.0,
          totalPrice: 15.00,
          category: null,
        );

        when(mockRepository.createReceipt(
                receiptItem: receiptItemWithoutCategory))
            .thenAnswer((_) async => Right(testReceipt));

        final result = await useCase.call(receiptItemWithoutCategory);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.createReceipt(
                receiptItem: receiptItemWithoutCategory))
            .called(1);
      });

      test('should handle receipt item with decimal quantities', () async {
        final decimalQuantityItem = TestDataFactory.createReceiptItem(
          description: 'Bulk Rice',
          quantity: 2.75,
          totalPrice: 13.45,
          category: 'Groceries',
        );

        when(mockRepository.createReceipt(receiptItem: decimalQuantityItem))
            .thenAnswer((_) async => Right(testReceipt));

        final result = await useCase.call(decimalQuantityItem);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: decimalQuantityItem))
            .called(1);
      });
    });

    group('failed creation', () {
      test('should return ServerFailure when repository returns server error',
          () async {
        const failure = ServerFailure('Failed to create receipt on server');
        when(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(testReceiptItem);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .called(1);
      });

      test(
          'should return ConnectionFailure when repository returns connection error',
          () async {
        const failure = ConnectionFailure();
        when(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(testReceiptItem);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .called(1);
      });

      test(
          'should return UnauthorizedFailure when repository returns unauthorized error',
          () async {
        const failure = UnauthorizedFailure();
        when(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(testReceiptItem);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .called(1);
      });

      test('should return ValidationFailure when validation fails', () async {
        const failure = ValidationFailure([
          {'field': 'description', 'error': 'Description cannot be empty'},
          {'field': 'totalPrice', 'error': 'Total price must be positive'}
        ]);
        when(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(testReceiptItem);

        expect(result, isA<Left<Failure, Receipt>>());
        expect(result.fold((f) => f, (_) => null), equals(failure));
        verify(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .called(1);
      });
    });

    group('parameter validation', () {
      test('should handle empty description', () async {
        final emptyDescriptionItem = TestDataFactory.createReceiptItem(
          description: '',
          quantity: 1.0,
          totalPrice: 5.00,
          category: 'Test',
        );

        const failure = ValidationFailure([
          {'field': 'description', 'error': 'Description cannot be empty'}
        ]);

        when(mockRepository.createReceipt(receiptItem: emptyDescriptionItem))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(emptyDescriptionItem);

        expect(result, isA<Left<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: emptyDescriptionItem))
            .called(1);
      });

      test('should handle zero quantity', () async {
        final zeroQuantityItem = TestDataFactory.createReceiptItem(
          description: 'Zero Item',
          quantity: 0.0,
          totalPrice: 0.0,
          category: 'Test',
        );

        const failure = ValidationFailure([
          {'field': 'quantity', 'error': 'Quantity must be greater than zero'}
        ]);

        when(mockRepository.createReceipt(receiptItem: zeroQuantityItem))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(zeroQuantityItem);

        expect(result, isA<Left<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: zeroQuantityItem))
            .called(1);
      });

      test('should handle negative total price', () async {
        final negativePrice = TestDataFactory.createReceiptItem(
          description: 'Negative Item',
          quantity: 1.0,
          totalPrice: -5.00,
          category: 'Test',
        );

        const failure = ValidationFailure([
          {'field': 'totalPrice', 'error': 'Total price cannot be negative'}
        ]);

        when(mockRepository.createReceipt(receiptItem: negativePrice))
            .thenAnswer((_) async => const Left(failure));

        final result = await useCase.call(negativePrice);

        expect(result, isA<Left<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: negativePrice))
            .called(1);
      });

      test('should handle very large values', () async {
        final largeValueItem = TestDataFactory.createReceiptItem(
          description: 'Expensive Item',
          quantity: 999999.99,
          totalPrice: 999999999.99,
          category: 'Luxury',
        );

        when(mockRepository.createReceipt(receiptItem: largeValueItem))
            .thenAnswer((_) async => Right(testReceipt));

        final result = await useCase.call(largeValueItem);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: largeValueItem))
            .called(1);
      });
    });

    group('edge cases', () {
      test('should handle repository throwing exception', () async {
        when(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .thenThrow(Exception('Unexpected error'));

        expect(
          () async => await useCase.call(testReceiptItem),
          throwsException,
        );
      });

      test('should handle very long description', () async {
        final longDescriptionItem = TestDataFactory.createReceiptItem(
          description: 'Very long description ${'a' * 1000}',
          quantity: 1.0,
          totalPrice: 10.00,
          category: 'Test',
        );

        when(mockRepository.createReceipt(receiptItem: longDescriptionItem))
            .thenAnswer((_) async => Right(testReceipt));

        final result = await useCase.call(longDescriptionItem);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: longDescriptionItem))
            .called(1);
      });

      test('should handle special characters in description', () async {
        final specialCharsItem = TestDataFactory.createReceiptItem(
          description: 'Special chars: @#\$%^&*()_+-=[]{}|;:,.<>?',
          quantity: 1.0,
          totalPrice: 15.99,
          category: 'Special',
        );

        when(mockRepository.createReceipt(receiptItem: specialCharsItem))
            .thenAnswer((_) async => Right(testReceipt));

        final result = await useCase.call(specialCharsItem);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: specialCharsItem))
            .called(1);
      });

      test('should handle unicode characters in description', () async {
        final unicodeItem = TestDataFactory.createReceiptItem(
          description: 'Unicode: 🍕🍔🍟☕️💰',
          quantity: 1.0,
          totalPrice: 25.50,
          category: 'Food & Dining',
        );

        when(mockRepository.createReceipt(receiptItem: unicodeItem))
            .thenAnswer((_) async => Right(testReceipt));

        final result = await useCase.call(unicodeItem);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: unicodeItem))
            .called(1);
      });

      test('should handle very small decimal values', () async {
        final smallDecimalItem = TestDataFactory.createReceiptItem(
          description: 'Tiny Item',
          quantity: 0.001,
          totalPrice: 0.01,
          category: 'Test',
        );

        when(mockRepository.createReceipt(receiptItem: smallDecimalItem))
            .thenAnswer((_) async => Right(testReceipt));

        final result = await useCase.call(smallDecimalItem);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: smallDecimalItem))
            .called(1);
      });
    });

    group('different categories', () {
      final categories = [
        'Food & Dining',
        'Groceries',
        'Transportation',
        'Entertainment',
        'Health & Medical',
        'Shopping',
        'Utilities',
        null,
      ];

      for (final category in categories) {
        test('should handle category: ${category ?? 'null'}', () async {
          final categoryItem = TestDataFactory.createReceiptItem(
            description: 'Category Test Item',
            quantity: 1.0,
            totalPrice: 10.00,
            category: category,
          );

          when(mockRepository.createReceipt(receiptItem: categoryItem))
              .thenAnswer((_) async => Right(testReceipt));

          final result = await useCase.call(categoryItem);

          expect(result, isA<Right<Failure, Receipt>>());
          verify(mockRepository.createReceipt(receiptItem: categoryItem))
              .called(1);
        });
      }
    });

    group('use case contract', () {
      test('should implement BaseUseCase interface correctly', () {
        expect(
            useCase, isA<BaseUseCase<ReceiptItem, Either<Failure, Receipt>>>());
      });

      test('should call repository method exactly once per invocation',
          () async {
        when(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .thenAnswer((_) async => Right(testReceipt));

        await useCase.call(testReceiptItem);
        await useCase.call(testReceiptItem);
        await useCase.call(testReceiptItem);

        verify(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .called(3);
      });

      test('should pass exact same ReceiptItem instance to repository',
          () async {
        when(mockRepository.createReceipt(receiptItem: testReceiptItem))
            .thenAnswer((_) async => Right(testReceipt));

        await useCase.call(testReceiptItem);

        final captured = verify(mockRepository.createReceipt(
                receiptItem: captureAnyNamed('receiptItem')))
            .captured;
        expect(captured.single, same(testReceiptItem));
      });
    });

    group('realistic scenarios', () {
      test('should handle typical grocery item', () async {
        final groceryItem = TestDataFactory.createReceiptItem(
          description: 'Organic Bananas',
          quantity: 2.5,
          totalPrice: 4.99,
          category: 'Groceries',
        );

        final expectedReceipt = TestDataFactory.createReceipt(
          id: 'grocery-receipt-id',
          total: 4.99,
        );

        when(mockRepository.createReceipt(receiptItem: groceryItem))
            .thenAnswer((_) async => Right(expectedReceipt));

        final result = await useCase.call(groceryItem);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: groceryItem))
            .called(1);
      });

      test('should handle restaurant bill item', () async {
        final restaurantItem = TestDataFactory.createReceiptItem(
          description: 'Dinner for Two',
          quantity: 1.0,
          totalPrice: 67.50,
          category: 'Food & Dining',
        );

        final expectedReceipt = TestDataFactory.createReceipt(
          id: 'restaurant-receipt-id',
          total: 67.50,
        );

        when(mockRepository.createReceipt(receiptItem: restaurantItem))
            .thenAnswer((_) async => Right(expectedReceipt));

        final result = await useCase.call(restaurantItem);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: restaurantItem))
            .called(1);
      });

      test('should handle gas station purchase', () async {
        final gasItem = TestDataFactory.createReceiptItem(
          description: 'Regular Gasoline',
          quantity: 12.5,
          totalPrice: 45.75,
          category: 'Transportation',
        );

        final expectedReceipt = TestDataFactory.createReceipt(
          id: 'gas-receipt-id',
          total: 45.75,
        );

        when(mockRepository.createReceipt(receiptItem: gasItem))
            .thenAnswer((_) async => Right(expectedReceipt));

        final result = await useCase.call(gasItem);

        expect(result, isA<Right<Failure, Receipt>>());
        verify(mockRepository.createReceipt(receiptItem: gasItem)).called(1);
      });
    });
  });
}
