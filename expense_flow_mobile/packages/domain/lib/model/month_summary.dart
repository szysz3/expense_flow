import 'package:freezed_annotation/freezed_annotation.dart';

import 'category_summary.dart';

part 'month_summary.freezed.dart';
part 'month_summary.g.dart';

@freezed
class MonthSummary with _$MonthSummary {
  const factory MonthSummary({
    required String id,
    required int monthNumber,
    required int year,
    required double previousMonthTotal,
    required List<CategorySummary> categories,
  }) = _MonthSummary;

  factory MonthSummary.fromJson(Map<String, dynamic> json) =>
      _$MonthSummaryFromJson(json);
}
