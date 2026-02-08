import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:domain/model/unprocessed_receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/screen/receipt_details/widget/receipt_details_section_widget.dart';
import 'package:presentation/core/widget/app_spacing.dart';

import '../bloc/unprocessed_receipt_edit_bloc.dart';
import '../bloc/unprocessed_receipt_edit_event.dart';
import '../widget/unprocessed_receipt_items_list_widget.dart';
import '../widget/unprocessed_receipt_merchant_info_widget.dart';
import '../widget/unprocessed_receipt_status_widget.dart';
import '../widget/unprocessed_receipt_transaction_info_widget.dart';

class UnprocessedReceiptDetailsContent extends StatefulWidget {
  final UnprocessedReceipt receipt;
  final bool isEditMode;

  const UnprocessedReceiptDetailsContent({
    super.key,
    required this.receipt,
    required this.isEditMode,
  });

  @override
  State<UnprocessedReceiptDetailsContent> createState() =>
      _UnprocessedReceiptDetailsContentState();
}

class _UnprocessedReceiptDetailsContentState
    extends State<UnprocessedReceiptDetailsContent> {
  late TextEditingController _merchantNameController;
  late TextEditingController _merchantAddressController;
  late TextEditingController _totalController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant UnprocessedReceiptDetailsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receipt != widget.receipt ||
        oldWidget.isEditMode != widget.isEditMode) {
      _initControllers();
    }
  }

  void _initControllers() {
    _merchantNameController =
        TextEditingController(text: widget.receipt.rawData.merchant.name);
    _merchantAddressController =
        TextEditingController(text: widget.receipt.rawData.merchant.address);
    _totalController = TextEditingController(
        text: widget.receipt.rawData.total.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _merchantNameController.dispose();
    _merchantAddressController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.unprocessedReceiptDetails,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        ReceiptDetailsSectionWidget(
          title: l10n.status,
          child: UnprocessedReceiptStatusWidget(
            status: widget.receipt.status,
            errorMessage: widget.receipt.errorMessage,
          ),
        ),
        if (_hasMerchantInfo(widget.receipt))
          ReceiptDetailsSectionWidget(
            title: l10n.merchant,
            child: UnprocessedReceiptMerchantInfoWidget(
              receipt: widget.receipt,
              isEditMode: widget.isEditMode,
              merchantNameController: _merchantNameController,
              merchantAddressController: _merchantAddressController,
            ),
          ),
        ReceiptDetailsSectionWidget(
          title: l10n.transactionDetails,
          child: UnprocessedReceiptTransactionInfoWidget(
            receipt: widget.receipt,
            isEditMode: widget.isEditMode,
            totalController: _totalController,
            onDateTimeSelected: (dateTime) {
              context.read<UnprocessedReceiptEditBloc>().add(
                    UnprocessedReceiptEditEvent.updateTransactionDateTime(
                        dateTime),
                  );
            },
            onTotalChanged: (value) {
              context.read<UnprocessedReceiptEditBloc>().add(
                    UnprocessedReceiptEditEvent.updateTotal(value),
                  );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.items,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: UnprocessedReceiptItemsListWidget(
            receipt: _convertToReceipt(widget.receipt),
            isEditMode: widget.isEditMode,
            onItemUpdated: (index, updatedItem) {
              final newItems =
                  List<ReceiptItem>.from(widget.receipt.rawData.items);
              newItems[index] = updatedItem;
              context.read<UnprocessedReceiptEditBloc>().add(
                    UnprocessedReceiptEditEvent.updateItems(newItems),
                  );
            },
          ),
        ),
      ],
    );
  }

  bool _hasMerchantInfo(UnprocessedReceipt receipt) {
    return receipt.rawData.merchant.name.isNotEmpty ||
        receipt.rawData.merchant.address.isNotEmpty;
  }

  // TODO: Consider moving this conversion logic to a separate utility or service
  Receipt _convertToReceipt(UnprocessedReceipt unprocessedReceipt) {
    return Receipt(
      id: unprocessedReceipt.id,
      merchant: unprocessedReceipt.rawData.merchant,
      items: unprocessedReceipt.rawData.items,
      total: unprocessedReceipt.rawData.total,
      transactionDateTime: unprocessedReceipt.rawData.transactionDatetime ??
          unprocessedReceipt.createdAt,
      addedDateTime: unprocessedReceipt.createdAt,
    );
  }
}
