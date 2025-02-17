import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_summary.freezed.dart';
part 'category_summary.g.dart';

@freezed
class CategorySummary with _$CategorySummary {
  const factory CategorySummary({
    required String id,
    required String name,
    required String iconName,
    required double amount,
    required double previousMonthAmount,
  }) = _CategorySummary;

  factory CategorySummary.fromJson(Map<String, dynamic> json) =>
      _$CategorySummaryFromJson(json);
}
