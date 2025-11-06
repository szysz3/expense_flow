/// Represents a specific month and year.
class MonthYear {
  final int month;
  final int year;

  const MonthYear(this.month, this.year)
      : assert(month >= 1 && month <= 12, 'Month must be between 1 and 12');

  /// Creates a MonthYear from the current date.
  factory MonthYear.now() {
    final now = DateTime.now();
    return MonthYear(now.month, now.year);
  }

  /// Returns the next month, incrementing year if necessary.
  MonthYear increment() {
    if (month == 12) {
      return MonthYear(1, year + 1);
    }
    return MonthYear(month + 1, year);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYear &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => month.hashCode ^ year.hashCode;

  @override
  String toString() => '$month/$year';
}
