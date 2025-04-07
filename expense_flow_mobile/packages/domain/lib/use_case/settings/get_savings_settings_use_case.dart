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
          print('--> current month savings: ${currentMonthSettings.first}');
          return Right(currentMonthSettings.first);
        } else {
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
