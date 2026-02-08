import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localization/app_localizations.dart';

import '../../../core/utils/currency_text_formatter.dart';

class BaseReceiptTransactionInfoWidget extends StatelessWidget {
  final DateTime? transactionDateTime;
  final DateTime fallbackDateTime;
  final double total;
  final bool isEditMode;
  final TextEditingController totalController;
  final Function(DateTime) onDateTimeSelected;
  final Function(double) onTotalChanged;

  const BaseReceiptTransactionInfoWidget({
    super.key,
    required this.transactionDateTime,
    required this.fallbackDateTime,
    required this.total,
    required this.isEditMode,
    required this.totalController,
    required this.onDateTimeSelected,
    required this.onTotalChanged,
  });

  DateTime get _effectiveDateTime => transactionDateTime ?? fallbackDateTime;

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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Text(
              dateFormat.format(_effectiveDateTime),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
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
    final locale = Localizations.localeOf(context).toString();
    var currencyFormatter = CurrencyTextFormatter(locale: locale);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            theme,
            label: l10n.transactionDate,
            value: dateFormat.format(_effectiveDateTime),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            theme,
            label: l10n.totalChartData,
            value: currencyFormatter.formatCurrency(total),
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: isHighlighted
              ? theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _showDateTimePicker(BuildContext context) async {
    final currentDate = _effectiveDateTime;

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
