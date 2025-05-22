import 'package:dartz/dartz.dart';
import 'package:domain/model/category_with_items.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/get_categories_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../utils/test_data_factory.dart';
import 'get_autocomplete_suggestions_use_case_test.mocks.dart';

@GenerateMocks([ReceiptRepository])
void main() {
  late GetCategoriesUseCase useCase;
  late MockReceiptRepository mockRepository;

  setUp(() {
    mockRepository = MockReceiptRepository();
    useCase = GetCategoriesUseCase(mockRepository);
  });

  group('GetCategoriesUseCase', () {
    test('should get categories from the repository', () async {
      final testCategories = TestDataFactory.createCategoriesWithItems();
      final expectedSortedCategories =
          TestDataFactory.createCategoriesWithItemsSorted();

      when(mockRepository.getCategories()).thenAnswer(
          (_) async => Right<Failure, List<CategoryWithItems>>(testCategories));

      final result = await useCase(const NoParams());

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []), expectedSortedCategories);
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should sort items by amount in descending order', () async {
      final unsortedCategories =
          TestDataFactory.createCategoriesWithUnsortedItems();
      final expectedSortedCategories =
          TestDataFactory.createCategoriesWithSortedItems();

      when(mockRepository.getCategories()).thenAnswer((_) async =>
          Right<Failure, List<CategoryWithItems>>(unsortedCategories));

      final result = await useCase(const NoParams());

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []), expectedSortedCategories);
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should maintain original category order while sorting items',
        () async {
      final testCategories = [
        TestDataFactory.createSingleCategoryWithItems(
          id: 'cat1',
          name: 'First Category',
          items: [
            TestDataFactory.createCategoryItem(
                id: 'item1', name: 'Low', amount: 10.0, count: 1),
            TestDataFactory.createCategoryItem(
                id: 'item2', name: 'High', amount: 100.0, count: 3),
            TestDataFactory.createCategoryItem(
                id: 'item3', name: 'Medium', amount: 50.0, count: 2),
          ],
        ),
        TestDataFactory.createSingleCategoryWithItems(
          id: 'cat2',
          name: 'Second Category',
          items: [
            TestDataFactory.createCategoryItem(
                id: 'item4', name: 'Small', amount: 5.0, count: 1),
            TestDataFactory.createCategoryItem(
                id: 'item5', name: 'Large', amount: 200.0, count: 1),
          ],
        ),
      ];

      when(mockRepository.getCategories()).thenAnswer(
          (_) async => Right<Failure, List<CategoryWithItems>>(testCategories));

      final result = await useCase(const NoParams());

      result.fold(
        (failure) => fail('Expected success but got failure'),
        (categories) {
          expect(categories.length, 2);
          expect(categories[0].name, 'First Category');
          expect(categories[1].name, 'Second Category');

          expect(categories[0].items[0].amount, 100.0);
          expect(categories[0].items[1].amount, 50.0);
          expect(categories[0].items[2].amount, 10.0);

          expect(categories[1].items[0].amount, 200.0);
          expect(categories[1].items[1].amount, 5.0);
        },
      );
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle categories with no items', () async {
      final categoriesWithNoItems = [
        TestDataFactory.createSingleCategoryWithItems(
          id: 'empty-cat',
          name: 'Empty Category',
          items: [],
        ),
      ];

      when(mockRepository.getCategories()).thenAnswer((_) async =>
          Right<Failure, List<CategoryWithItems>>(categoriesWithNoItems));

      final result = await useCase(const NoParams());

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []), categoriesWithNoItems);
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle categories with single item', () async {
      final singleItemCategories = [
        TestDataFactory.createSingleCategoryWithItems(
          id: 'single-cat',
          name: 'Single Item Category',
          items: [
            TestDataFactory.createCategoryItem(
                id: 'only-item', name: 'Only Item', amount: 42.0, count: 1)
          ],
        ),
      ];

      when(mockRepository.getCategories()).thenAnswer((_) async =>
          Right<Failure, List<CategoryWithItems>>(singleItemCategories));

      final result = await useCase(const NoParams());

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []), singleItemCategories);
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle items with identical amounts', () async {
      final identicalAmountCategories = [
        TestDataFactory.createSingleCategoryWithItems(
          id: 'identical-cat',
          name: 'Identical Amounts',
          items: [
            TestDataFactory.createCategoryItem(
                id: 'item-a', name: 'Item A', amount: 50.0, count: 1),
            TestDataFactory.createCategoryItem(
                id: 'item-b', name: 'Item B', amount: 50.0, count: 2),
            TestDataFactory.createCategoryItem(
                id: 'item-c', name: 'Item C', amount: 50.0, count: 3),
          ],
        ),
      ];

      when(mockRepository.getCategories()).thenAnswer((_) async =>
          Right<Failure, List<CategoryWithItems>>(identicalAmountCategories));

      final result = await useCase(const NoParams());

      result.fold(
        (failure) => fail('Expected success but got failure'),
        (categories) {
          expect(categories.length, 1);
          expect(categories[0].items.length, 3);
          for (final item in categories[0].items) {
            expect(item.amount, 50.0);
          }
        },
      );
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when repository returns empty list',
        () async {
      when(mockRepository.getCategories()).thenAnswer((_) async =>
          const Right<Failure, List<CategoryWithItems>>(<CategoryWithItems>[]));

      final result = await useCase(const NoParams());

      expect(result.isRight(), true);
      expect(result.getOrElse(() => []), <CategoryWithItems>[]);
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository returns ServerFailure',
        () async {
      const failure = ServerFailure('Server error occurred');

      when(mockRepository.getCategories()).thenAnswer(
          (_) async => const Left<Failure, List<CategoryWithItems>>(failure));

      final result = await useCase(const NoParams());

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), failure);
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return ConnectionFailure when repository returns ConnectionFailure',
        () async {
      const failure = ConnectionFailure();

      when(mockRepository.getCategories()).thenAnswer(
          (_) async => const Left<Failure, List<CategoryWithItems>>(failure));

      final result = await useCase(const NoParams());

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), failure);
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return UnauthorizedFailure when repository returns UnauthorizedFailure',
        () async {
      const failure = UnauthorizedFailure();

      when(mockRepository.getCategories()).thenAnswer(
          (_) async => const Left<Failure, List<CategoryWithItems>>(failure));

      final result = await useCase(const NoParams());

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), failure);
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return NotFoundFailure when repository returns NotFoundFailure',
        () async {
      const failure = NotFoundFailure();

      when(mockRepository.getCategories()).thenAnswer(
          (_) async => const Left<Failure, List<CategoryWithItems>>(failure));

      final result = await useCase(const NoParams());

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), failure);
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return ValidationFailure when repository returns ValidationFailure',
        () async {
      const failure = ValidationFailure([
        {'field': 'categories', 'message': 'Invalid data'}
      ]);

      when(mockRepository.getCategories()).thenAnswer(
          (_) async => const Left<Failure, List<CategoryWithItems>>(failure));

      final result = await useCase(const NoParams());

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), failure);
      verify(mockRepository.getCategories());
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
