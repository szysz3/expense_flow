import 'package:domain/model/category.dart';
import 'package:flutter/material.dart';
import 'package:presentation/core/utils/category_utils.dart';

class ReceiptFilteringCategoriesSection extends StatelessWidget {
  const ReceiptFilteringCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories', // TODO: Add to localization
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        const CategoryChips(),
      ],
    );
  }
}

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedCategories = <String>{}; // TODO: Get from state

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Category.all.map((categoryId) {
        final isSelected = selectedCategories.contains(categoryId);
        final displayName = CategoryUtils.getDisplayName(categoryId, context);

        return FilterChip(
          selected: isSelected,
          label: Text(
            displayName,
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          onSelected: (selected) {
            // TODO: Add bloc event
          },
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          selectedColor: Colors.white.withValues(alpha: 0.9),
          checkmarkColor: Colors.black,
          side: BorderSide(
            color:
                isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}
