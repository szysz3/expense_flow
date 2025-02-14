import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_summary.freezed.dart';

@freezed
class CategorySummary with _$CategorySummary {
  const factory CategorySummary({
    required String id,
    required String name,
    required double amount,
  }) = _CategorySummary;
}
