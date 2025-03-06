import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../bloc/add_item_bloc.dart';
import '../bloc/add_item_event.dart';

// TODO: decouple view from BLoC
class QuantityPriceSection extends StatelessWidget {
  final TextEditingController quantityController;
  final TextEditingController priceController;

  const QuantityPriceSection({
    super.key,
    required this.quantityController,
    required this.priceController,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: quantityController,
                onChanged: (value) => context.read<AddItemBloc>().add(
                      AddItemEvent.quantityChanged(value),
                    ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).quantity,
                  hintText: AppLocalizations.of(context).enterQuantity,
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPriceField(context),
            ),
          ],
        ),
      );

  Widget _buildPriceField(BuildContext context) => TextField(
        controller: priceController,
        onChanged: (value) {
          final locale = Localizations.localeOf(context);
          final format = NumberFormat.decimalPattern(locale.toString());
          final decimalSeparator = format.symbols.DECIMAL_SEP;
          String normalizedValue = value;
          if (decimalSeparator != '.') {
            normalizedValue = value.replaceAll(decimalSeparator, '.');
          }

          context.read<AddItemBloc>().add(
                AddItemEvent.priceChanged(normalizedValue),
              );
        },
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).totalPrice,
          hintText: AppLocalizations.of(context).enterPrice,
          border: InputBorder.none,
        ),
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) {
            final locale = Localizations.localeOf(context);
            final format = NumberFormat.decimalPattern(locale.toString());
            final decimalSeparator = format.symbols.DECIMAL_SEP;
            final regExp = RegExp('[0-9.,]');

            String filtered = newValue.text
                .split('')
                .where((char) => regExp.hasMatch(char))
                .join();

            if (filtered.contains('.') || filtered.contains(',')) {
              filtered = filtered
                  .replaceAll(',', decimalSeparator)
                  .replaceAll('.', decimalSeparator);

              final parts = filtered.split(decimalSeparator);
              if (parts.length > 2) {
                filtered =
                    parts[0] + decimalSeparator + parts.sublist(1).join('');
              }
            }

            return newValue.copyWith(
              text: filtered,
              selection: TextSelection.collapsed(offset: filtered.length),
            );
          }),
        ],
      );
}
