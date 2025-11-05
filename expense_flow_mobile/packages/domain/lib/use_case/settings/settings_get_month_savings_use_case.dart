import 'package:dartz/dartz.dart';
import 'package:domain/model/savings_settings.dart';

import '../../extensions/savings_settings_extensions.dart';
import '../../model/failure/failures.dart';
import '../../repository/settings_repository.dart';
import '../base/base_use_case.dart';

class SettingsGetMonthSavingsParams {
  final List<(int, int)> monthYearPairs;

  const SettingsGetMonthSavingsParams({required this.monthYearPairs});
}

class SettingsGetMonthSavingsUseCase
    implements
        BaseUseCase<SettingsGetMonthSavingsParams,
            Either<Failure, Map<(int, int), SavingsSettings>>> {
  final SettingsRepository repository;

  SettingsGetMonthSavingsUseCase(this.repository);

  @override
  Future<Either<Failure, Map<(int, int), SavingsSettings>>> call(
      SettingsGetMonthSavingsParams params) async {
    final settingsResult = await repository.getSettings();

    return settingsResult.fold(
      (failure) => Left(failure),
      (settings) {
        final result = <(int, int), SavingsSettings>{};

        final periods = settings.savingsSettings ?? [];
        for (final pair in params.monthYearPairs) {
          final month = pair.$1;
          final year = pair.$2;

          final matchingPeriod = periods.findPeriodForMonth(month, year);
          if (matchingPeriod != null) {
            result[pair] = matchingPeriod;
            continue;
          }

          result[pair] = SavingsSettings(
            startMonth: month,
            startYear: year,
            endMonth: month,
            endYear: year,
            savingsAmount: 0.0,
            income: 0.0,
          );
        }

        return Right(result);
      },
    );
  }
}
