import 'package:freezed_annotation/freezed_annotation.dart';

import '../util/date_comparison_utils.dart';

part 'savings_settings.freezed.dart';
part 'savings_settings.g.dart';

@freezed
class SavingsSettings with _$SavingsSettings {
  const factory SavingsSettings({
    required int startMonth,
    required int startYear,
    int? endMonth,
    int? endYear,
    @Default(0.0) double savingsAmount,
    @Default(0.0) double income,
  }) = _SavingsSettings;

  factory SavingsSettings.fromJson(Map<String, dynamic> json) =>
      _$SavingsSettingsFromJson(json);

  const SavingsSettings._();

  /// Checks if this savings period contains the specified month and year.
  bool containsMonth(int month, int year) {
    final startsBeforeOrEqual = DateComparisonUtils.isSameOrBefore(
      startYear,
      startMonth,
      year,
      month,
    );

    if (!startsBeforeOrEqual) {
      return false;
    }

    // If period is open-ended, it contains all months after start
    if (endMonth == null || endYear == null) {
      return true;
    }

    return DateComparisonUtils.isSameOrAfter(
      endYear!,
      endMonth!,
      year,
      month,
    );
  }
}
