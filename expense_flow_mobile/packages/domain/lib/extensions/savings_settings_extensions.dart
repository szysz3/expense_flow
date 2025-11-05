import '../model/savings_settings.dart';

extension SavingsSettingsListExtension on List<SavingsSettings> {
  /// Finds the first period that contains the specified month and year.
  /// Returns null if no matching period is found.
  SavingsSettings? findPeriodForMonth(int month, int year) {
    for (final period in this) {
      if (period.containsMonth(month, year)) {
        return period;
      }
    }
    return null;
  }

  /// Sorts the list of savings settings by start date (year, then month).
  /// Returns a new sorted list without modifying the original.
  List<SavingsSettings> sortedByStartDate() {
    final sorted = toList();
    sorted.sort((a, b) {
      final yearComparison = a.startYear.compareTo(b.startYear);
      if (yearComparison != 0) {
        return yearComparison;
      }
      return a.startMonth.compareTo(b.startMonth);
    });
    return sorted;
  }
}
