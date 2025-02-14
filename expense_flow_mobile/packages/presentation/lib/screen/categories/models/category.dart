import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'category_item.dart';

part 'category.freezed.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String iconName,
    required List<CategoryItem> items,
    @Default(false) bool isExpanded,
  }) = _Category;

  const Category._();

  double get totalAmount => items.fold(0.0, (sum, item) => sum + item.amount);
}
