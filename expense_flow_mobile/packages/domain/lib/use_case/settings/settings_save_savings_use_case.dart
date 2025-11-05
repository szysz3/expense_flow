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
          {'field': 'startMonth', 'msg': 'Start month must be between 1 and 12'}
        ]);
      }

      if (period.startYear < 2000) {
        return ValidationFailure([
          {'field': 'startYear', 'msg': 'Start year must be 2000 or later'}
        ]);
      }

      if (hasPartialEnd) {
        return ValidationFailure([
          {'field': 'end', 'msg': 'End month and year must both be provided'}
        ]);
      }

      if (!isOpenEnded) {
        if (period.endMonth! < 1 || period.endMonth! > 12) {
          return ValidationFailure([
            {'field': 'endMonth', 'msg': 'End month must be between 1 and 12'}
          ]);
        }

        if (period.endYear! < period.startYear) {
          return ValidationFailure([
            {'field': 'endYear', 'msg': 'End year cannot be before start year'}
          ]);
        }

        if (period.endYear == period.startYear &&
            period.endMonth! < period.startMonth) {
          return ValidationFailure([
            {
              'field': 'endMonth',
              'msg': 'End month cannot be before start month'
            }
          ]);
        }
      }

      if (period.income < 0 || period.savingsAmount < 0) {
        return ValidationFailure([
          {'field': 'values', 'msg': 'Income and savings must be non-negative'}
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
          {'field': 'end', 'msg': 'Only the last period may be open-ended'}
        ]);
      }

      final currentEndYear = current.endYear!;
      final currentEndMonth = current.endMonth!;

      final endsBefore = currentEndYear < next.startYear ||
          (currentEndYear == next.startYear &&
              currentEndMonth < next.startMonth);

      if (!endsBefore) {
        return ValidationFailure([
          {'field': 'range', 'msg': 'Periods may not overlap'}
        ]);
      }
    }

    return null;
  }
}
