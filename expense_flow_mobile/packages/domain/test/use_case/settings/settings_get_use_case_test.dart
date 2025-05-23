import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/settings_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/settings/settings_get_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../utils/test_data_factory.dart';
import 'settings_get_savings_use_case_test.mocks.dart';

@GenerateMocks([SettingsRepository])
void main() {
  late SettingsGetUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = SettingsGetUseCase(mockRepository);
  });

  group('SettingsGetUseCase', () {
    test('should return settings when repository succeeds', () async {
      final settings = TestDataFactory.createSettings();
      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      final result = await useCase.call(NoParams());

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualSettings) => expect(actualSettings, settings),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test('should return empty settings when repository returns empty settings',
        () async {
      final emptySettings = TestDataFactory.createEmptySettings();
      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(emptySettings));

      final result = await useCase.call(NoParams());

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualSettings) => expect(actualSettings, emptySettings),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test(
        'should return settings with null savingsSettings when repository returns null',
        () async {
      final settingsWithNull = TestDataFactory.createSettingsWithNullSavings();
      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settingsWithNull));

      final result = await useCase.call(NoParams());

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualSettings) => expect(actualSettings, settingsWithNull),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test('should return server failure when repository fails with server error',
        () async {
      const failure = ServerFailure('Server error occurred');
      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase.call(NoParams());

      result.fold(
        (actualFailure) => expect(actualFailure, failure),
        (settings) => fail('Expected failure but got success: $settings'),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test(
        'should return connection failure when repository fails with connection error',
        () async {
      const failure = ConnectionFailure();
      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase.call(NoParams());

      result.fold(
        (actualFailure) => expect(actualFailure, failure),
        (settings) => fail('Expected failure but got success: $settings'),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test(
        'should return unauthorized failure when repository fails with unauthorized error',
        () async {
      const failure = UnauthorizedFailure();
      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase.call(NoParams());

      result.fold(
        (actualFailure) => expect(actualFailure, failure),
        (settings) => fail('Expected failure but got success: $settings'),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test(
        'should return not found failure when repository fails with not found error',
        () async {
      const failure = NotFoundFailure();
      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase.call(NoParams());

      result.fold(
        (actualFailure) => expect(actualFailure, failure),
        (settings) => fail('Expected failure but got success: $settings'),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test(
        'should return validation failure when repository fails with validation error',
        () async {
      const failure = ValidationFailure([
        {'field': 'savingsAmount', 'error': 'must be positive'},
        {'field': 'income', 'error': 'required field'},
      ]);
      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase.call(NoParams());

      result.fold(
        (actualFailure) => expect(actualFailure, failure),
        (settings) => fail('Expected failure but got success: $settings'),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test('should handle multiple consecutive calls correctly', () async {
      final settings1 = TestDataFactory.createSettings();
      final settings2 = TestDataFactory.createEmptySettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings1));

      final result1 = await useCase.call(NoParams());

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings2));

      final result2 = await useCase.call(NoParams());

      result1.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualSettings) => expect(actualSettings, settings1),
      );

      result2.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualSettings) => expect(actualSettings, settings2),
      );

      verify(mockRepository.getSettings()).called(2);
    });

    test('should handle repository throwing exception', () async {
      when(mockRepository.getSettings())
          .thenThrow(Exception('Unexpected error'));

      expect(
        () => useCase.call(NoParams()),
        throwsA(isA<Exception>()),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test('should pass NoParams correctly to repository call', () async {
      final settings = TestDataFactory.createSettings();
      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      await useCase.call(NoParams());

      verify(mockRepository.getSettings()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should preserve settings data integrity', () async {
      final originalSettings = TestDataFactory.createSettings(
        savingsSettings: TestDataFactory.createSavingsSettingsList(),
      );
      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(originalSettings));

      final result = await useCase.call(NoParams());

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualSettings) {
          expect(actualSettings.savingsSettings?.length,
              originalSettings.savingsSettings?.length);

          if (actualSettings.savingsSettings != null &&
              originalSettings.savingsSettings != null) {
            for (int i = 0; i < actualSettings.savingsSettings!.length; i++) {
              final actual = actualSettings.savingsSettings![i];
              final expected = originalSettings.savingsSettings![i];

              expect(actual.month, expected.month);
              expect(actual.year, expected.year);
              expect(actual.savingsAmount, expected.savingsAmount);
              expect(actual.income, expected.income);
            }
          }
        },
      );
      verify(mockRepository.getSettings()).called(1);
    });
  });
}
