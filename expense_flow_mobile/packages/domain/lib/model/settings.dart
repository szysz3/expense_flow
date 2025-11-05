import 'package:domain/model/savings_settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

const int settingsCurrentVersion = 2;

@freezed
class Settings with _$Settings {
  const factory Settings({
    int? version,
    List<SavingsSettings>? savingsSettings,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}
