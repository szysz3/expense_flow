import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';

import '../widget/unprocessed_receipt_edit_dialog.dart';
import '../widget/unprocessed_receipt_item_widget.dart';

class UnprocessedReceiptItemsListWidget extends StatelessWidget {
  final Receipt receipt;
  final bool isEditMode;
  final Function(int index, ReceiptItem updatedItem) onItemUpdated;

  const UnprocessedReceiptItemsListWidget({
    super.key,
    required this.receipt,
    required this.isEditMode,
    required this.onItemUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        physics: const ClampingScrollPhysics(),
        itemCount: receipt.items.length,
        separatorBuilder: (_, __) => Divider(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          height: 1,
        ),
        itemBuilder: (context, index) => UnprocessedReceiptItemWidget(
          item: receipt.items[index],
          isEditMode: isEditMode,
          index: index,
          onEdit: (item) => _showEditItemDialog(context, item, index),
        ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, ReceiptItem item, int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => UnprocessedReceiptEditDialog(
        item: item,
        onSave: (updatedItem) {
          onItemUpdated(index, updatedItem);
        },
      ),
    );
  }
}
