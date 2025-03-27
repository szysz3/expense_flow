import 'package:dartz/dartz.dart';

import '../../model/failure/failures.dart';
import '../../model/settings.dart';
import '../../repository/settings_repository.dart';
import '../base/base_use_case.dart';

class GetSettingsUseCase
    implements BaseUseCase<NoParams, Either<Failure, Settings>> {
  final SettingsRepository repository;

  GetSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, Settings>> call(NoParams params) async {
    return await repository.getSettings();
  }
}
