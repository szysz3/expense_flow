import 'package:domain/model/category.dart';
import 'package:flutter/material.dart';
import 'package:presentation/core/utils/category_utils.dart';

import 'category_button.dart';

class CategorySection extends StatelessWidget {
  final String? selectedCategory;
  final Function(String) onCategorySelected;

  const CategorySection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: Category.all.map((categoryId) {
            final isSelected = selectedCategory == categoryId;
            return CategoryButton(
              icon: CategoryUtils.getIconPath(categoryId),
              label: CategoryUtils.getDisplayName(categoryId, context),
              isSelected: isSelected,
              onPressed: () => onCategorySelected(categoryId),
            );
          }).toList(),
        ),
      );
}
