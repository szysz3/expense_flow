import '../../../common/widget/expandable_list_item.dart';
import '../model/category_summary.dart';

class SummaryItemData implements ExpandableItemData {
  final CategorySummary category;

  SummaryItemData(this.category);

  @override
  String get name => category.name;

  @override
  double get amount => category.amount;
}
