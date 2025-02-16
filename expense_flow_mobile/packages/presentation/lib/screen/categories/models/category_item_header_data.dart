import '../../../common/widget/expandable_list_item/expandable_header_data.dart';
import 'category.dart';

class CategoryItemHeaderData implements ExpandableHeaderData {
  final Category category;

  CategoryItemHeaderData(this.category);

  @override
  String get title => category.name;

  @override
  String? get iconPath => category.iconName;

  @override
  bool get isExpanded => category.isExpanded;

  @override
  double get totalAmount => category.totalAmount;
}
