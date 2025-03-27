import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
class Settings with _$Settings {
  const factory Settings({
    @Default(0.0) double savingsAmount,
    @Default(0.0) double income,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}
