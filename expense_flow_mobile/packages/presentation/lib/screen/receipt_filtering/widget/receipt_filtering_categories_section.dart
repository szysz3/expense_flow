import 'package:domain/model/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/core/utils/category_utils.dart';
import 'package:presentation/core/widget/app_spacing.dart';

import '../bloc/receipt_filtering_bloc.dart';
import '../bloc/receipt_filtering_event.dart';
import '../bloc/receipt_filtering_state.dart';

class ReceiptFilteringCategoriesSection extends StatelessWidget {
  const ReceiptFilteringCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.categoriesFilterLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        BlocBuilder<ReceiptFilteringBloc, ReceiptFilteringState>(
          builder: (context, state) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Category.all.map((categoryId) {
                final isSelected =
                    state.filterParams.categories.contains(categoryId);
                final displayName =
                    CategoryUtils.getDisplayName(categoryId, context);

                return FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  label: Text(
                    displayName,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  onSelected: (selected) {
                    context.read<ReceiptFilteringBloc>().add(
                          ReceiptFilteringEvent.toggleCategory(categoryId),
                        );
                  },
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.6),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.4),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
