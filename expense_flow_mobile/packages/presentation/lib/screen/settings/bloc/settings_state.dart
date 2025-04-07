import 'package:domain/model/savings_settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'settings_state.freezed.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    @Default(0.0) double savingsAmount,
    @Default(0.0) double income,
    AppError? error,
  }) = _SettingsState;

  const SettingsState._();

  SavingsSettings toSavingsSettings() {
    final now = DateTime.now();
    return SavingsSettings(
      month: now.month,
      year: now.year,
      savingsAmount: savingsAmount,
      income: income,
    );
  }
}
