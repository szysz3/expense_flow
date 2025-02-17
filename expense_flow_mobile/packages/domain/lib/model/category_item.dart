import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_item.freezed.dart';
part 'category_item.g.dart';

@freezed
class CategoryItem with _$CategoryItem {
  const factory CategoryItem({
    required String id,
    required String name,
    required double amount,
    @Default(1) int count,
  }) = _CategoryItem;

  factory CategoryItem.fromJson(Map<String, dynamic> json) =>
      _$CategoryItemFromJson(json);
}
