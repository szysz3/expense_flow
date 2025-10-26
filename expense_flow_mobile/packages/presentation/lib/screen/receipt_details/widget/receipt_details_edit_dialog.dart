import 'package:domain/model/category.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/core/utils/category_utils.dart';

import '../../../core/utils/currency_text_formatter.dart';

class ReceiptDetailsEditDialog extends StatefulWidget {
  final ReceiptItem item;
  final Function(ReceiptItem) onSave;

  const ReceiptDetailsEditDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<ReceiptDetailsEditDialog> createState() =>
      _ReceiptDetailsEditDialogState();
}

class _ReceiptDetailsEditDialogState extends State<ReceiptDetailsEditDialog> {
  late final TextEditingController _descController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late String _selectedCategory;

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
    _selectedCategory = Category.ensureValid(widget.item.category);
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
            _buildCategoryDropdown(context),
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

  Widget _buildCategoryDropdown(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: l10n.category,
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
      dropdownColor: theme.colorScheme.surface,
      items: CategoryUtils.getAllCategoriesForDropdown(context)
          .map((entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
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
        category: _selectedCategory,
      );

      widget.onSave(updatedItem);
      Navigator.of(context).pop();
    }
  }
}
