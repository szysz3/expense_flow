import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:presentation/core/widget/glass_container.dart';
import 'package:presentation/core/widget/staggered_slide_fade.dart';
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

    return GlassContainer(
      blur: 14,
      tintOpacity: 0.45,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        physics: const ClampingScrollPhysics(),
        itemCount: receipt.items.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(left: 56, right: 16),
          child: Divider(
            color: theme.colorScheme.outline.withValues(alpha: 0.25),
            height: 16,
          ),
        ),
        itemBuilder: (context, index) => StaggeredSlideFade(
          index: index,
          child: ReceiptDetailsItemWidget(
            item: receipt.items[index],
            isEditMode: isEditMode,
            index: index,
            onEdit: (item) => _showEditItemDialog(context, item, index),
          ),
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
