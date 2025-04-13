import 'package:domain/model/receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final Receipt receipt;

  const ReceiptDetailScreen({
    super.key,
    required this.receipt,
  });

  static Future<void> show(BuildContext context, Receipt receipt) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReceiptDetailScreen(receipt: receipt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            _buildModalHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMMM dd, yyyy - HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.receiptDetails,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),

        // Merchant Information
        _buildInfoSection(
          title: l10n.merchant,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                receipt.merchant.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (receipt.merchant.address.isNotEmpty)
                Text(
                  receipt.merchant.address,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),

        // Transaction Information
        _buildInfoSection(
          title: l10n.transactionDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${l10n.transactionDate}: ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    dateFormat.format(receipt.transactionDateTime),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  Text('${l10n.totalChartData}: ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    receipt.total.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Items List
        _buildInfoSection(
          title: l10n.items,
          child: SizedBox(
            height: 300,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: receipt.items.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final item = receipt.items[index];
                return _buildItemRow(context, item);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, dynamic item) {
    final categoryIconPath =
        'packages/presentation/assets/icon_${item.category}.svg';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            categoryIconPath,
            width: 24,
            height: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${item.quantity.toStringAsFixed(2)} × ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    item.totalPrice.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
