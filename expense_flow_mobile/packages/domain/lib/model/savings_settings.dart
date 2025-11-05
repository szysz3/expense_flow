import 'package:freezed_annotation/freezed_annotation.dart';

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

  bool containsMonth(int month, int year) {
    final startsBeforeOrEqual =
        _isSameOrBefore(startYear, startMonth, year, month);

    if (!startsBeforeOrEqual) {
      return false;
    }

    if (endMonth == null || endYear == null) {
      return true;
    }

    return _isSameOrAfter(endYear!, endMonth!, year, month);
  }

  bool _isSameOrBefore(
    int leftYear,
    int leftMonth,
    int rightYear,
    int rightMonth,
  ) {
    if (leftYear < rightYear) {
      return true;
    }
    if (leftYear > rightYear) {
      return false;
    }
    return leftMonth <= rightMonth;
  }

  bool _isSameOrAfter(
    int leftYear,
    int leftMonth,
    int rightYear,
    int rightMonth,
  ) {
    if (leftYear > rightYear) {
      return true;
    }
    if (leftYear < rightYear) {
      return false;
    }
    return leftMonth >= rightMonth;
  }
}
