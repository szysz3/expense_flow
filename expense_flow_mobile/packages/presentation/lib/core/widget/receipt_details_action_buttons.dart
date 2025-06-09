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

  const ReceiptDetailsActionButtons({
    super.key,
    required this.isEditMode,
    required this.onCancel,
    required this.onDelete,
    required this.onEdit,
    required this.onSave,
    required this.deleteConfirmMessage,
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
      isProcessing: false,
      onPressed: onCancel,
      width: 36.0,
      height: 36.0,
      iconSize: 18.0,
      borderColor: Colors.grey,
      backgroundColor: Colors.grey.withValues(alpha: 0.3),
      icon: SvgPicture.asset(
        'packages/presentation/assets/icon_close.svg',
        height: 18,
        width: 18,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return AnimatedSquareButton(
      isProcessing: false,
      onPressed: () => _showDeleteConfirmation(context),
      width: 36.0,
      height: 36.0,
      iconSize: 18.0,
      borderColor: ExpenseFlowColors.chartRed,
      backgroundColor: Colors.red.withValues(alpha: 0.3),
      icon: SvgPicture.asset(
        'packages/presentation/assets/icon_delete.svg',
        height: 18,
        width: 18,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return AnimatedSquareButton(
      isProcessing: false,
      onPressed: isEditMode ? onSave : onEdit,
      width: 36.0,
      height: 36.0,
      iconSize: 18.0,
      borderColor: isEditMode
          ? ExpenseFlowColors.chartMutedGreen
          : Theme.of(context).colorScheme.primary,
      backgroundColor: isEditMode
          ? ExpenseFlowColors.chartMutedGreen.withValues(alpha: 0.3)
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      icon: SvgPicture.asset(
        isEditMode
            ? 'packages/presentation/assets/icon_tick.svg'
            : 'packages/presentation/assets/icon_edit.svg',
        height: 18,
        width: 18,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
