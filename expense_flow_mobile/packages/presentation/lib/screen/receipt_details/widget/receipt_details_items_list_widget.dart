import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:presentation/screen/receipt_details/widget/receipt_details_edit_dialog.dart';

import 'receipt_details_item_widget.dart';

class ReceiptDetailsItemsListWidget extends StatelessWidget {
  final Receipt receipt;
  final bool isEditMode;
  final Function(int index, ReceiptItem updatedItem) onItemUpdated;

  const ReceiptDetailsItemsListWidget({
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
        itemBuilder: (context, index) => ReceiptDetailsItemWidget(
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
      builder: (dialogContext) => ReceiptDetailsEditDialog(
        item: item,
        onSave: (updatedItem) {
          onItemUpdated(index, updatedItem);
        },
      ),
    );
  }
}
