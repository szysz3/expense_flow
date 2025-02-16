import '../../../common/widget/expandable_list_item.dart';
import '../models/category_item.dart';

class CategoryItemData implements ExpandableItemData {
  final CategoryItem item;

  CategoryItemData(this.item);

  @override
  String get name => item.name;

  @override
  double get amount => item.amount;
}
