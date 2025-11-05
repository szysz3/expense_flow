import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_event.freezed.dart';

@freezed
class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.init() = InitEvent;

  const factory SettingsEvent.periodAdded() = PeriodAddedEvent;

  const factory SettingsEvent.periodRemoved(String id) = PeriodRemovedEvent;

  const factory SettingsEvent.periodStartChanged({
    required String id,
    required int month,
    required int year,
  }) = PeriodStartChangedEvent;

  const factory SettingsEvent.periodEndChanged({
    required String id,
    int? month,
    int? year,
  }) = PeriodEndChangedEvent;

  const factory SettingsEvent.periodIncomeChanged({
    required String id,
    required String income,
  }) = PeriodIncomeChangedEvent;

  const factory SettingsEvent.periodSavingsChanged({
    required String id,
    required String savings,
  }) = PeriodSavingsChangedEvent;

  const factory SettingsEvent.toggleOpenEnded(String id) = ToggleOpenEndedEvent;

  const factory SettingsEvent.saveSettings() = SaveSettingsEvent;
}
