import 'package:domain/model/receipt.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/core/utils/string_utils.dart';

import '../../../core/utils/currency_text_formatter.dart';

class ReceiptHeaderWidget extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback onTap;

  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _timeFormat = DateFormat('HH:mm');

  const ReceiptHeaderWidget({
    super.key,
    required this.receipt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: _buildContainer(context, theme),
      ),
    );
  }

  Widget _buildContainer(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(theme, context),
          const SizedBox(height: 8),
          _buildDateTimeRow(theme),
          const SizedBox(height: 8),
          _buildInfoRow(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(ThemeData theme, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    var currencyFormatter = CurrencyTextFormatter(locale: locale);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildMerchantName(theme, context),
        ),
        Text(
          currencyFormatter.formatCurrency(receipt.total),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow(ThemeData theme) {
    final date = receipt.transactionDateTime;
    final formattedDate = _dateFormat.format(date);
    final formattedTime = _timeFormat.format(date);

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(formattedDate, style: textStyle),
        Text(formattedTime, style: textStyle),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, ThemeData theme) {
    final topCategories = _getMostCommonCategories(2);

    return Row(
      children: [
        Text(
          '${receipt.items.length} items',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const Spacer(),
        if (topCategories.isNotEmpty) ...[
          _buildCategoryChips(context, topCategories),
          const SizedBox(width: 8),
        ],
        Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          size: 18,
        ),
      ],
    );
  }

  List<dynamic> _getMostCommonCategories(int count) {
    if (receipt.items.isEmpty) return [];

    final Map<dynamic, int> categoryCounts = {};
    for (var item in receipt.items) {
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
    }

    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.take(count).map((e) => e.key).toList();
  }

  Widget _buildCategoryChips(BuildContext context, List<dynamic> categories) {
    return Wrap(
      spacing: 4,
      children: categories.map((category) {
        return _buildCategoryChip(context, category.toString());
      }).toList(),
    );
  }

  Widget _buildMerchantName(ThemeData theme, BuildContext context) {
    String idText = receipt.id?.substring(0, 8) ?? "";
    String label = AppLocalizations.of(context).receiptIdLabel(idText);
    final textStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    if (receipt.merchant.name.isEmpty) {
      if (receipt.items.isNotEmpty) {
        return Text(
          receipt.items.first.description,
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
      return Text(
        label,
        style: textStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      receipt.merchant.name,
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCategoryChip(BuildContext context, String category) {
    final theme = Theme.of(context);
    final displayName = StringUtils.formatCategoryName(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: 10,
        ),
      ),
    );
  }
}
