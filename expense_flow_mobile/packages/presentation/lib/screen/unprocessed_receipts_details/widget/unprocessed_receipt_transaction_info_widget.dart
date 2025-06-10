import 'package:domain/model/unprocessed_receipt.dart';
import 'package:flutter/material.dart';

import '../../../core/widget/receipt/base_receipt_transaction_info_widget.dart';

class UnprocessedReceiptTransactionInfoWidget extends StatelessWidget {
  final UnprocessedReceipt receipt;
  final bool isEditMode;
  final TextEditingController totalController;
  final Function(DateTime) onDateTimeSelected;
  final Function(double) onTotalChanged;

  const UnprocessedReceiptTransactionInfoWidget({
    super.key,
    required this.receipt,
    required this.isEditMode,
    required this.totalController,
    required this.onDateTimeSelected,
    required this.onTotalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BaseReceiptTransactionInfoWidget(
      transactionDateTime: receipt.rawData.transactionDatetime,
      total: receipt.rawData.total,
      isEditMode: isEditMode,
      totalController: totalController,
      onDateTimeSelected: onDateTimeSelected,
      onTotalChanged: onTotalChanged,
    );
  }
}
