import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/currency_text_formatter.dart';

class BaseReceiptItemWidget extends StatelessWidget {
  final ReceiptItem item;
  final bool isEditMode;
  final int index;
  final Function(ReceiptItem) onEdit;
  final Widget Function(BuildContext, ThemeData) iconBuilder;
  final Widget Function(BuildContext, ThemeData)? categoryBuilder;

  const BaseReceiptItemWidget({
    super.key,
    required this.item,
    required this.isEditMode,
    required this.index,
    required this.onEdit,
    required this.iconBuilder,
    this.categoryBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = _buildItemContent(context, theme);

    if (isEditMode) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onEdit(item),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
            child: content,
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
        child: content,
      );
    }
  }

  Widget _buildItemContent(BuildContext context, ThemeData theme) {
    final locale = Localizations.localeOf(context).toString();
    var currencyFormatter = CurrencyTextFormatter(locale: locale);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        iconBuilder(context, theme),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (categoryBuilder != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    categoryBuilder!(context, theme),
                  ],
                )
              else
                Text(
                  item.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} × ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    currencyFormatter.formatCurrency(item.totalPrice),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        if (isEditMode)
          Icon(
            Icons.edit,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}
