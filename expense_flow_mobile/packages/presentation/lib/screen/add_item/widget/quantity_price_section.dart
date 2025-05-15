import 'package:flutter/material.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../../../core/utils/currency_text_formatter.dart';

class QuantityPriceSection extends StatelessWidget {
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final Function(String) onQuantityChanged;
  final Function(String) onPriceChanged;

  const QuantityPriceSection({
    super.key,
    required this.quantityController,
    required this.priceController,
    required this.onQuantityChanged,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildQuantityField(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPriceField(context),
            ),
          ],
        ),
      );

  Widget _buildQuantityField(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return TextField(
      controller: quantityController,
      onChanged: (value) {
        if (value.isNotEmpty) {
          final normalizedValue =
              CurrencyTextFormatter.normalizeNumberString(value, locale);
          onQuantityChanged(normalizedValue);
        } else {
          onQuantityChanged(value);
        }
      },
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      inputFormatters: [
        CurrencyTextFormatter(locale: locale),
      ],
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).quantity,
        hintText: AppLocalizations.of(context).enterQuantity,
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildPriceField(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return TextField(
      controller: priceController,
      onChanged: (value) {
        if (value.isNotEmpty) {
          final normalizedValue =
              CurrencyTextFormatter.normalizeNumberString(value, locale);
          onPriceChanged(normalizedValue);
        } else {
          onPriceChanged(value);
        }
      },
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      inputFormatters: [
        CurrencyTextFormatter(locale: locale),
      ],
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).totalPrice,
        hintText: AppLocalizations.of(context).enterPrice,
        border: InputBorder.none,
      ),
    );
  }
}
