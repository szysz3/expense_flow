import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/settings.dart';
import 'package:domain/repository/settings_repository.dart';
import 'package:domain/use_case/settings/settings_get_month_savings_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../utils/test_data_factory.dart';
import 'settings_get_month_savings_use_case_test.mocks.dart';

@GenerateMocks([SettingsRepository])
void main() {
  late SettingsGetMonthSavingsUseCase useCase;
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = SettingsGetMonthSavingsUseCase(repository);
  });

  test('returns failure when repository fails', () async {
    when(repository.getSettings()).thenAnswer(
      (_) async => const Left(ServerFailure('error')),
    );

    const params = SettingsGetMonthSavingsParams(monthYearPairs: [(1, 2024)]);

    final result = await useCase(params);

    expect(result.isLeft(), true);
    verify(repository.getSettings()).called(1);
  });

  test('returns default entries when no periods exist', () async {
    when(repository.getSettings()).thenAnswer(
      (_) async => const Right(Settings(savingsSettings: [])),
    );

    const params = SettingsGetMonthSavingsParams(
      monthYearPairs: [(3, 2024), (8, 2025)],
    );

    final result = await useCase(params);

    result.fold(
      (_) => fail('Expected success'),
      (map) {
        expect(map.length, 2);
        expect(map[(3, 2024)]?.income, 0);
        expect(map[(8, 2025)]?.savingsAmount, 0);
      },
    );
  });

  test('maps month pairs to the matching periods', () async {
    final firstQuarter = TestDataFactory.createSavingsSettings(
      month: 1,
      year: 2024,
      endMonth: 3,
      endYear: 2024,
      savingsAmount: 600,
      income: 3200,
    );

    final openEnded = TestDataFactory.createSavingsSettings(
      month: 4,
      year: 2024,
      openEnded: true,
      savingsAmount: 800,
      income: 4000,
    );

    when(repository.getSettings()).thenAnswer(
      (_) async => Right(Settings(savingsSettings: [firstQuarter, openEnded])),
    );

    const params = SettingsGetMonthSavingsParams(
      monthYearPairs: [(2, 2024), (7, 2024)],
    );

    final result = await useCase(params);

    result.fold(
      (_) => fail('Expected success'),
      (map) {
        expect(map[(2, 2024)], firstQuarter);
        expect(map[(7, 2024)], openEnded);
      },
    );
  });

  test('returns default for months outside all periods', () async {
    final period = TestDataFactory.createSavingsSettings(
      month: 6,
      year: 2024,
      endMonth: 8,
      endYear: 2024,
    );

    when(repository.getSettings()).thenAnswer(
      (_) async => Right(Settings(savingsSettings: [period])),
    );

    const params = SettingsGetMonthSavingsParams(
      monthYearPairs: [(1, 2024), (12, 2025)],
    );

    final result = await useCase(params);

    result.fold(
      (_) => fail('Expected success'),
      (map) {
        expect(map[(1, 2024)]?.income, 0);
        expect(map[(12, 2025)]?.savingsAmount, 0);
      },
    );
  });

  test('returns empty map when no month pairs provided', () async {
    when(repository.getSettings()).thenAnswer(
      (_) async => Right(TestDataFactory.createSettings()),
    );

    const params = SettingsGetMonthSavingsParams(monthYearPairs: []);

    final result = await useCase(params);

    result.fold(
      (_) => fail('Expected success'),
      (map) => expect(map, isEmpty),
    );
  });
}
