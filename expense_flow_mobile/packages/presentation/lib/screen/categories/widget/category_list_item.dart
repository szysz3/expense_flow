import 'package:flutter/widgets.dart';
import 'package:presentation/screen/categories/models/category_item_data.dart';
import 'package:presentation/screen/categories/models/category_item_header_data.dart';

import '../../../core/widget/expandable_list_item/expandable_list_item.dart';
import '../models/category.dart';

class CategoryListItem extends StatelessWidget {
  final Category category;
  final VoidCallback onToggle;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableListItem<CategoryItemHeaderData, CategoryItemData>(
      headerData: CategoryItemHeaderData(category),
      items: category.items.map((i) => CategoryItemData(i)).toList(),
      onToggle: onToggle,
    );
  }
}
