import 'package:domain/model/savings_settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'settings_state.freezed.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    @Default([]) List<SettingsPeriodForm> periods,
    String? validationMessage,
    AppError? error,
  }) = _SettingsState;

  const SettingsState._();

  List<SavingsSettings> toSavingsSettingsList() {
    return periods
        .map((period) => period.toSavingsSettings())
        .toList(growable: false);
  }
}

class SettingsPeriodForm {
  final String id;
  final int startMonth;
  final int startYear;
  final int? endMonth;
  final int? endYear;
  final double savingsAmount;
  final double income;

  const SettingsPeriodForm({
    required this.id,
    required this.startMonth,
    required this.startYear,
    this.endMonth,
    this.endYear,
    this.savingsAmount = 0.0,
    this.income = 0.0,
  });

  factory SettingsPeriodForm.fromSavingsSettings(
    SavingsSettings settings, {
    required String id,
  }) {
    return SettingsPeriodForm(
      id: id,
      startMonth: settings.startMonth,
      startYear: settings.startYear,
      endMonth: settings.endMonth,
      endYear: settings.endYear,
      savingsAmount: settings.savingsAmount,
      income: settings.income,
    );
  }

  SettingsPeriodForm copyWith({
    String? id,
    int? startMonth,
    int? startYear,
    int? endMonth,
    int? endYear,
    double? savingsAmount,
    double? income,
    bool clearEnd = false,
  }) {
    return SettingsPeriodForm(
      id: id ?? this.id,
      startMonth: startMonth ?? this.startMonth,
      startYear: startYear ?? this.startYear,
      endMonth: clearEnd ? null : (endMonth ?? this.endMonth),
      endYear: clearEnd ? null : (endYear ?? this.endYear),
      savingsAmount: savingsAmount ?? this.savingsAmount,
      income: income ?? this.income,
    );
  }

  bool get isOpenEnded => endMonth == null || endYear == null;

  SavingsSettings toSavingsSettings() {
    return SavingsSettings(
      startMonth: startMonth,
      startYear: startYear,
      endMonth: endMonth,
      endYear: endYear,
      savingsAmount: savingsAmount,
      income: income,
    );
  }
}
