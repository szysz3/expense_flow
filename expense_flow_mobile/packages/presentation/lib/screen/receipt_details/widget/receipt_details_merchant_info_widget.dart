import 'package:domain/model/merchant.dart';
import 'package:domain/model/receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

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
    final theme = Theme.of(context);

    if (isEditMode) {
      return _buildEditView(context, theme);
    } else {
      return _buildReadOnlyView(context, theme);
    }
  }

  Widget _buildEditView(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        TextField(
          controller: merchantNameController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).merchantName,
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
        const SizedBox(height: 16),
        TextField(
          controller: merchantAddressController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).merchantAddress,
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
          maxLines: 1,
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
  }

  Widget _buildReadOnlyView(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (receipt.merchant.name.isNotEmpty)
            Text(
              receipt.merchant.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          if (receipt.merchant.name.isNotEmpty &&
              receipt.merchant.address.isNotEmpty)
            const SizedBox(height: 4),
          if (receipt.merchant.address.isNotEmpty)
            Text(
              receipt.merchant.address,
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}
