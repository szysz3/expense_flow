import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localization/app_localizations.dart';

import '../../../core/utils/currency_text_formatter.dart';
import '../../widget/glass_container.dart';

class BaseReceiptEditDialog extends StatefulWidget {
  final ReceiptItem item;
  final Function(ReceiptItem) onSave;
  final Widget Function(BuildContext, ThemeData)? categorySelector;
  final Widget Function(BuildContext, ThemeData)? infoNote;

  const BaseReceiptEditDialog({
    super.key,
    required this.item,
    required this.onSave,
    this.categorySelector,
    this.infoNote,
  });

  @override
  State<BaseReceiptEditDialog> createState() => _BaseReceiptEditDialogState();
}

class _BaseReceiptEditDialogState extends State<BaseReceiptEditDialog> {
  late final TextEditingController _descController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  String? _selectedCategory;

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
    _selectedCategory = widget.item.category;
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: GlassContainer(
        blur: 24,
        tintOpacity: 0.75,
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.editItem,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: _descController,
                    labelText: l10n.description,
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _quantityController,
                    labelText: l10n.quantity,
                    theme: theme,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [CurrencyTextFormatter(locale: locale)],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _priceController,
                    labelText: l10n.totalPrice,
                    theme: theme,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [CurrencyTextFormatter(locale: locale)],
                  ),
                  if (widget.categorySelector != null) ...[
                    const SizedBox(height: 12),
                    widget.categorySelector!(context, theme),
                  ],
                  if (widget.infoNote != null) ...[
                    const SizedBox(height: 12),
                    widget.infoNote!(context, theme),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => _saveItem(context),
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required ThemeData theme,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: labelText,
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
    );
  }

  void updateSelectedCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _saveItem(BuildContext context) {
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
        category: _selectedCategory ?? widget.item.category,
      );

      widget.onSave(updatedItem);
      Navigator.of(context).pop();
    }
  }
}
