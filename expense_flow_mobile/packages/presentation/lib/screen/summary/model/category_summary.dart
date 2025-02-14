import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'category_summary.freezed.dart';

@freezed
class CategorySummary with _$CategorySummary {
  const factory CategorySummary({
    required String id,
    required String name,
    required String iconName,
    required double amount,
    required double previousMonthAmount,
  }) = _CategorySummary;

  const CategorySummary._();

  double get changePercentage {
    if (previousMonthAmount == 0) return 0;
    return ((amount - previousMonthAmount) / previousMonthAmount) * 100;
  }

  bool get isIncrease => amount > previousMonthAmount;
}