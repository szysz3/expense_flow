import 'package:dartz/dartz.dart';

import '../../model/failure/failures.dart';
import '../../model/settings.dart';
import '../../repository/settings_repository.dart';
import '../base/base_use_case.dart';

class SettingsSaveUseCase
    implements BaseUseCase<Settings, Either<Failure, Settings>> {
  final SettingsRepository repository;

  SettingsSaveUseCase(this.repository);

  @override
  Future<Either<Failure, Settings>> call(Settings params) async {
    return await repository.saveSettings(params);
  }
}
