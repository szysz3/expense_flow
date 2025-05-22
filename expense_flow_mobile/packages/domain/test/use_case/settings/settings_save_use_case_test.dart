import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/settings.dart';
import 'package:domain/repository/settings_repository.dart';
import 'package:domain/use_case/settings/settings_save_savings_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../utils/test_data_factory.dart';
import 'settings_save_savings_use_case_test.mocks.dart';

@GenerateMocks([SettingsRepository])
void main() {
  late SettingsSaveSavingsUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = SettingsSaveSavingsUseCase(mockRepository);
  });

  group('SettingsSaveSavingsUseCase', () {
    test('should update existing savings settings for the same month and year',
        () async {
      // Arrange
      final existingSettings = TestDataFactory.createSettings();
      final newSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2023,
        savingsAmount: 700.0,
        income: 3500.0,
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(existingSettings));

      final expectedUpdatedSettings = Settings(
        savingsSettings: [
          newSavingsSettings, // Updated first entry
          TestDataFactory.createSavingsSettings(
              month: 2, income: 3200.0, savingsAmount: 600.0),
        ],
      );

      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => Right(expectedUpdatedSettings));

      // Act
      final result = await useCase.call(newSavingsSettings);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (settings) {
          expect(settings.savingsSettings?.length, 2);
          expect(settings.savingsSettings?.first.savingsAmount, 700.0);
          expect(settings.savingsSettings?.first.income, 3500.0);
          expect(settings.savingsSettings?.first.month, 1);
          expect(settings.savingsSettings?.first.year, 2023);
        },
      );

      verify(mockRepository.getSettings()).called(1);
      verify(mockRepository.saveSettings(any)).called(1);
    });

    test(
        'should add new savings settings when month/year combination not found',
        () async {
      // Arrange
      final existingSettings = TestDataFactory.createSettings();
      final newSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 3,
        year: 2023,
        savingsAmount: 800.0,
        income: 3300.0,
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(existingSettings));

      final expectedUpdatedSettings = Settings(
        savingsSettings: [
          TestDataFactory.createSavingsSettings(
              month: 1, income: 3000.0, savingsAmount: 500.0),
          TestDataFactory.createSavingsSettings(
              month: 2, income: 3200.0, savingsAmount: 600.0),
          newSavingsSettings, // Added new entry
        ],
      );

      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => Right(expectedUpdatedSettings));

      // Act
      final result = await useCase.call(newSavingsSettings);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (settings) {
          expect(settings.savingsSettings?.length, 3);
          expect(settings.savingsSettings?.last.savingsAmount, 800.0);
          expect(settings.savingsSettings?.last.income, 3300.0);
          expect(settings.savingsSettings?.last.month, 3);
          expect(settings.savingsSettings?.last.year, 2023);
        },
      );

      verify(mockRepository.getSettings()).called(1);
      verify(mockRepository.saveSettings(any)).called(1);
    });

    test('should handle empty savings settings list', () async {
      // Arrange
      final emptySettings = TestDataFactory.createEmptySettings();
      final newSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2023,
        savingsAmount: 500.0,
        income: 3000.0,
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(emptySettings));

      final expectedUpdatedSettings = Settings(
        savingsSettings: [newSavingsSettings],
      );

      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => Right(expectedUpdatedSettings));

      // Act
      final result = await useCase.call(newSavingsSettings);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (settings) {
          expect(settings.savingsSettings?.length, 1);
          expect(settings.savingsSettings?.first.savingsAmount, 500.0);
          expect(settings.savingsSettings?.first.income, 3000.0);
        },
      );

      verify(mockRepository.getSettings()).called(1);
      verify(mockRepository.saveSettings(any)).called(1);
    });

    test('should handle null savings settings list', () async {
      // Arrange
      final settingsWithNullSavings =
          TestDataFactory.createSettingsWithNullSavings();
      final newSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2023,
        savingsAmount: 500.0,
        income: 3000.0,
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settingsWithNullSavings));

      final expectedUpdatedSettings = Settings(
        savingsSettings: [newSavingsSettings],
      );

      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => Right(expectedUpdatedSettings));

      // Act
      final result = await useCase.call(newSavingsSettings);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (settings) {
          expect(settings.savingsSettings?.length, 1);
          expect(settings.savingsSettings?.first.savingsAmount, 500.0);
          expect(settings.savingsSettings?.first.income, 3000.0);
        },
      );

      verify(mockRepository.getSettings()).called(1);
      verify(mockRepository.saveSettings(any)).called(1);
    });

    test('should return failure when getSettings fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to get settings');
      final newSavingsSettings = TestDataFactory.createSavingsSettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase.call(newSavingsSettings);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, failure),
        (settings) => fail('Expected failure but got success: $settings'),
      );

      verify(mockRepository.getSettings()).called(1);
      verifyNever(mockRepository.saveSettings(any));
    });

    test('should return failure when saveSettings fails', () async {
      // Arrange
      final existingSettings = TestDataFactory.createSettings();
      final newSavingsSettings = TestDataFactory.createSavingsSettings();
      const saveFailure = ServerFailure('Failed to save settings');

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(existingSettings));
      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => const Left(saveFailure));

      // Act
      final result = await useCase.call(newSavingsSettings);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, saveFailure),
        (settings) => fail('Expected failure but got success: $settings'),
      );

      verify(mockRepository.getSettings()).called(1);
      verify(mockRepository.saveSettings(any)).called(1);
    });

    test('should return ConnectionFailure when connection fails', () async {
      // Arrange
      const failure = ConnectionFailure();
      final newSavingsSettings = TestDataFactory.createSavingsSettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase.call(newSavingsSettings);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (f) {
          expect(f, isA<ConnectionFailure>());
          expect(f.message,
              'Connection failed. Please check your internet connection.');
        },
        (settings) => fail('Expected failure but got success: $settings'),
      );

      verify(mockRepository.getSettings()).called(1);
      verifyNever(mockRepository.saveSettings(any));
    });

    test('should return UnauthorizedFailure when unauthorized', () async {
      // Arrange
      const failure = UnauthorizedFailure();
      final newSavingsSettings = TestDataFactory.createSavingsSettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase.call(newSavingsSettings);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (f) {
          expect(f, isA<UnauthorizedFailure>());
          expect(f.message, 'Unauthorized access');
        },
        (settings) => fail('Expected failure but got success: $settings'),
      );

      verify(mockRepository.getSettings()).called(1);
      verifyNever(mockRepository.saveSettings(any));
    });

    test('should return NotFoundFailure when resource not found', () async {
      // Arrange
      const failure = NotFoundFailure();
      final newSavingsSettings = TestDataFactory.createSavingsSettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase.call(newSavingsSettings);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (f) {
          expect(f, isA<NotFoundFailure>());
          expect(f.message, 'Resource not found');
        },
        (settings) => fail('Expected failure but got success: $settings'),
      );

      verify(mockRepository.getSettings()).called(1);
      verifyNever(mockRepository.saveSettings(any));
    });

    test('should return ValidationFailure when validation fails', () async {
      // Arrange
      const validationDetails = [
        {'field': 'savingsAmount', 'error': 'Must be positive'},
        {'field': 'income', 'error': 'Cannot be empty'},
      ];
      const failure = ValidationFailure(validationDetails);
      final newSavingsSettings = TestDataFactory.createSavingsSettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase.call(newSavingsSettings);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (f) {
          expect(f, isA<ValidationFailure>());
          expect(f.message, 'Validation failed');
          expect((f as ValidationFailure).details, validationDetails);
        },
        (settings) => fail('Expected failure but got success: $settings'),
      );

      verify(mockRepository.getSettings()).called(1);
      verifyNever(mockRepository.saveSettings(any));
    });

    test(
        'should update settings with correct month and year when multiple exist',
        () async {
      // Arrange
      final existingSettings = Settings(
        savingsSettings: [
          TestDataFactory.createSavingsSettings(
              month: 1, year: 2023, savingsAmount: 500.0, income: 3000.0),
          TestDataFactory.createSavingsSettings(
              month: 2, year: 2023, savingsAmount: 600.0, income: 3200.0),
          TestDataFactory.createSavingsSettings(
              month: 1, year: 2024, savingsAmount: 550.0, income: 3100.0),
        ],
      );

      final updateSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 2,
        year: 2023,
        savingsAmount: 750.0,
        income: 3400.0,
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(existingSettings));

      final expectedUpdatedSettings = Settings(
        savingsSettings: [
          TestDataFactory.createSavingsSettings(
              month: 1, year: 2023, savingsAmount: 500.0, income: 3000.0),
          updateSavingsSettings, // Updated middle entry
          TestDataFactory.createSavingsSettings(
              month: 1, year: 2024, savingsAmount: 550.0, income: 3100.0),
        ],
      );

      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => Right(expectedUpdatedSettings));

      // Act
      final result = await useCase.call(updateSavingsSettings);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (settings) {
          expect(settings.savingsSettings?.length, 3);
          final updatedEntry = settings.savingsSettings?[1];
          expect(updatedEntry?.month, 2);
          expect(updatedEntry?.year, 2023);
          expect(updatedEntry?.savingsAmount, 750.0);
          expect(updatedEntry?.income, 3400.0);
        },
      );

      verify(mockRepository.getSettings()).called(1);
      verify(mockRepository.saveSettings(any)).called(1);
    });

    test('should preserve other settings when updating savings settings',
        () async {
      // Arrange
      final existingSettings = TestDataFactory.createSettings();
      final newSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2023,
        savingsAmount: 800.0,
        income: 3500.0,
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(existingSettings));

      // Capture the settings passed to saveSettings
      Settings? capturedSettings;
      when(mockRepository.saveSettings(any)).thenAnswer((invocation) async {
        capturedSettings = invocation.positionalArguments[0] as Settings;
        return Right(capturedSettings!);
      });

      // Act
      await useCase.call(newSavingsSettings);

      // Assert
      expect(capturedSettings, isNotNull);
      expect(capturedSettings!.savingsSettings?.length, 2);

      // Verify the updated entry
      final updatedEntry = capturedSettings!.savingsSettings?.first;
      expect(updatedEntry?.month, 1);
      expect(updatedEntry?.year, 2023);
      expect(updatedEntry?.savingsAmount, 800.0);
      expect(updatedEntry?.income, 3500.0);

      // Verify the preserved entry
      final preservedEntry = capturedSettings!.savingsSettings?.last;
      expect(preservedEntry?.month, 2);
      expect(preservedEntry?.year, 2023);
      expect(preservedEntry?.savingsAmount, 600.0);
      expect(preservedEntry?.income, 3200.0);
    });
  });
}
