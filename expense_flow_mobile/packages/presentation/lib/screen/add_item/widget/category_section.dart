import 'package:flutter/material.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../model/expense_category.dart';
import 'category_button.dart';

class CategorySection extends StatelessWidget {
  final ExpenseCategory? selectedCategory;
  final Function(ExpenseCategory) onCategorySelected;

  const CategorySection({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).category,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
              children: ExpenseCategory.values.map((category) {
                final isSelected = selectedCategory == category;
                return CategoryButton(
                  icon:
                      'packages/presentation/assets/icon_${category.name}.svg',
                  label: _getCategoryLabel(context, category),
                  isSelected: isSelected,
                  onPressed: () => onCategorySelected(category),
                );
              }).toList(),
            ),
          ],
        ),
      );

  String _getCategoryLabel(BuildContext context, ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.groceries:
        return AppLocalizations.of(context).groceries;
      case ExpenseCategory.alcoholic_beverages:
        return AppLocalizations.of(context).alcohol;
      case ExpenseCategory.personal_care:
        return AppLocalizations.of(context).personalCare;
      case ExpenseCategory.household:
        return AppLocalizations.of(context).household;
      case ExpenseCategory.clothing:
        return AppLocalizations.of(context).clothing;
      case ExpenseCategory.entertainment:
        return AppLocalizations.of(context).entertainment;
      case ExpenseCategory.transportation:
        return AppLocalizations.of(context).transportation;
      case ExpenseCategory.pet:
        return AppLocalizations.of(context).pet;
      case ExpenseCategory.other:
        return AppLocalizations.of(context).other;
      case ExpenseCategory.standing_orders:
        return AppLocalizations.of(context).standingOrders;
    }
  }
}
