import 'package:domain/model/receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../../../core/widget/animated_square_button.dart';
import '../../../theme/expense_flow_colors.dart';
import '../bloc/receipt_detail_bloc.dart';
import '../bloc/receipt_detail_event.dart';
import '../bloc/receipt_detail_state.dart';
import '../bloc/receipt_edit_bloc.dart';
import '../bloc/receipt_edit_event.dart';
import '../bloc/receipt_edit_state.dart';

class ReceiptDetailsActionButtons extends StatelessWidget {
  final Receipt receipt;

  const ReceiptDetailsActionButtons({
    super.key,
    required this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiptEditBloc, ReceiptEditState>(
      builder: (context, editState) {
        return Positioned(
          top: 16,
          right: 16,
          child: Row(
            children: [
              if (editState.isEditMode)
                _buildCancelButton(context)
              else
                _buildDeleteButton(context),
              const SizedBox(width: 8),
              _buildEditButton(context, editState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return AnimatedSquareButton(
      isProcessing: false,
      onPressed: () => context.read<ReceiptEditBloc>().add(
            const ReceiptEditEvent.cancelEdit(),
          ),
      width: 36.0,
      height: 36.0,
      iconSize: 18.0,
      borderColor: Colors.grey,
      backgroundColor: Colors.grey.withOpacity(0.3),
      icon: SvgPicture.asset(
        'packages/presentation/assets/icon_close.svg',
        height: 18,
        width: 18,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return BlocBuilder<ReceiptDetailBloc, ReceiptDetailState>(
      builder: (context, state) {
        return AnimatedSquareButton(
          isProcessing: state.isDeleting,
          onPressed: () => _showDeleteConfirmation(context),
          width: 36.0,
          height: 36.0,
          iconSize: 18.0,
          borderColor: ExpenseFlowColors.chartRed,
          backgroundColor: Colors.red.withOpacity(0.3),
          icon: SvgPicture.asset(
            'packages/presentation/assets/icon_delete.svg',
            height: 18,
            width: 18,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        );
      },
    );
  }

  Widget _buildEditButton(BuildContext context, ReceiptEditState state) {
    final isEditMode = state.isEditMode;

    return BlocBuilder<ReceiptEditBloc, ReceiptEditState>(
      builder: (context, state) {
        return AnimatedSquareButton(
          isProcessing: state.isSaving,
          onPressed: () {
            if (isEditMode) {
              // Save changes
              context.read<ReceiptEditBloc>().add(
                    const ReceiptEditEvent.saveChanges(),
                  );
            } else {
              // Enter edit mode
              context.read<ReceiptEditBloc>().add(
                    const ReceiptEditEvent.toggleEditMode(),
                  );
            }
          },
          width: 36.0,
          height: 36.0,
          iconSize: 18.0,
          borderColor: isEditMode
              ? ExpenseFlowColors.chartMutedGreen
              : Theme.of(context).colorScheme.primary,
          backgroundColor: isEditMode
              ? ExpenseFlowColors.chartMutedGreen.withOpacity(0.3)
              : Theme.of(context).colorScheme.primary.withOpacity(0.3),
          icon: SvgPicture.asset(
            isEditMode
                ? 'packages/presentation/assets/icon_tick.svg'
                : 'packages/presentation/assets/icon_edit.svg',
            height: 18,
            width: 18,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(l10n.deleteConfirmation),
        content: Text(l10n.deleteReceiptConfirmMessage),
        actions: [
          TextButton(
            child: Text(
              l10n.cancel,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
              if (receipt.id != null) {
                context.read<ReceiptDetailBloc>().add(
                      ReceiptDetailEvent.deleteReceipt(receipt.id!),
                    );
              }
            },
          ),
        ],
      ),
    );
  }
}
