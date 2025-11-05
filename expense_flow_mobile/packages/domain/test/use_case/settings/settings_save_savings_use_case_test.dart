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
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = SettingsSaveSavingsUseCase(repository);
  });

  test('saves sorted periods and sets current version', () async {
    final inputPeriods = [
      TestDataFactory.createSavingsSettings(month: 5, year: 2024, income: 4000),
      TestDataFactory.createSavingsSettings(month: 2, year: 2023, income: 3200),
      TestDataFactory.createSavingsSettings(
          month: 12, year: 2023, income: 3800),
    ];

    when(repository.getSettings()).thenAnswer(
      (_) async => Right(TestDataFactory.createSettings()),
    );

    Settings? captured;
    when(repository.saveSettings(any)).thenAnswer((invocation) async {
      captured = invocation.positionalArguments.first as Settings;
      return Right(captured!);
    });

    final result = await useCase(inputPeriods);

    expect(result.isRight(), true);
    verify(repository.getSettings()).called(1);
    verify(repository.saveSettings(any)).called(1);
    expect(captured, isNotNull);
    final savedPeriods = captured!.savingsSettings!;
    expect(savedPeriods.length, 3);
    expect(savedPeriods.first.startYear, 2023);
    expect(savedPeriods.first.startMonth, 2);
    expect(savedPeriods.last.startYear, 2024);
    expect(captured!.version, settingsCurrentVersion);
  });

  test('allows saving an empty list of periods', () async {
    when(repository.getSettings()).thenAnswer(
      (_) async => Right(TestDataFactory.createSettings()),
    );

    Settings? captured;
    when(repository.saveSettings(any)).thenAnswer((invocation) async {
      captured = invocation.positionalArguments.first as Settings;
      return Right(captured!);
    });

    final result = await useCase(const []);

    expect(result.isRight(), true);
    verify(repository.getSettings()).called(1);
    verify(repository.saveSettings(any)).called(1);
    expect(captured?.savingsSettings, isEmpty);
  });

  test('returns validation failure when periods overlap', () async {
    final overlapping = [
      TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2024,
        endMonth: 6,
        endYear: 2024,
      ),
      TestDataFactory.createSavingsSettings(
        month: 5,
        year: 2024,
      ),
    ];

    final result = await useCase(overlapping);

    expect(result.isLeft(), true);
    result.fold((failure) {
      expect(failure, isA<ValidationFailure>());
    }, (_) => fail('Expected validation failure'));
    verifyNever(repository.getSettings());
    verifyNever(repository.saveSettings(any));
  });

  test('returns validation failure when non-last period is open-ended',
      () async {
    final periods = [
      TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2024,
        openEnded: true,
      ),
      TestDataFactory.createSavingsSettings(
        month: 3,
        year: 2024,
      ),
    ];

    final result = await useCase(periods);

    expect(result.isLeft(), true);
    result.fold((failure) {
      expect(failure, isA<ValidationFailure>());
    }, (_) => fail('Expected validation failure'));
    verifyNever(repository.getSettings());
    verifyNever(repository.saveSettings(any));
  });

  test('returns validation failure for invalid month values', () async {
    final periods = [
      TestDataFactory.createSavingsSettings(month: 13, year: 2024),
    ];

    final result = await useCase(periods);

    expect(result.isLeft(), true);
    result.fold((failure) {
      expect(failure, isA<ValidationFailure>());
    }, (_) => fail('Expected validation failure'));
    verifyNever(repository.getSettings());
    verifyNever(repository.saveSettings(any));
  });

  test('returns validation failure for negative values', () async {
    final periods = [
      TestDataFactory.createSavingsSettings(
        month: 1,
        year: 2024,
        income: -10,
      ),
    ];

    final result = await useCase(periods);

    expect(result.isLeft(), true);
    result.fold((failure) {
      expect(failure, isA<ValidationFailure>());
    }, (_) => fail('Expected validation failure'));
    verifyNever(repository.getSettings());
    verifyNever(repository.saveSettings(any));
  });

  test('forwards repository failure when getSettings fails', () async {
    when(repository.getSettings()).thenAnswer(
      (_) async => const Left(ServerFailure('failure')),
    );

    final result = await useCase([TestDataFactory.createSavingsSettings()]);

    expect(result.isLeft(), true);
    expect(
      result.swap().getOrElse(() => const ServerFailure('failure')),
      const ServerFailure('failure'),
    );
    verify(repository.getSettings()).called(1);
    verifyNever(repository.saveSettings(any));
  });

  test('forwards repository failure when saveSettings fails', () async {
    when(repository.getSettings()).thenAnswer(
      (_) async => Right(TestDataFactory.createSettings()),
    );

    when(repository.saveSettings(any)).thenAnswer(
      (_) async => const Left(ServerFailure('save failed')),
    );

    final result = await useCase([TestDataFactory.createSavingsSettings()]);

    expect(result.isLeft(), true);
    expect(
      result.swap().getOrElse(() => const ServerFailure('save failed')),
      const ServerFailure('save failed'),
    );
    verify(repository.getSettings()).called(1);
    verify(repository.saveSettings(any)).called(1);
  });
}
