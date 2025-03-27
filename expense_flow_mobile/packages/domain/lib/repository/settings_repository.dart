import 'package:dartz/dartz.dart';

import '../model/failure/failures.dart';
import '../model/settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, Settings>> getSettings();

  Future<Either<Failure, Settings>> saveSettings(Settings settings);
}
