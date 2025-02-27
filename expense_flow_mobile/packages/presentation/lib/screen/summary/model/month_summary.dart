import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:presentation/screen/summary/model/category_summary.dart';

part 'month_summary.freezed.dart';

@freezed
class MonthSummary with _$MonthSummary {
  const factory MonthSummary({
    required String id,
    required String month,
    required List<CategorySummary> categories,
    required double previousMonthAmount,
    @Default(false) bool isExpanded,
  }) = _MonthSummary;

  const MonthSummary._();

  double get totalAmount =>
      categories.fold(0.0, (sum, cat) => sum + cat.amount);

  double get changePercentage {
    if (previousMonthAmount == 0) {
      return totalAmount > 0 ? 100 : 0;
    } else {
      return ((totalAmount - previousMonthAmount) / previousMonthAmount) * 100;
    }
  }

  bool get isIncrease => totalAmount > previousMonthAmount;
}
