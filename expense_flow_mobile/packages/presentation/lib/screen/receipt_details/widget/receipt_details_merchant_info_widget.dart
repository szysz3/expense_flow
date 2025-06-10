import 'package:domain/model/merchant.dart';
import 'package:domain/model/receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widget/receipt/base_receipt_merchant_info_widget.dart';
import '../bloc/receipt_edit_bloc.dart';
import '../bloc/receipt_edit_event.dart';

class ReceiptDetailsMerchantInfoWidget extends StatelessWidget {
  final Receipt receipt;
  final bool isEditMode;
  final TextEditingController merchantNameController;
  final TextEditingController merchantAddressController;

  const ReceiptDetailsMerchantInfoWidget({
    super.key,
    required this.receipt,
    required this.isEditMode,
    required this.merchantNameController,
    required this.merchantAddressController,
  });

  @override
  Widget build(BuildContext context) {
    return BaseReceiptMerchantInfoWidget(
      merchant: receipt.merchant,
      isEditMode: isEditMode,
      merchantNameController: merchantNameController,
      merchantAddressController: merchantAddressController,
      onMerchantUpdated: () => _updateMerchant(context),
    );
  }

  void _updateMerchant(BuildContext context) {
    context.read<ReceiptEditBloc>().add(
          ReceiptEditEvent.updateMerchant(
            Merchant(
              name: merchantNameController.text,
              address: merchantAddressController.text,
            ),
          ),
        );
  }
}
