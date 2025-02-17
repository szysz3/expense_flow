import 'package:freezed_annotation/freezed_annotation.dart';

import 'category_item.dart';

part 'category_with_items.freezed.dart';
part 'category_with_items.g.dart';

@freezed
class CategoryWithItems with _$CategoryWithItems {
  const factory CategoryWithItems({
    required String id,
    required String name,
    required String iconName,
    required List<CategoryItem> items,
  }) = _CategoryWithItems;

  factory CategoryWithItems.fromJson(Map<String, dynamic> json) =>
      _$CategoryWithItemsFromJson(json);
}
