import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:localization/app_localizations.dart';

import '../../../core/widget/receipt/base_receipt_edit_dialog.dart';

class UnprocessedReceiptEditDialog extends StatelessWidget {
  final ReceiptItem item;
  final Function(ReceiptItem) onSave;

  const UnprocessedReceiptEditDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BaseReceiptEditDialog(
      item: item,
      onSave: onSave,
      infoNote: (context, theme) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.unprocessedReceiptCategoryNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
