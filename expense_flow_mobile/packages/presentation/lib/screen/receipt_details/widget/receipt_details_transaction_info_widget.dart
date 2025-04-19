import 'package:domain/model/receipt.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../../../core/utils/currency_text_formatter.dart';
import 'receipt_details_info_row.dart';

class ReceiptDetailsTransactionInfoWidget extends StatelessWidget {
  final Receipt receipt;
  final bool isEditMode;
  final TextEditingController totalController;
  final Function(DateTime) onDateTimeSelected;
  final Function(double) onTotalChanged;

  const ReceiptDetailsTransactionInfoWidget({
    super.key,
    required this.receipt,
    required this.isEditMode,
    required this.totalController,
    required this.onDateTimeSelected,
    required this.onTotalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return isEditMode
        ? _buildEditView(context, theme)
        : _buildReadOnlyView(context, theme);
  }

  Widget _buildEditView(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMMM dd, yyyy - HH:mm');
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showDateTimePicker(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.transactionDate,
              suffixIcon: Icon(
                Icons.calendar_today,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
            child: Text(
              dateFormat.format(receipt.transactionDateTime),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: totalController,
          decoration: InputDecoration(
            labelText: l10n.totalChartData,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyTextFormatter(locale: locale)],
          onChanged: (value) {},
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              final parsedValue = double.tryParse(value.replaceAll(',', '.'));
              if (parsedValue != null) {
                onTotalChanged(parsedValue);
              }
            } else {
              onTotalChanged(0.0);
            }
          },
        )
      ],
    );
  }

  Widget _buildReadOnlyView(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMMM dd, yyyy - HH:mm');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReceiptDetailsInfoRow(
            label: l10n.transactionDate,
            value: dateFormat.format(receipt.transactionDateTime),
          ),
          const SizedBox(height: 8),
          ReceiptDetailsInfoRow(
            label: l10n.totalChartData,
            value: receipt.total.toStringAsFixed(2),
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  void _showDateTimePicker(BuildContext context) async {
    final currentDate = receipt.transactionDateTime;

    final date = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDate),
      );

      if (time != null && context.mounted) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        onDateTimeSelected(newDateTime);
      }
    }
  }
}
