import '../../../core/widget/expandable_list_item/expandable_item_data.dart';
import 'category_item.dart';

class CategoryItemData implements ExpandableItemData {
  final CategoryItem item;

  CategoryItemData(this.item);

  @override
  String get name => item.name;

  @override
  double get amount => item.amount;

  @override
  int get count => item.count;
}
