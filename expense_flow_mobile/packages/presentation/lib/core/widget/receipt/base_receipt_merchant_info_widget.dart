import 'package:domain/model/merchant.dart';
import 'package:flutter/material.dart';
import 'package:localization/app_localizations.dart';

class BaseReceiptMerchantInfoWidget extends StatelessWidget {
  final Merchant merchant;
  final bool isEditMode;
  final TextEditingController merchantNameController;
  final TextEditingController merchantAddressController;
  final VoidCallback onMerchantUpdated;

  const BaseReceiptMerchantInfoWidget({
    super.key,
    required this.merchant,
    required this.isEditMode,
    required this.merchantNameController,
    required this.merchantAddressController,
    required this.onMerchantUpdated,
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
        _buildEditTextField(
          context,
          theme,
          controller: merchantNameController,
          labelText: AppLocalizations.of(context).merchantName,
        ),
        const SizedBox(height: 16),
        _buildEditTextField(
          context,
          theme,
          controller: merchantAddressController,
          labelText: AppLocalizations.of(context).merchantAddress,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildEditTextField(
    BuildContext context,
    ThemeData theme, {
    required TextEditingController controller,
    required String labelText,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
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
      onSubmitted: (_) {
        onMerchantUpdated();
        FocusScope.of(context).unfocus();
      },
      onEditingComplete: () {
        onMerchantUpdated();
        FocusScope.of(context).unfocus();
      },
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
          if (merchant.name.isNotEmpty)
            Text(
              merchant.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          if (merchant.name.isNotEmpty && merchant.address.isNotEmpty)
            const SizedBox(height: 4),
          if (merchant.address.isNotEmpty)
            Text(
              merchant.address,
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}
