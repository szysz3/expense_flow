/// Utility class for comparing month/year dates.
class DateComparisonUtils {
  DateComparisonUtils._();

  /// Checks if the left date (leftYear/leftMonth) is the same as or before the right date (rightYear/rightMonth).
  static bool isSameOrBefore(
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

  /// Checks if the left date (leftYear/leftMonth) is the same as or after the right date (rightYear/rightMonth).
  static bool isSameOrAfter(
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

  /// Checks if the left date (leftYear/leftMonth) is before the right date (rightYear/rightMonth).
  static bool isBefore(
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
    return leftMonth < rightMonth;
  }

  /// Checks if the left date (leftYear/leftMonth) is after the right date (rightYear/rightMonth).
  static bool isAfter(
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
    return leftMonth > rightMonth;
  }
}
