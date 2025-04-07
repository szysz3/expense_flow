import 'package:freezed_annotation/freezed_annotation.dart';

part 'savings_settings.freezed.dart';
part 'savings_settings.g.dart';

@freezed
class SavingsSettings with _$SavingsSettings {
  const factory SavingsSettings({
    required int month,
    required int year,
    @Default(0.0) double savingsAmount,
    @Default(0.0) double income,
  }) = _SavingsSettings;

  factory SavingsSettings.fromJson(Map<String, dynamic> json) =>
      _$SavingsSettingsFromJson(json);
}
