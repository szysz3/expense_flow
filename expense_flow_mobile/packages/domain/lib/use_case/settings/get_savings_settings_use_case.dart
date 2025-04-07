import 'package:dartz/dartz.dart';
import 'package:domain/model/savings_settings.dart';

import '../../model/failure/failures.dart';
import '../../repository/settings_repository.dart';
import '../base/base_use_case.dart';

class GetSavingsSettingsUseCase
    implements BaseUseCase<NoParams, Either<Failure, SavingsSettings>> {
  final SettingsRepository repository;

  GetSavingsSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, SavingsSettings>> call(NoParams params) async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final settingsResult = await repository.getSettings();

    return settingsResult.fold(
      (failure) => Left(failure),
      (settings) {
        final currentMonthSettings = settings.savingsSettings?.where(
            (setting) =>
                setting.month == currentMonth && setting.year == currentYear);

        if (currentMonthSettings != null && currentMonthSettings.isNotEmpty) {
          // Return matching settings entry
          return Right(currentMonthSettings.first);
        } else if (settings.savingsSettings != null &&
            settings.savingsSettings!.isNotEmpty) {
          final sortedSettings = settings.savingsSettings!.toList()
            ..sort((a, b) {
              final yearComparison = b.year.compareTo(a.year);
              if (yearComparison != 0) return yearComparison;
              return b.month.compareTo(a.month);
            });

          // Return the most recent settings entry
          return Right(sortedSettings.first);
        } else {
          // Return default settings if no entries exist
          return Right(SavingsSettings(
            month: currentMonth,
            year: currentYear,
            savingsAmount: 0.0,
            income: 0.0,
          ));
        }
      },
    );
  }
}
