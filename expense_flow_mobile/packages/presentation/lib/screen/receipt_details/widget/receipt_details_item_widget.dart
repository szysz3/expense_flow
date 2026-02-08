import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:presentation/core/widget/glass_container.dart';

import '../../../core/utils/category_utils.dart';
import '../../../core/widget/receipt/base_receipt_item_widget.dart';

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
        child: SvgPicture.asset(
          categoryIconPath,
          width: 22,
          height: 22,
          colorFilter: ColorFilter.mode(
            theme.colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),
      ),
      categoryBuilder: (context, theme) => Text(
        categoryName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
