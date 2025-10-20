import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';

import '../../../theme/expense_flow_colors.dart';
import 'animated_square_button.dart';

class ReceiptDetailsActionButtons extends StatelessWidget {
  final bool isEditMode;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final String deleteConfirmMessage;
  final bool isDisabled;

  const ReceiptDetailsActionButtons({
    super.key,
    required this.isEditMode,
    required this.onCancel,
    required this.onDelete,
    required this.onEdit,
    required this.onSave,
    required this.deleteConfirmMessage,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 16,
      child: Row(
        children: [
          if (isEditMode)
            _buildCancelButton(context)
          else
            _buildDeleteButton(context),
          const SizedBox(width: 12),
          _buildEditButton(context),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return AnimatedSquareButton(
      isProcessing: isDisabled,
      onPressed: onCancel,
      width: 36.0,
      height: 36.0,
      iconSize: 18.0,
      borderColor: isDisabled ? Colors.grey.withValues(alpha: 0.3) : Colors.grey,
      backgroundColor: Colors.grey.withValues(alpha: isDisabled ? 0.1 : 0.3),
      icon: SvgPicture.asset(
        'packages/presentation/assets/icon_close.svg',
        height: 18,
        width: 18,
        colorFilter: ColorFilter.mode(
          isDisabled ? Colors.grey.withValues(alpha: 0.5) : Colors.white,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return AnimatedSquareButton(
      isProcessing: isDisabled,
      onPressed: () => _showDeleteConfirmation(context),
      width: 36.0,
      height: 36.0,
      iconSize: 18.0,
      borderColor: isDisabled ? Colors.grey.withValues(alpha: 0.3) : ExpenseFlowColors.chartRed,
      backgroundColor: isDisabled ? Colors.grey.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.3),
      icon: SvgPicture.asset(
        'packages/presentation/assets/icon_delete.svg',
        height: 18,
        width: 18,
        colorFilter: ColorFilter.mode(
          isDisabled ? Colors.grey.withValues(alpha: 0.5) : Colors.white,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    final Color activeBorderColor = isEditMode
        ? ExpenseFlowColors.chartMutedGreen
        : Theme.of(context).colorScheme.primary;
    final Color activeBackgroundColor = isEditMode
        ? ExpenseFlowColors.chartMutedGreen
        : Theme.of(context).colorScheme.primary;

    return AnimatedSquareButton(
      isProcessing: isDisabled,
      onPressed: isEditMode ? onSave : onEdit,
      width: 36.0,
      height: 36.0,
      iconSize: 18.0,
      borderColor: isDisabled ? Colors.grey.withValues(alpha: 0.3) : activeBorderColor,
      backgroundColor: isDisabled
          ? Colors.grey.withValues(alpha: 0.1)
          : activeBackgroundColor.withValues(alpha: 0.3),
      icon: SvgPicture.asset(
        isEditMode
            ? 'packages/presentation/assets/icon_tick.svg'
            : 'packages/presentation/assets/icon_edit.svg',
        height: 18,
        width: 18,
        colorFilter: ColorFilter.mode(
          isDisabled ? Colors.grey.withValues(alpha: 0.5) : Colors.white,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(l10n.deleteConfirmation),
        content: Text(deleteConfirmMessage),
        actions: [
          TextButton(
            child: Text(
              l10n.cancel,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: Text(
              l10n.delete,
              style: const TextStyle(color: ExpenseFlowColors.chartMutedRed),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}
