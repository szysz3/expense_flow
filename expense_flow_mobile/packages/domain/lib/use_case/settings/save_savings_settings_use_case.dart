import 'package:dartz/dartz.dart';
import 'package:domain/model/savings_settings.dart';

import '../../model/failure/failures.dart';
import '../../model/settings.dart';
import '../../repository/settings_repository.dart';
import '../base/base_use_case.dart';

class SaveSavingsSettingsUseCase
    implements BaseUseCase<SavingsSettings, Either<Failure, Settings>> {
  final SettingsRepository repository;

  SaveSavingsSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, Settings>> call(
      SavingsSettings currentSavingsSettings) async {
    final settingsResult = await repository.getSettings();

    return settingsResult.fold(
      (failure) => Left(failure),
      (settings) {
        final updatedSavingsSettings = List<SavingsSettings>.from(
            settings.savingsSettings ?? List.empty());

        final currentMonthIndex = updatedSavingsSettings.indexWhere((setting) =>
            setting.month == currentSavingsSettings.month &&
            setting.year == currentSavingsSettings.year);

        if (currentMonthIndex >= 0) {
          updatedSavingsSettings[currentMonthIndex] = currentSavingsSettings;
        } else {
          updatedSavingsSettings.add(currentSavingsSettings);
        }

        final updatedSettings =
            Settings(savingsSettings: updatedSavingsSettings);

        return repository.saveSettings(updatedSettings);
      },
    );
  }
}
