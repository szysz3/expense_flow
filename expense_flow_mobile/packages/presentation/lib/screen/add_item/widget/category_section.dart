import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../bloc/add_item_bloc.dart';
import '../bloc/add_item_event.dart';
import '../bloc/add_item_state.dart';
import 'category_button.dart';

// TODO: decouple view from BLoC
class CategorySection extends StatelessWidget {
  final AddItemState state;

  const CategorySection({
    super.key,
    required this.state,
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
              children: ItemCategory.values.map((category) {
                final isSelected = state.selectedCategory == category;
                return CategoryButton(
                  icon:
                      'packages/presentation/assets/icon_${category.name}.svg',
                  label: _getCategoryLabel(context, category),
                  isSelected: isSelected,
                  onPressed: () => context.read<AddItemBloc>().add(
                        AddItemEvent.categorySelected(category),
                      ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  String _getCategoryLabel(BuildContext context, ItemCategory category) {
    switch (category) {
      case ItemCategory.groceries:
        return AppLocalizations.of(context).groceries;
      case ItemCategory.alcoholic_beverages:
        return AppLocalizations.of(context).alcohol;
      case ItemCategory.personal_care:
        return AppLocalizations.of(context).personalCare;
      case ItemCategory.household:
        return AppLocalizations.of(context).household;
      case ItemCategory.clothing:
        return AppLocalizations.of(context).clothing;
      case ItemCategory.entertainment:
        return AppLocalizations.of(context).entertainment;
      case ItemCategory.transportation:
        return AppLocalizations.of(context).transportation;
      case ItemCategory.pet:
        return AppLocalizations.of(context).pet;
      case ItemCategory.other:
        return AppLocalizations.of(context).other;
      case ItemCategory.standing_orders:
        return AppLocalizations.of(context).standingOrders;
    }
  }
}
