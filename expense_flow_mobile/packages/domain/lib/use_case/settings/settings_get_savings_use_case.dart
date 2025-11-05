import 'package:dartz/dartz.dart';
import 'package:domain/model/savings_settings.dart';

import '../../extensions/savings_settings_extensions.dart';
import '../../model/failure/failures.dart';
import '../../repository/settings_repository.dart';
import '../base/base_use_case.dart';

class SettingsGetSavingsUseCase
    implements BaseUseCase<NoParams, Either<Failure, SavingsSettings>> {
  final SettingsRepository repository;

  SettingsGetSavingsUseCase(this.repository);

  @override
  Future<Either<Failure, SavingsSettings>> call(NoParams params) async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final settingsResult = await repository.getSettings();

    return settingsResult.fold(
      (failure) => Left(failure),
      (settings) {
        final periods = settings.savingsSettings ?? [];
        if (periods.isEmpty) {
          return Right(SavingsSettings(
            startMonth: currentMonth,
            startYear: currentYear,
            endMonth: currentMonth,
            endYear: currentYear,
            savingsAmount: 0.0,
            income: 0.0,
          ));
        }

        final matchingPeriod =
            periods.findPeriodForMonth(currentMonth, currentYear);
        if (matchingPeriod != null) {
          return Right(matchingPeriod);
        }

        final sorted = periods.toList()
          ..sort((a, b) {
            final yearComparison = b.startYear.compareTo(a.startYear);
            if (yearComparison != 0) return yearComparison;
            return b.startMonth.compareTo(a.startMonth);
          });

        return Right(sorted.first);
      },
    );
  }
}
