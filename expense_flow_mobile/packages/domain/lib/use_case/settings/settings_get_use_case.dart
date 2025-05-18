import 'package:dartz/dartz.dart';

import '../../model/failure/failures.dart';
import '../../model/settings.dart';
import '../../repository/settings_repository.dart';
import '../base/base_use_case.dart';

class SettingsGetUseCase
    implements BaseUseCase<NoParams, Either<Failure, Settings>> {
  final SettingsRepository repository;

  SettingsGetUseCase(this.repository);

  @override
  Future<Either<Failure, Settings>> call(NoParams params) async {
    return await repository.getSettings();
  }
}
