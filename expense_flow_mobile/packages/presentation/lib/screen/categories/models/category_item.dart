import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_item.freezed.dart';

@freezed
class CategoryItem with _$CategoryItem {
  const factory CategoryItem({
    required String id,
    required String name,
    required double amount,
    @Default(1) int count,
  }) = _CategoryItem;
}
