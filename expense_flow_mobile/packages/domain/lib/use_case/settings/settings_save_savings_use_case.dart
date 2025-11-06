import 'package:dartz/dartz.dart';
import 'package:domain/model/savings_settings.dart';

import '../../extensions/savings_settings_extensions.dart';
import '../../model/failure/failures.dart';
import '../../model/settings.dart';
import '../../repository/settings_repository.dart';
import '../base/base_use_case.dart';

class SettingsSaveSavingsUseCase
    implements BaseUseCase<List<SavingsSettings>, Either<Failure, Settings>> {
  final SettingsRepository repository;

  SettingsSaveSavingsUseCase(this.repository);

  @override
  Future<Either<Failure, Settings>> call(List<SavingsSettings> periods) async {
    final validationFailure = _validatePeriods(periods);
    if (validationFailure != null) {
      return Left(validationFailure);
    }

    final sortedPeriods = periods.sortedByStartDate();

    final settingsResult = await repository.getSettings();

    return settingsResult.fold(
      (failure) => Left(failure),
      (settings) {
        final updatedSettings = Settings(
          version: settingsCurrentVersion,
          savingsSettings: sortedPeriods,
        );

        return repository.saveSettings(updatedSettings);
      },
    );
  }

  Failure? _validatePeriods(List<SavingsSettings> periods) {
    if (periods.isEmpty) {
      return null;
    }

    for (final period in periods) {
      final isOpenEnded = period.endMonth == null && period.endYear == null;
      final hasPartialEnd =
          (period.endMonth == null) != (period.endYear == null);

      if (period.startMonth < 1 || period.startMonth > 12) {
        return ValidationFailure([
          {'code': 'INVALID_START_MONTH'}
        ]);
      }

      if (period.startYear < 2000) {
        return ValidationFailure([
          {'code': 'INVALID_START_YEAR'}
        ]);
      }

      if (hasPartialEnd) {
        return ValidationFailure([
          {'code': 'PARTIAL_END_DATE'}
        ]);
      }

      if (!isOpenEnded) {
        if (period.endMonth! < 1 || period.endMonth! > 12) {
          return ValidationFailure([
            {'code': 'INVALID_END_MONTH'}
          ]);
        }

        if (period.endYear! < period.startYear) {
          return ValidationFailure([
            {'code': 'END_BEFORE_START_YEAR'}
          ]);
        }

        if (period.endYear == period.startYear &&
            period.endMonth! < period.startMonth) {
          return ValidationFailure([
            {'code': 'END_BEFORE_START_MONTH'}
          ]);
        }
      }

      if (period.income < 0 || period.savingsAmount < 0) {
        return ValidationFailure([
          {'code': 'NEGATIVE_VALUES'}
        ]);
      }
    }

    final sorted = periods.sortedByStartDate();

    for (var i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i];
      final next = sorted[i + 1];

      final currentOpenEnded =
          current.endMonth == null && current.endYear == null;
      if (currentOpenEnded) {
        return ValidationFailure([
          {'code': 'ONLY_LAST_OPEN_ENDED'}
        ]);
      }

      final currentEndYear = current.endYear!;
      final currentEndMonth = current.endMonth!;

      final endsBefore = currentEndYear < next.startYear ||
          (currentEndYear == next.startYear &&
              currentEndMonth < next.startMonth);

      if (!endsBefore) {
        return ValidationFailure([
          {'code': 'PERIODS_OVERLAP'}
        ]);
      }
    }

    return null;
  }
}
