import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/savings_settings.dart';
import 'package:domain/model/settings.dart';
import 'package:domain/repository/settings_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';
import 'package:domain/use_case/settings/settings_get_savings_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../utils/test_data_factory.dart';
import 'settings_get_savings_use_case_test.mocks.dart';

@GenerateMocks([SettingsRepository])
void main() {
  late SettingsGetSavingsUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = SettingsGetSavingsUseCase(mockRepository);
  });

  group('SettingsGetSavingsUseCase', () {
    test('should return failure when repository fails', () async {
      const failure = ServerFailure('Server error');
      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase.call(NoParams());

      expect(result, const Left(failure));
      verify(mockRepository.getSettings()).called(1);
    });

    test('should return current month settings when exact match exists',
        () async {
      final now = DateTime.now();
      final currentMonthSettings = SavingsSettings(
        month: now.month,
        year: now.year,
        savingsAmount: 600.0,
        income: 3500.0,
      );

      final otherSettings = SavingsSettings(
        month: now.month == 1 ? 2 : 1,
        year: now.year,
        savingsAmount: 500.0,
        income: 3000.0,
      );

      final settings = Settings(
        savingsSettings: [otherSettings, currentMonthSettings],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      final result = await useCase.call(NoParams());

      expect(result, Right(currentMonthSettings));
      verify(mockRepository.getSettings()).called(1);
    });

    test('should return most recent settings when no current month match',
        () async {
      final now = DateTime.now();
      final olderSettings = SavingsSettings(
        month: 1,
        year: now.year - 1,
        savingsAmount: 400.0,
        income: 2800.0,
      );

      final newerSettings = SavingsSettings(
        month: 6,
        year: now.year,
        savingsAmount: 700.0,
        income: 3200.0,
      );

      final middleSettings = SavingsSettings(
        month: 3,
        year: now.year,
        savingsAmount: 550.0,
        income: 3100.0,
      );

      final settings = Settings(
        savingsSettings: [olderSettings, middleSettings, newerSettings],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      final result = await useCase.call(NoParams());

      expect(result, Right(newerSettings));
      verify(mockRepository.getSettings()).called(1);
    });

    test('should return most recent settings when sorted by year first',
        () async {
      final now = DateTime.now();
      final currentYearEarly = SavingsSettings(
        month: 2,
        year: now.year,
        savingsAmount: 500.0,
        income: 3000.0,
      );

      final nextYearLate = SavingsSettings(
        month: 12,
        year: now.year + 1,
        savingsAmount: 800.0,
        income: 3500.0,
      );

      final currentYearLate = SavingsSettings(
        month: 10,
        year: now.year,
        savingsAmount: 600.0,
        income: 3200.0,
      );

      final settings = Settings(
        savingsSettings: [currentYearEarly, currentYearLate, nextYearLate],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      final result = await useCase.call(NoParams());

      expect(result, Right(nextYearLate));
      verify(mockRepository.getSettings()).called(1);
    });

    test('should return default settings when savingsSettings is null',
        () async {
      final now = DateTime.now();
      const settings = Settings(savingsSettings: null);

      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Right(settings));

      final result = await useCase.call(NoParams());

      final expectedDefault = SavingsSettings(
        month: now.month,
        year: now.year,
        savingsAmount: 0.0,
        income: 0.0,
      );

      expect(result, Right(expectedDefault));
      verify(mockRepository.getSettings()).called(1);
    });

    test('should return default settings when savingsSettings is empty',
        () async {
      final now = DateTime.now();
      final settings = TestDataFactory.createEmptySettings();

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      final result = await useCase.call(NoParams());

      final expectedDefault = SavingsSettings(
        month: now.month,
        year: now.year,
        savingsAmount: 0.0,
        income: 0.0,
      );

      expect(result, Right(expectedDefault));
      verify(mockRepository.getSettings()).called(1);
    });

    test('should return first match when multiple current month settings exist',
        () async {
      final now = DateTime.now();
      final firstCurrentMonth = SavingsSettings(
        month: now.month,
        year: now.year,
        savingsAmount: 500.0,
        income: 3000.0,
      );

      final secondCurrentMonth = SavingsSettings(
        month: now.month,
        year: now.year,
        savingsAmount: 600.0,
        income: 3200.0,
      );

      final settings = Settings(
        savingsSettings: [firstCurrentMonth, secondCurrentMonth],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      final result = await useCase.call(NoParams());

      expect(result, Right(firstCurrentMonth));
      verify(mockRepository.getSettings()).called(1);
    });

    test('should handle different failure types', () async {
      const failures = [
        ConnectionFailure(),
        UnauthorizedFailure(),
        NotFoundFailure(),
        ValidationFailure([
          {'field': 'error'}
        ]),
      ];

      for (final failure in failures) {
        when(mockRepository.getSettings())
            .thenAnswer((_) async => Left(failure));

        final result = await useCase.call(NoParams());

        expect(result, Left(failure));
      }

      verify(mockRepository.getSettings()).called(failures.length);
    });

    test('should sort settings correctly with mixed years and months',
        () async {
      final settings2023Jan = SavingsSettings(
        month: 1,
        year: 2023,
        savingsAmount: 300.0,
        income: 2500.0,
      );

      final settings2024Dec = SavingsSettings(
        month: 12,
        year: 2024,
        savingsAmount: 800.0,
        income: 4000.0,
      );

      final settings2024Jan = SavingsSettings(
        month: 1,
        year: 2024,
        savingsAmount: 500.0,
        income: 3000.0,
      );

      final settings2023Dec = SavingsSettings(
        month: 12,
        year: 2023,
        savingsAmount: 400.0,
        income: 2800.0,
      );

      final settings = Settings(
        savingsSettings: [
          settings2023Jan,
          settings2024Jan,
          settings2023Dec,
          settings2024Dec,
        ],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      final result = await useCase.call(NoParams());

      expect(result, Right(settings2024Dec));
      verify(mockRepository.getSettings()).called(1);
    });

    test('should handle single savings setting', () async {
      final singleSetting = TestDataFactory.createSavingsSettings(
        month: 6,
        year: 2023,
        savingsAmount: 750.0,
        income: 3500.0,
      );

      final settings = Settings(savingsSettings: [singleSetting]);

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      final result = await useCase.call(NoParams());

      expect(result, Right(singleSetting));
      verify(mockRepository.getSettings()).called(1);
    });
  });
}
