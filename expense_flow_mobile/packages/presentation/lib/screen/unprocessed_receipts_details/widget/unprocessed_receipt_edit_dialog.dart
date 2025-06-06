import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:localization/app_localizations.dart';

import '../../../core/utils/currency_text_formatter.dart';

class UnprocessedReceiptEditDialog extends StatefulWidget {
  final ReceiptItem item;
  final Function(ReceiptItem) onSave;

  const UnprocessedReceiptEditDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<UnprocessedReceiptEditDialog> createState() =>
      _UnprocessedReceiptEditDialogState();
}

class _UnprocessedReceiptEditDialogState
    extends State<UnprocessedReceiptEditDialog> {
  late final TextEditingController _descController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.item.description);
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: widget.item.totalPrice.toString(),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        l10n.editItem,
        style: theme.textTheme.titleLarge,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: l10n.description,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: l10n.quantity,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [CurrencyTextFormatter(locale: locale)],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: l10n.totalPrice,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [CurrencyTextFormatter(locale: locale)],
            ),
            const SizedBox(height: 16),
            Container(
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
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _saveItem,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  void _saveItem() {
    final description = _descController.text;
    final quantity = _quantityController.text.isEmpty
        ? widget.item.quantity
        : double.tryParse(_quantityController.text) ?? widget.item.quantity;
    final price = _priceController.text.isEmpty
        ? widget.item.totalPrice
        : double.tryParse(_priceController.text) ?? widget.item.totalPrice;

    if (description.isNotEmpty && price > 0) {
      final updatedItem = ReceiptItem(
        description: description,
        quantity: quantity,
        totalPrice: price,
        category: widget.item.category,
      );

      widget.onSave(updatedItem);
      Navigator.of(context).pop();
    }
  }
}
