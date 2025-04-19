import 'package:domain/model/merchant.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../../../core/utils/category_utils.dart';
import '../bloc/receipt_edit_bloc.dart';
import '../bloc/receipt_edit_event.dart';
import 'receipt_details_edit_dialog.dart';

class ReceiptDetailsContent extends StatelessWidget {
  final Receipt receipt;
  final bool isEditMode;

  const ReceiptDetailsContent({
    super.key,
    required this.receipt,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.receiptDetails,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        if (_hasMerchantInfo(receipt))
          _buildSection(
            title: l10n.merchant,
            child: _buildMerchantInfo(context, receipt, isEditMode),
          ),
        _buildSection(
          title: l10n.transactionDetails,
          child: _buildTransactionInfo(context, receipt, isEditMode),
        ),
        Text(
          l10n.items,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildItemsList(context, receipt, isEditMode),
        ),
      ],
    );
  }

  bool _hasMerchantInfo(Receipt receipt) {
    return receipt.merchant.name.isNotEmpty ||
        receipt.merchant.address.isNotEmpty;
  }

  Widget _buildMerchantInfo(
      BuildContext context, Receipt receipt, bool isEditMode) {
    if (isEditMode) {
      return Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).merchantName,
            ),
            controller: TextEditingController(text: receipt.merchant.name),
            onChanged: (value) {
              context.read<ReceiptEditBloc>().add(
                    ReceiptEditEvent.updateMerchant(
                      Merchant(
                        name: value,
                        address: receipt.merchant.address,
                      ),
                    ),
                  );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).merchantAddress,
            ),
            controller: TextEditingController(text: receipt.merchant.address),
            maxLines: 2,
            onChanged: (value) {
              context.read<ReceiptEditBloc>().add(
                    ReceiptEditEvent.updateMerchant(
                      Merchant(
                        name: receipt.merchant.name,
                        address: value,
                      ),
                    ),
                  );
            },
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (receipt.merchant.name.isNotEmpty)
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
      );
    }
  }

  Widget _buildTransactionInfo(
      BuildContext context, Receipt receipt, bool isEditMode) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMMM dd, yyyy - HH:mm');

    if (isEditMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _showDateTimePicker(context, receipt),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.transactionDate,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(dateFormat.format(receipt.transactionDateTime)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: l10n.totalChartData,
            ),
            controller:
                TextEditingController(text: receipt.total.toStringAsFixed(2)),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final total = double.tryParse(value) ?? receipt.total;
              context.read<ReceiptEditBloc>().add(
                    ReceiptEditEvent.updateTotal(total),
                  );
            },
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context: context,
            label: l10n.transactionDate,
            value: dateFormat.format(receipt.transactionDateTime),
          ),
          _buildInfoRow(
            context: context,
            label: l10n.totalChartData,
            value: receipt.total.toStringAsFixed(2),
            isHighlighted: true,
          ),
        ],
      );
    }
  }

  void _showDateTimePicker(BuildContext context, Receipt receipt) async {
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

        context.read<ReceiptEditBloc>().add(
              ReceiptEditEvent.updateTransactionDateTime(newDateTime),
            );
      }
    }
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: isHighlighted
              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )
              : Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildItemsList(
      BuildContext context, Receipt receipt, bool isEditMode) {
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      itemCount: receipt.items.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12),
      itemBuilder: (context, index) => _buildItemRow(
          context, receipt.items[index], isEditMode, index, receipt),
    );
  }

  Widget _buildItemRow(BuildContext context, ReceiptItem item, bool isEditMode,
      int index, Receipt currentReceipt) {
    final categoryIconPath = CategoryUtils.getIconPath(item.category);
    final categoryName = CategoryUtils.getDisplayName(item.category, context);

    if (isEditMode) {
      return InkWell(
        onTap: () => _showEditItemDialog(context, item, index, currentReceipt),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: _buildItemRowContent(
              context, item, categoryIconPath, categoryName,
              isEditable: true),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child:
            _buildItemRowContent(context, item, categoryIconPath, categoryName),
      );
    }
  }

  Widget _buildItemRowContent(BuildContext context, ReceiptItem item,
      String categoryIconPath, String categoryName,
      {bool isEditable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category icon
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    categoryName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
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
        const SizedBox(width: 4),
        if (isEditable)
          Icon(
            Icons.edit,
            size: 16,
          ),
      ],
    );
  }

  void _showEditItemDialog(BuildContext context, ReceiptItem item, int index,
      Receipt currentReceipt) {
    showDialog(
      context: context,
      builder: (dialogContext) => ReceiptDetailsEditDialog(
        item: item,
        onSave: (updatedItem) {
          final newItems = List<ReceiptItem>.from(currentReceipt.items);
          newItems[index] = updatedItem;

          context.read<ReceiptEditBloc>().add(
                ReceiptEditEvent.updateItems(newItems),
              );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
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
}
