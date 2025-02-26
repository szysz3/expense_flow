// lib/screen/unprocessed_receipts/widget/unprocessed_receipt_item.dart
import 'package:domain/model/unprocessed_receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class UnprocessedReceiptItem extends StatelessWidget {
  final UnprocessedReceipt receipt;

  const UnprocessedReceiptItem({
    required this.receipt,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildStatusIcon(context),
          const SizedBox(width: 16),
          _buildDateTime(context),
          const Spacer(),
          _buildAmount(context),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    String iconName;
    switch (receipt.status) {
      case UnprocessedReceiptStatus.pending:
        iconName = 'icon_pending.svg';
        break;
      case UnprocessedReceiptStatus.processing:
        iconName = 'icon_processing.svg';
        break;
      case UnprocessedReceiptStatus.error:
        iconName = 'icon_error.svg';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SvgPicture.asset(
        'packages/presentation/assets/$iconName',
        width: 36,
        height: 36,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildDateTime(BuildContext context) {
    final dateFormat = DateFormat('d MMM, HH:mm');
    return Text(
      dateFormat.format(receipt.rawData.transactionDatetime),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
    );
  }

  Widget _buildAmount(BuildContext context) {
    final amount = receipt.rawData.total;
    final locale = Localizations.localeOf(context).toString();
    final currencySymbol = NumberFormat.currency(locale: locale).currencySymbol;

    return Text(
      '$currencySymbol $amount',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
