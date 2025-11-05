import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/settings.dart';
import 'package:domain/repository/settings_repository.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _settingsKey = 'expense_flow_settings';

class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _sharedPreferences;
  final Logger _logger;

  SettingsRepositoryImpl({
    required SharedPreferences sharedPreferences,
    required Logger logger,
  })  : _sharedPreferences = sharedPreferences,
        _logger = logger;

  @override
  Future<Either<Failure, Settings>> getSettings() async {
    try {
      final settingsJson = _sharedPreferences.getString(_settingsKey);

      if (settingsJson == null) {
        // Return default settings if none found
        return Right(
          const Settings(version: settingsCurrentVersion, savingsSettings: []),
        );
      }

      final Map<String, dynamic> decodedJson = jsonDecode(settingsJson);
      final settings = Settings.fromJson(decodedJson);
      return Right(settings);
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to get settings',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Failed to load settings: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Settings>> saveSettings(Settings settings) async {
    try {
      final encodedJson = jsonEncode(settings.toJson());

      final success =
          await _sharedPreferences.setString(_settingsKey, encodedJson);

      if (success) {
        return Right(settings);
      } else {
        return Left(ServerFailure('Failed to save settings'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to save settings',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Failed to save settings: ${e.toString()}'));
    }
  }
}
