import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/utils/category_utils.dart';

class ReceiptDetailsItemWidget extends StatelessWidget {
  final ReceiptItem item;
  final bool isEditMode;
  final int index;
  final Function(ReceiptItem) onEdit;

  const ReceiptDetailsItemWidget({
    super.key,
    required this.item,
    required this.isEditMode,
    required this.index,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final categoryIconPath = CategoryUtils.getIconPath(item.category);
    final categoryName = CategoryUtils.getDisplayName(item.category, context);
    final content = _buildItemContent(context, categoryIconPath, categoryName);

    if (isEditMode) {
      return InkWell(
        onTap: () => onEdit(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          child: content,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        child: content,
      );
    }
  }

  Widget _buildItemContent(
      BuildContext context, String categoryIconPath, String categoryName) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            categoryIconPath,
            width: 24,
            height: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    categoryName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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
                    item.totalPrice.toStringAsFixed(2),
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
