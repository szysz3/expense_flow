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
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = SettingsGetSavingsUseCase(repository);
  });

  test('returns failure when repository fails', () async {
    when(repository.getSettings()).thenAnswer(
      (_) async => const Left(ServerFailure('error')),
    );

    final result = await useCase(const NoParams());

    expect(result.isLeft(), true);
    verify(repository.getSettings()).called(1);
  });

  test('returns period covering current month when available', () async {
    final now = DateTime.now();
    final matchingPeriod = SavingsSettings(
      startMonth: now.month - 1 <= 0 ? 12 : now.month - 1,
      startYear: now.month - 1 <= 0 ? now.year - 1 : now.year,
      endMonth: now.month,
      endYear: now.year,
      savingsAmount: 600,
      income: 3200,
    );

    final otherPeriod = TestDataFactory.createSavingsSettings(
      month: now.month,
      year: now.year - 1,
      savingsAmount: 500,
      income: 3000,
    );

    when(repository.getSettings()).thenAnswer(
      (_) async =>
          Right(Settings(savingsSettings: [otherPeriod, matchingPeriod])),
    );

    final result = await useCase(const NoParams());

    expect(result, Right(matchingPeriod));
    verify(repository.getSettings()).called(1);
  });

  test('prefers most recent period when no match exists', () async {
    final periods = [
      TestDataFactory.createSavingsSettings(month: 1, year: 2022),
      TestDataFactory.createSavingsSettings(month: 3, year: 2023),
      TestDataFactory.createSavingsSettings(month: 7, year: 2021),
    ];

    when(repository.getSettings()).thenAnswer(
      (_) async => Right(Settings(savingsSettings: periods)),
    );

    final result = await useCase(const NoParams());

    expect(result, Right(periods[1]));
  });

  test('returns period with open end when applicable', () async {
    final now = DateTime.now();
    final openEnded = TestDataFactory.createSavingsSettings(
      month: now.month,
      year: now.year,
      openEnded: true,
      income: 4100,
    );

    when(repository.getSettings()).thenAnswer(
      (_) async => Right(Settings(savingsSettings: [openEnded])),
    );

    final result = await useCase(const NoParams());

    expect(result, Right(openEnded));
  });

  test('returns default zero values when no periods exist', () async {
    when(repository.getSettings()).thenAnswer(
      (_) async => Right(const Settings(savingsSettings: [])),
    );

    final result = await useCase(const NoParams());
    final now = DateTime.now();

    expect(
      result,
      Right(
        SavingsSettings(
          startMonth: now.month,
          startYear: now.year,
          endMonth: now.month,
          endYear: now.year,
          income: 0,
          savingsAmount: 0,
        ),
      ),
    );
  });

  test('returns first matching period when duplicates exist', () async {
    final now = DateTime.now();
    final first = TestDataFactory.createSavingsSettings(
      month: now.month,
      year: now.year,
      savingsAmount: 400,
      income: 2500,
    );
    final second = TestDataFactory.createSavingsSettings(
      month: now.month,
      year: now.year,
      savingsAmount: 600,
      income: 3000,
    );

    when(repository.getSettings()).thenAnswer(
      (_) async => Right(Settings(savingsSettings: [first, second])),
    );

    final result = await useCase(const NoParams());

    expect(result, Right(first));
  });
}
