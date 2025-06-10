import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';

import '../../../core/widget/receipt/base_receipt_item_widget.dart';

class UnprocessedReceiptItemWidget extends StatelessWidget {
  final ReceiptItem item;
  final bool isEditMode;
  final int index;
  final Function(ReceiptItem) onEdit;

  const UnprocessedReceiptItemWidget({
    super.key,
    required this.item,
    required this.isEditMode,
    required this.index,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return BaseReceiptItemWidget(
      item: item,
      isEditMode: isEditMode,
      index: index,
      onEdit: onEdit,
      iconBuilder: (context, theme) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.receipt_long,
          size: 24,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
