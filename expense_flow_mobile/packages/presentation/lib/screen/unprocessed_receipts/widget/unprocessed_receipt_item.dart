import 'package:domain/model/unprocessed_receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_text_formatter.dart';

class UnprocessedReceiptItem extends StatelessWidget {
  final UnprocessedReceipt receipt;
  final VoidCallback? onTap;

  const UnprocessedReceiptItem({
    required this.receipt,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildStatusIcon(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateTime(context),
                    if (receipt.status == UnprocessedReceiptStatus.error &&
                        receipt.errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        receipt.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildAmount(context),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    String iconName;
    Color iconColor;
    switch (receipt.status) {
      case UnprocessedReceiptStatus.pending:
        iconName = 'icon_pending.svg';
        iconColor = Colors.orange;
        break;
      case UnprocessedReceiptStatus.processing:
        iconName = 'icon_processing.svg';
        iconColor = Colors.blue;
        break;
      case UnprocessedReceiptStatus.error:
        iconName = 'icon_error.svg';
        iconColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: iconColor.withValues(alpha: 0.1),
      ),
      child: SvgPicture.asset(
        'packages/presentation/assets/$iconName',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildDateTime(BuildContext context) {
    final dateFormat = DateFormat('d MMM, HH:mm');
    return Text(
      dateFormat.format(receipt.rawData.transactionDatetime),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
    );
  }

  Widget _buildAmount(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    var currencyFormatter = CurrencyTextFormatter(locale: locale);
    final amount = currencyFormatter.formatCurrency(receipt.rawData.total);

    return Text(
      amount,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
