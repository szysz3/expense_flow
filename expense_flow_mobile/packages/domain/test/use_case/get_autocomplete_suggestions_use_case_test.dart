import 'package:dartz/dartz.dart';
import 'package:domain/model/autocomplete_suggestion.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/get_autocomplete_suggestions_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../utils/test_data_factory.dart';
import 'get_autocomplete_suggestions_use_case_test.mocks.dart';

@GenerateMocks([ReceiptRepository])
void main() {
  late GetAutocompleteSuggestionsUseCase useCase;
  late MockReceiptRepository mockRepository;

  setUp(() {
    mockRepository = MockReceiptRepository();
    useCase = GetAutocompleteSuggestionsUseCase(mockRepository);
  });

  group('GetAutocompleteSuggestionsUseCase', () {
    test('should get autocomplete suggestions from the repository', () async {
      final params = GetAutocompleteSuggestionsParams(text: 'gro');
      final testSuggestions = TestDataFactory.createAutocompleteSuggestions();

      when(mockRepository.getAutocompleteSuggestions(params.text,
              limit: params.limit))
          .thenAnswer((_) async => Right(testSuggestions));

      final result = await useCase(params);

      expect(result, Right(testSuggestions));
      verify(mockRepository.getAutocompleteSuggestions(params.text,
          limit: params.limit));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when text is empty', () async {
      final params = GetAutocompleteSuggestionsParams(text: '');

      final result = await useCase(params);

      expect(result, const Right(<AutocompleteSuggestion>[]));
      verifyNever(mockRepository.getAutocompleteSuggestions(any,
          limit: anyNamed('limit')));
    });

    test('should return empty list when text contains only whitespace',
        () async {
      final params = GetAutocompleteSuggestionsParams(text: '   ');

      final result = await useCase(params);

      expect(result, const Right(<AutocompleteSuggestion>[]));
      verifyNever(mockRepository.getAutocompleteSuggestions(any,
          limit: anyNamed('limit')));
    });

    test('should use custom limit when provided', () async {
      final params = GetAutocompleteSuggestionsParams(text: 'food', limit: 5);
      final testSuggestions =
          TestDataFactory.createAutocompleteSuggestions(count: 5);

      when(mockRepository.getAutocompleteSuggestions(params.text,
              limit: params.limit))
          .thenAnswer((_) async => Right(testSuggestions));

      final result = await useCase(params);

      expect(result, Right(testSuggestions));
      verify(mockRepository.getAutocompleteSuggestions(params.text, limit: 5));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should use default limit when not provided', () async {
      final params = GetAutocompleteSuggestionsParams(text: 'shop');
      final testSuggestions = TestDataFactory.createAutocompleteSuggestions();

      when(mockRepository.getAutocompleteSuggestions(params.text, limit: 8))
          .thenAnswer((_) async => Right(testSuggestions));

      final result = await useCase(params);

      expect(result, Right(testSuggestions));
      verify(mockRepository.getAutocompleteSuggestions(params.text, limit: 8));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return empty list when repository returns empty list',
        () async {
      final params = GetAutocompleteSuggestionsParams(text: 'nonexistent');

      when(mockRepository.getAutocompleteSuggestions(params.text,
              limit: params.limit))
          .thenAnswer((_) async => const Right([]));

      final result = await useCase(params);

      expect(result, const Right(<AutocompleteSuggestion>[]));
      verify(mockRepository.getAutocompleteSuggestions(params.text,
          limit: params.limit));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository returns ServerFailure',
        () async {
      final params = GetAutocompleteSuggestionsParams(text: 'test');
      const failure = ServerFailure('Server error occurred');

      when(mockRepository.getAutocompleteSuggestions(params.text,
              limit: params.limit))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params);

      expect(result, const Left(failure));
      verify(mockRepository.getAutocompleteSuggestions(params.text,
          limit: params.limit));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return ConnectionFailure when repository returns ConnectionFailure',
        () async {
      final params = GetAutocompleteSuggestionsParams(text: 'test');
      const failure = ConnectionFailure();

      when(mockRepository.getAutocompleteSuggestions(params.text,
              limit: params.limit))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params);

      expect(result, const Left(failure));
      verify(mockRepository.getAutocompleteSuggestions(params.text,
          limit: params.limit));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return UnauthorizedFailure when repository returns UnauthorizedFailure',
        () async {
      final params = GetAutocompleteSuggestionsParams(text: 'test');
      const failure = UnauthorizedFailure();

      when(mockRepository.getAutocompleteSuggestions(params.text,
              limit: params.limit))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params);

      expect(result, const Left(failure));
      verify(mockRepository.getAutocompleteSuggestions(params.text,
          limit: params.limit));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return NotFoundFailure when repository returns NotFoundFailure',
        () async {
      final params = GetAutocompleteSuggestionsParams(text: 'test');
      const failure = NotFoundFailure();

      when(mockRepository.getAutocompleteSuggestions(params.text,
              limit: params.limit))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params);

      expect(result, const Left(failure));
      verify(mockRepository.getAutocompleteSuggestions(params.text,
          limit: params.limit));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return ValidationFailure when repository returns ValidationFailure',
        () async {
      final params = GetAutocompleteSuggestionsParams(text: 'test');
      const failure = ValidationFailure([
        {'field': 'text', 'message': 'Invalid input'}
      ]);

      when(mockRepository.getAutocompleteSuggestions(params.text,
              limit: params.limit))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params);

      expect(result, const Left(failure));
      verify(mockRepository.getAutocompleteSuggestions(params.text,
          limit: params.limit));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should trim whitespace from text before checking if empty', () async {
      final params = GetAutocompleteSuggestionsParams(text: '  test  ');
      final testSuggestions = TestDataFactory.createAutocompleteSuggestions();

      when(mockRepository.getAutocompleteSuggestions('  test  ',
              limit: params.limit))
          .thenAnswer((_) async => Right(testSuggestions));

      final result = await useCase(params);

      expect(result, Right(testSuggestions));
      verify(mockRepository.getAutocompleteSuggestions('  test  ',
          limit: params.limit));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
