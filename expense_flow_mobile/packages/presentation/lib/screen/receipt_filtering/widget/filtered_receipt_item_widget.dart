import 'package:domain/model/filtered_receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presentation/core/utils/string_utils.dart';
import 'package:presentation/core/widget/glass_container.dart';
import 'package:presentation/core/widget/app_spacing.dart';
import 'package:presentation/core/widget/glass_container.dart';

import '../../../core/utils/currency_text_formatter.dart';

class FilteredReceiptItemWidget extends StatelessWidget {
  final FilteredReceiptItem item;

  static final _dateFormat = DateFormat('MMM d, yyyy');

  const FilteredReceiptItemWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final currencyFormatter = CurrencyTextFormatter(locale: locale);

    return GlassContainer(
      blur: 16,
      tintOpacity: 0.5,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                currencyFormatter.formatCurrency(item.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (item.category != null) ...[
                _buildCategoryChip(context, item.category!),
                const SizedBox(width: 8),
              ],
              Text(
                _dateFormat.format(item.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  item.merchantName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String category) {
    final theme = Theme.of(context);
    final displayName = StringUtils.formatCategoryName(category);

    return GlassContainer(
      blur: 8,
      tintOpacity: 0.35,
      borderRadius: BorderRadius.circular(6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 10,
        ),
      ),
    );
  }
}
