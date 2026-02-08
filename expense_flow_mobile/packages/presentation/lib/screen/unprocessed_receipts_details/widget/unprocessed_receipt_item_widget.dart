import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:presentation/core/widget/glass_container.dart';

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
      iconBuilder: (context, theme) => GlassContainer(
        blur: 12,
        tintOpacity: 0.5,
        borderRadius: BorderRadius.circular(10),
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.receipt_long,
          size: 22,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
