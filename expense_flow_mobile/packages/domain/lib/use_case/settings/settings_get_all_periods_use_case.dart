import 'package:dartz/dartz.dart';
import 'package:domain/model/savings_settings.dart';

import '../../model/failure/failures.dart';
import '../../repository/settings_repository.dart';
import '../base/base_use_case.dart';

class SettingsGetAllPeriodsUseCase
    implements BaseUseCase<NoParams, Either<Failure, List<SavingsSettings>>> {
  final SettingsRepository repository;

  SettingsGetAllPeriodsUseCase(this.repository);

  @override
  Future<Either<Failure, List<SavingsSettings>>> call(NoParams params) async {
    final settingsResult = await repository.getSettings();

    return settingsResult.fold(
      (failure) => Left(failure),
      (settings) => Right(settings.savingsSettings ?? []),
    );
  }
}
