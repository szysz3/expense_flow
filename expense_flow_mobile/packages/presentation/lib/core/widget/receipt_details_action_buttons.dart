import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/core/widget/glass_container.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSquareButton(
      isProcessing: isDisabled,
      onPressed: onCancel,
      width: 36.0,
      height: 36.0,
      iconSize: 18.0,
      borderColor:
          isDisabled ? scheme.outline.withValues(alpha: 0.3) : scheme.outline,
      backgroundColor:
          scheme.surface.withValues(alpha: isDisabled ? 0.3 : 0.6),
      icon: SvgPicture.asset(
        'packages/presentation/assets/icon_close.svg',
        height: 18,
        width: 18,
        colorFilter: ColorFilter.mode(
          isDisabled
              ? scheme.onSurface.withValues(alpha: 0.4)
              : scheme.onSurface,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSquareButton(
      isProcessing: isDisabled,
      onPressed: () => _showDeleteConfirmation(context),
      width: 36.0,
      height: 36.0,
      iconSize: 18.0,
      borderColor: isDisabled
          ? scheme.outline.withValues(alpha: 0.3)
          : scheme.error,
      backgroundColor: isDisabled
          ? scheme.surface.withValues(alpha: 0.3)
          : scheme.error.withValues(alpha: 0.25),
      icon: SvgPicture.asset(
        'packages/presentation/assets/icon_delete.svg',
        height: 18,
        width: 18,
        colorFilter: ColorFilter.mode(
          isDisabled
              ? scheme.onSurface.withValues(alpha: 0.4)
              : scheme.onError,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color activeBorderColor = isEditMode
        ? ExpenseFlowColors.chartMutedGreen
        : scheme.primary;
    final Color activeBackgroundColor = isEditMode
        ? ExpenseFlowColors.chartMutedGreen
        : scheme.primary;

    return AnimatedSquareButton(
      isProcessing: isDisabled,
      onPressed: isEditMode ? onSave : onEdit,
      width: 36.0,
      height: 36.0,
      iconSize: 18.0,
      borderColor: isDisabled
          ? scheme.outline.withValues(alpha: 0.3)
          : activeBorderColor,
      backgroundColor: isDisabled
          ? scheme.surface.withValues(alpha: 0.3)
          : activeBackgroundColor.withValues(alpha: 0.3),
      icon: SvgPicture.asset(
        isEditMode
            ? 'packages/presentation/assets/icon_tick.svg'
            : 'packages/presentation/assets/icon_edit.svg',
        height: 18,
        width: 18,
        colorFilter: ColorFilter.mode(
          isDisabled
              ? scheme.onSurface.withValues(alpha: 0.4)
              : scheme.onPrimary,
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
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: GlassContainer(
            blur: 24,
            tintOpacity: 0.75,
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(20),
            expand: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deleteConfirmation,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  deleteConfirmMessage,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      child: Text(
                        l10n.delete,
                        style: const TextStyle(
                            color: ExpenseFlowColors.chartMutedRed),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onDelete();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
