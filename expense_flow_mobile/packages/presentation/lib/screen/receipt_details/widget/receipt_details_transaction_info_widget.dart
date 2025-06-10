import 'package:domain/model/receipt.dart';
import 'package:flutter/material.dart';

import '../../../core/widget/receipt/base_receipt_transaction_info_widget.dart';

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
    return BaseReceiptTransactionInfoWidget(
      transactionDateTime: receipt.transactionDateTime,
      total: receipt.total,
      isEditMode: isEditMode,
      totalController: totalController,
      onDateTimeSelected: onDateTimeSelected,
      onTotalChanged: onTotalChanged,
    );
  }
}
