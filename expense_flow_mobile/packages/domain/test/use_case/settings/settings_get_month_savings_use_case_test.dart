import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/savings_settings.dart';
import 'package:domain/model/settings.dart';
import 'package:domain/repository/settings_repository.dart';
import 'package:domain/use_case/settings/settings_get_month_savings_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../utils/test_data_factory.dart';
import 'settings_get_savings_use_case_test.mocks.dart';

@GenerateMocks([SettingsRepository])
void main() {
  late SettingsGetMonthSavingsUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = SettingsGetMonthSavingsUseCase(mockRepository);
  });

  group('SettingsGetMonthSavingsUseCase', () {
    test('should return failure when repository fails', () async {
      const failure = ServerFailure('Server error');
      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(1, 2024), (2, 2024)],
      );

      final result = await useCase.call(params);

      expect(result, const Left(failure));
      verify(mockRepository.getSettings()).called(1);
    });

    test('should return default settings when savingsSettings is null',
        () async {
      const settings = Settings(savingsSettings: null);
      when(mockRepository.getSettings())
          .thenAnswer((_) async => const Right(settings));

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(3, 2024), (6, 2024)],
      );

      final result = await useCase.call(params);

      final expectedMap = <(int, int), SavingsSettings>{
        (3, 2024): const SavingsSettings(
          month: 3,
          year: 2024,
          savingsAmount: 0.0,
          income: 0.0,
        ),
        (6, 2024): const SavingsSettings(
          month: 6,
          year: 2024,
          savingsAmount: 0.0,
          income: 0.0,
        ),
      };

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, expectedMap),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test('should return default settings when savingsSettings is empty',
        () async {
      final settings = TestDataFactory.createEmptySettings();
      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(1, 2023)],
      );

      final result = await useCase.call(params);

      final expectedMap = <(int, int), SavingsSettings>{
        (1, 2023): const SavingsSettings(
          month: 1,
          year: 2023,
          savingsAmount: 0.0,
          income: 0.0,
        ),
      };

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, expectedMap),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test('should return exact matches when they exist', () async {
      final march2024 = TestDataFactory.createSavingsSettings(
        month: 3,
        year: 2024,
        savingsAmount: 600.0,
        income: 3200.0,
      );

      final june2024 = TestDataFactory.createSavingsSettings(
        month: 6,
        year: 2024,
        savingsAmount: 750.0,
        income: 3500.0,
      );

      final settings = Settings(
        savingsSettings: [march2024, june2024],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(3, 2024), (6, 2024)],
      );

      final result = await useCase.call(params);

      final expectedMap = <(int, int), SavingsSettings>{
        (3, 2024): march2024,
        (6, 2024): june2024,
      };

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, expectedMap),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test(
        'should return first exact match when multiple exist for same month/year',
        () async {
      final firstMarch = TestDataFactory.createSavingsSettings(
        month: 3,
        year: 2024,
        savingsAmount: 500.0,
        income: 3000.0,
      );

      final secondMarch = TestDataFactory.createSavingsSettings(
        month: 3,
        year: 2024,
        savingsAmount: 600.0,
        income: 3200.0,
      );

      final settings = Settings(
        savingsSettings: [firstMarch, secondMarch],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(3, 2024)],
      );

      final result = await useCase.call(params);

      final expectedMap = <(int, int), SavingsSettings>{
        (3, 2024): firstMarch,
      };

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, expectedMap),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test('should find closest earlier month from same year', () async {
      final jan2024 = TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2024,
        savingsAmount: 400.0,
        income: 2800.0,
      );

      final march2024 = TestDataFactory.createSavingsSettings(
        month: 3,
        year: 2024,
        savingsAmount: 600.0,
        income: 3200.0,
      );

      final settings = Settings(
        savingsSettings: [jan2024, march2024],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(5, 2024)],
      );

      final result = await useCase.call(params);

      final expectedMap = <(int, int), SavingsSettings>{
        (5, 2024): march2024,
      };

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, expectedMap),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test(
        'should choose latest month when multiple same year earlier months exist',
        () async {
      final jan2024 = TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2024,
        savingsAmount: 400.0,
        income: 2800.0,
      );

      final march2024 = TestDataFactory.createSavingsSettings(
        month: 3,
        year: 2024,
        savingsAmount: 600.0,
        income: 3200.0,
      );

      final april2024 = TestDataFactory.createSavingsSettings(
        month: 4,
        year: 2024,
        savingsAmount: 650.0,
        income: 3300.0,
      );

      final settings = Settings(
        savingsSettings: [jan2024, march2024, april2024],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(7, 2024)],
      );

      final result = await useCase.call(params);

      final expectedMap = <(int, int), SavingsSettings>{
        (7, 2024): april2024,
      };

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, expectedMap),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test('should find most recent from previous years when no same year match',
        () async {
      final dec2022 = TestDataFactory.createSavingsSettings(
        month: 12,
        year: 2022,
        savingsAmount: 300.0,
        income: 2500.0,
      );

      final june2023 = TestDataFactory.createSavingsSettings(
        month: 6,
        year: 2023,
        savingsAmount: 500.0,
        income: 3000.0,
      );

      final feb2023 = TestDataFactory.createSavingsSettings(
        month: 2,
        year: 2023,
        savingsAmount: 450.0,
        income: 2900.0,
      );

      final settings = Settings(
        savingsSettings: [dec2022, feb2023, june2023],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(3, 2024)],
      );

      final result = await useCase.call(params);

      final expectedMap = <(int, int), SavingsSettings>{
        (3, 2024): june2023,
      };

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, expectedMap),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test('should use most recent settings when no closer match found',
        () async {
      final dec2025 = TestDataFactory.createSavingsSettings(
        month: 12,
        year: 2025,
        savingsAmount: 800.0,
        income: 4000.0,
      );

      final june2026 = TestDataFactory.createSavingsSettings(
        month: 6,
        year: 2026,
        savingsAmount: 900.0,
        income: 4500.0,
      );

      final settings = Settings(
        savingsSettings: [dec2025, june2026],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(3, 2024)],
      );

      final result = await useCase.call(params);

      final expectedMap = <(int, int), SavingsSettings>{
        (3, 2024): june2026,
      };

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, expectedMap),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test('should handle mixed scenarios with multiple month/year pairs',
        () async {
      final jan2023 = TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2023,
        savingsAmount: 400.0,
        income: 2800.0,
      );

      final march2024 = TestDataFactory.createSavingsSettings(
        month: 3,
        year: 2024,
        savingsAmount: 600.0,
        income: 3200.0,
      );

      final june2024 = TestDataFactory.createSavingsSettings(
        month: 6,
        year: 2024,
        savingsAmount: 750.0,
        income: 3500.0,
      );

      final settings = Settings(
        savingsSettings: [jan2023, march2024, june2024],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [
          (3, 2024), // Exact match
          (5, 2024), // Same year earlier month (march2024)
          (2, 2023), // Same year earlier month (jan2023)
          (6, 2025), // Most recent (june2024)
        ],
      );

      final result = await useCase.call(params);

      final expectedMap = <(int, int), SavingsSettings>{
        (3, 2024): march2024,
        (5, 2024): march2024,
        (2, 2023): jan2023,
        (6, 2025): june2024,
      };

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, expectedMap),
      );
      verify(mockRepository.getSettings()).called(1);
    });

    test('should handle empty monthYearPairs list', () async {
      final settings = TestDataFactory.createSettings();
      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      const params = SettingsGetMonthSavingsParams(monthYearPairs: []);

      final result = await useCase.call(params);

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, isEmpty),
      );
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

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(1, 2024)],
      );

      for (final failure in failures) {
        when(mockRepository.getSettings())
            .thenAnswer((_) async => Left(failure));

        final result = await useCase.call(params);

        expect(result, Left(failure));
      }

      verify(mockRepository.getSettings()).called(failures.length);
    });

    test(
        'should correctly sort and find most recent from mixed years and months',
        () async {
      final jan2023 = TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2023,
        savingsAmount: 300.0,
        income: 2500.0,
      );

      final dec2023 = TestDataFactory.createSavingsSettings(
        month: 12,
        year: 2023,
        savingsAmount: 500.0,
        income: 3000.0,
      );

      final june2024 = TestDataFactory.createSavingsSettings(
        month: 6,
        year: 2024,
        savingsAmount: 700.0,
        income: 3500.0,
      );

      final march2024 = TestDataFactory.createSavingsSettings(
        month: 3,
        year: 2024,
        savingsAmount: 650.0,
        income: 3300.0,
      );

      final settings = Settings(
        savingsSettings: [jan2023, march2024, dec2023, june2024],
      );

      when(mockRepository.getSettings())
          .thenAnswer((_) async => Right(settings));

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(1, 2025)],
      );

      final result = await useCase.call(params);

      final expectedMap = <(int, int), SavingsSettings>{
        (1, 2025): june2024,
      };

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, expectedMap),
      );
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

      const params = SettingsGetMonthSavingsParams(
        monthYearPairs: [(6, 2023), (8, 2023), (1, 2024)],
      );

      final result = await useCase.call(params);

      final expectedMap = <(int, int), SavingsSettings>{
        (6, 2023): singleSetting, // Exact match
        (8, 2023): singleSetting, // Same year earlier month
        (1, 2024): singleSetting, // Most recent from previous year
      };

      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (actualMap) => expect(actualMap, expectedMap),
      );
      verify(mockRepository.getSettings()).called(1);
    });
  });
}
