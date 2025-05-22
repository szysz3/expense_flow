import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/savings_settings.dart';
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
    test(
        'should add new savings settings when month/year combination does not exist',
        () async {
      final existingSettings = TestDataFactory.createSettings();
      final newSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 4,
        year: 2023,
        income: 3500.0,
        savingsAmount: 700.0,
      );
      final expectedUpdatedSettings = Settings(
        savingsSettings: [
          ...existingSettings.savingsSettings!,
          newSavingsSettings,
        ],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right<Failure, Settings>(existingSettings));
      when(mockRepository.saveSettings(any)).thenAnswer(
          (_) async => Right<Failure, Settings>(expectedUpdatedSettings));

      final result = await useCase(newSavingsSettings);

      expect(result.isRight(), true);
      verify(mockRepository.getSettings());
      verify(mockRepository.saveSettings(argThat(predicate<Settings>(
          (settings) =>
              settings.savingsSettings?.length == 3 &&
              settings.savingsSettings?.last == newSavingsSettings))));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should update existing savings settings when month/year combination exists',
        () async {
      final existingSettings = TestDataFactory.createSettings();
      final updatedSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2023,
        income: 3500.0,
        savingsAmount: 800.0,
      );
      final expectedUpdatedSettings = Settings(
        savingsSettings: [
          updatedSavingsSettings,
          SavingsSettings(
              month: 2, year: 2023, income: 3200.0, savingsAmount: 600.0),
        ],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right<Failure, Settings>(existingSettings));
      when(mockRepository.saveSettings(any)).thenAnswer(
          (_) async => Right<Failure, Settings>(expectedUpdatedSettings));

      final result = await useCase(updatedSavingsSettings);

      expect(result.isRight(), true);
      verify(mockRepository.getSettings());
      verify(mockRepository.saveSettings(argThat(predicate<Settings>(
          (settings) =>
              settings.savingsSettings?.length == 2 &&
              settings.savingsSettings?.first == updatedSavingsSettings))));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle settings with null savingsSettings list', () async {
      final settingsWithNullSavings =
          TestDataFactory.createSettingsWithNullSavings();
      final newSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2023,
        income: 2500.0,
        savingsAmount: 400.0,
      );
      final expectedUpdatedSettings = Settings(
        savingsSettings: [newSavingsSettings],
      );

      when(mockRepository.getSettings()).thenAnswer(
          (_) async => Right<Failure, Settings>(settingsWithNullSavings));
      when(mockRepository.saveSettings(any)).thenAnswer(
          (_) async => Right<Failure, Settings>(expectedUpdatedSettings));

      final result = await useCase(newSavingsSettings);

      expect(result.isRight(), true);
      verify(mockRepository.getSettings());
      verify(mockRepository.saveSettings(argThat(predicate<Settings>(
          (settings) =>
              settings.savingsSettings?.length == 1 &&
              settings.savingsSettings?.first == newSavingsSettings))));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle empty savingsSettings list', () async {
      final emptySettings = TestDataFactory.createEmptySettings();
      final newSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 5,
        year: 2023,
        income: 4000.0,
        savingsAmount: 900.0,
      );
      final expectedUpdatedSettings = Settings(
        savingsSettings: [newSavingsSettings],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right<Failure, Settings>(emptySettings));
      when(mockRepository.saveSettings(any)).thenAnswer(
          (_) async => Right<Failure, Settings>(expectedUpdatedSettings));

      final result = await useCase(newSavingsSettings);

      expect(result.isRight(), true);
      verify(mockRepository.getSettings());
      verify(mockRepository.saveSettings(argThat(predicate<Settings>(
          (settings) =>
              settings.savingsSettings?.length == 1 &&
              settings.savingsSettings?.first == newSavingsSettings))));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should handle multiple savings settings for different years',
        () async {
      final existingSettings = Settings(
        savingsSettings: [
          SavingsSettings(
              month: 12, year: 2022, income: 2800.0, savingsAmount: 300.0),
          SavingsSettings(
              month: 1, year: 2023, income: 3000.0, savingsAmount: 500.0),
        ],
      );
      final newSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 12,
        year: 2023,
        income: 3800.0,
        savingsAmount: 1000.0,
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right<Failure, Settings>(existingSettings));
      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => Right<Failure, Settings>(existingSettings));

      final result = await useCase(newSavingsSettings);

      expect(result.isRight(), true);
      verify(mockRepository.getSettings());
      verify(mockRepository.saveSettings(argThat(predicate<Settings>(
          (settings) =>
              settings.savingsSettings?.length == 3 &&
              settings.savingsSettings
                      ?.any((s) => s.month == 12 && s.year == 2023) ==
                  true))));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should update existing savings settings with same month but different year',
        () async {
      final existingSettings = Settings(
        savingsSettings: [
          SavingsSettings(
              month: 6, year: 2022, income: 2500.0, savingsAmount: 200.0),
          SavingsSettings(
              month: 6, year: 2023, income: 3000.0, savingsAmount: 500.0),
        ],
      );
      final updatedSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 6,
        year: 2023,
        income: 3200.0,
        savingsAmount: 600.0,
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right<Failure, Settings>(existingSettings));
      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => Right<Failure, Settings>(existingSettings));

      final result = await useCase(updatedSavingsSettings);

      expect(result.isRight(), true);
      verify(mockRepository.getSettings());
      verify(
          mockRepository.saveSettings(argThat(predicate<Settings>((settings) {
        final june2023Setting = settings.savingsSettings?.firstWhere(
          (s) => s.month == 6 && s.year == 2023,
        );
        return settings.savingsSettings?.length == 2 &&
            june2023Setting?.income == 3200.0 &&
            june2023Setting?.savingsAmount == 600.0;
      }))));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should preserve original list when creating updated settings',
        () async {
      final originalSavingsList = TestDataFactory.createSavingsSettingsList();
      final existingSettings = Settings(savingsSettings: originalSavingsList);
      final newSavingsSettings = TestDataFactory.createSavingsSettings(
        month: 4,
        year: 2023,
        income: 3300.0,
        savingsAmount: 650.0,
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right<Failure, Settings>(existingSettings));
      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => Right<Failure, Settings>(existingSettings));

      await useCase(newSavingsSettings);

      // Verify original list is not modified
      expect(originalSavingsList.length, 3);
      expect(originalSavingsList.any((s) => s.month == 4), false);

      verify(mockRepository.saveSettings(argThat(predicate<Settings>(
          (settings) => settings.savingsSettings?.length == 4))));
    });

    test('should return failure when getSettings fails', () async {
      const failure = ServerFailure('Failed to get settings');
      final newSavingsSettings = TestDataFactory.createSavingsSettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left<Failure, Settings>(failure));

      final result = await useCase(newSavingsSettings);

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), failure);
      verify(mockRepository.getSettings());
      verifyNever(mockRepository.saveSettings(any));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when saveSettings fails', () async {
      final existingSettings = TestDataFactory.createSettings();
      const failure = ServerFailure('Failed to save settings');
      final newSavingsSettings = TestDataFactory.createSavingsSettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right<Failure, Settings>(existingSettings));
      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => const Left<Failure, Settings>(failure));

      final result = await useCase(newSavingsSettings);

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), failure);
      verify(mockRepository.getSettings());
      verify(mockRepository.saveSettings(any));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return ConnectionFailure when getSettings returns ConnectionFailure',
        () async {
      const failure = ConnectionFailure();
      final newSavingsSettings = TestDataFactory.createSavingsSettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left<Failure, Settings>(failure));

      final result = await useCase(newSavingsSettings);

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), failure);
      verify(mockRepository.getSettings());
      verifyNever(mockRepository.saveSettings(any));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return UnauthorizedFailure when saveSettings returns UnauthorizedFailure',
        () async {
      final existingSettings = TestDataFactory.createSettings();
      const failure = UnauthorizedFailure();
      final newSavingsSettings = TestDataFactory.createSavingsSettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right<Failure, Settings>(existingSettings));
      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => const Left<Failure, Settings>(failure));

      final result = await useCase(newSavingsSettings);

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), failure);
      verify(mockRepository.getSettings());
      verify(mockRepository.saveSettings(any));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return NotFoundFailure when getSettings returns NotFoundFailure',
        () async {
      const failure = NotFoundFailure();
      final newSavingsSettings = TestDataFactory.createSavingsSettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left<Failure, Settings>(failure));

      final result = await useCase(newSavingsSettings);

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), failure);
      verify(mockRepository.getSettings());
      verifyNever(mockRepository.saveSettings(any));
      verifyNoMoreInteractions(mockRepository);
    });

    test(
        'should return ValidationFailure when saveSettings returns ValidationFailure',
        () async {
      final existingSettings = TestDataFactory.createSettings();
      const failure = ValidationFailure([
        {'field': 'savingsSettings', 'message': 'Invalid data'}
      ]);
      final newSavingsSettings = TestDataFactory.createSavingsSettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right<Failure, Settings>(existingSettings));
      when(mockRepository.saveSettings(any))
          .thenAnswer((_) async => const Left<Failure, Settings>(failure));

      final result = await useCase(newSavingsSettings);

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), failure);
      verify(mockRepository.getSettings());
      verify(mockRepository.saveSettings(any));
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
