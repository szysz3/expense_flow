import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_event.freezed.dart';

@freezed
class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.init() = InitEvent;

  const factory SettingsEvent.savingsAmountChanged(String amount) =
      SavingsAmountChangedEvent;

  const factory SettingsEvent.incomeChanged(String income) = IncomeChangedEvent;

  const factory SettingsEvent.saveSettings() = SaveSettingsEvent;
}
