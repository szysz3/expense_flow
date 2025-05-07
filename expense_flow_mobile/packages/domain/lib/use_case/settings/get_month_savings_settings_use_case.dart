import 'package:dartz/dartz.dart';
import 'package:domain/model/savings_settings.dart';

import '../../model/failure/failures.dart';
import '../../repository/settings_repository.dart';
import '../base/base_use_case.dart';

class GetMonthSavingsSettingsParams {
  final List<(int, int)> monthYearPairs;

  const GetMonthSavingsSettingsParams({required this.monthYearPairs});
}

class GetMonthSavingsSettingsUseCase
    implements
        BaseUseCase<GetMonthSavingsSettingsParams,
            Either<Failure, Map<(int, int), SavingsSettings>>> {
  final SettingsRepository repository;

  GetMonthSavingsSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, Map<(int, int), SavingsSettings>>> call(
      GetMonthSavingsSettingsParams params) async {
    final settingsResult = await repository.getSettings();

    return settingsResult.fold(
      (failure) => Left(failure),
      (settings) {
        final result = <(int, int), SavingsSettings>{};

        // If no savings settings exist, return default values for each requested month
        if (settings.savingsSettings == null ||
            settings.savingsSettings!.isEmpty) {
          for (final pair in params.monthYearPairs) {
            result[pair] = SavingsSettings(
              month: pair.$1,
              year: pair.$2,
              savingsAmount: 0.0,
              income: 0.0,
            );
          }
          return Right(result);
        }

        // Sort settings for easier lookup of closest match
        final sortedSettings = settings.savingsSettings!.toList()
          ..sort((a, b) {
            final yearComparison = b.year.compareTo(a.year);
            if (yearComparison != 0) return yearComparison;
            return b.month.compareTo(a.month);
          });

        for (final pair in params.monthYearPairs) {
          final month = pair.$1;
          final year = pair.$2;

          // Try to find exact match first
          final exactMatch = settings.savingsSettings!.where(
              (setting) => setting.month == month && setting.year == year);

          if (exactMatch.isNotEmpty) {
            result[pair] = exactMatch.first;
          } else {
            // Find the closest earlier settings (prefer settings from same year)
            SavingsSettings? closestSettings;

            // First try to find settings from same year but earlier month
            final sameYearSettings = settings.savingsSettings!.where(
                (setting) => setting.year == year && setting.month < month);

            if (sameYearSettings.isNotEmpty) {
              closestSettings =
                  sameYearSettings.reduce((a, b) => a.month > b.month ? a : b);
            } else {
              // Try to find most recent settings from previous years
              final earlierYearSettings = settings.savingsSettings!
                  .where((setting) => setting.year < year);

              if (earlierYearSettings.isNotEmpty) {
                closestSettings = sortedSettings.firstWhere(
                    (setting) => setting.year < year,
                    orElse: () => sortedSettings.first);
              }
            }

            if (closestSettings != null) {
              result[pair] = closestSettings;
            } else {
              // Use most recent settings if no closer match found
              result[pair] = sortedSettings.first;
            }
          }
        }

        return Right(result);
      },
    );
  }
}
