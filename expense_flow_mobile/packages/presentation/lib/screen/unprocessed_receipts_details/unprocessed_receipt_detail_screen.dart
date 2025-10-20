import 'package:domain/model/unprocessed_receipt.dart';
import 'package:domain/use_case/unprocessed_receipt/unprocessed_receipt_delete_use_case.dart';
import 'package:domain/use_case/unprocessed_receipt/unprocessed_receipt_update_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:presentation/screen/unprocessed_receipts_details/widget/unprocessed_receipt_details_content.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/widget/receipt_details_action_buttons.dart';
import '../../../di/di.dart';
import '../../core/widget/receipt/base_receipt_details_screen.dart';
import '../../theme/expense_flow_colors.dart';
import '../unprocessed_receipts/bloc/unprocessed_receipts_bloc.dart';
import '../unprocessed_receipts/bloc/unprocessed_receipts_event.dart';
import 'bloc/unprocessed_receipt_detail_bloc.dart';
import 'bloc/unprocessed_receipt_detail_event.dart';
import 'bloc/unprocessed_receipt_detail_state.dart';
import 'bloc/unprocessed_receipt_edit_bloc.dart';
import 'bloc/unprocessed_receipt_edit_event.dart';
import 'bloc/unprocessed_receipt_edit_state.dart';

class UnprocessedReceiptDetailScreen extends StatelessWidget {
  final UnprocessedReceipt receipt;

  const UnprocessedReceiptDetailScreen({
    super.key,
    required this.receipt,
  });

  static Future<void> show(BuildContext context, UnprocessedReceipt receipt) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => UnprocessedReceiptDetailBloc(
              getIt<UnprocessedReceiptDeleteUseCase>(),
              getIt<Logger>(),
              getIt<LocalizationService>(),
            ),
          ),
          BlocProvider(
            create: (_) => UnprocessedReceiptEditBloc(
              getIt<Logger>(),
              getIt<LocalizationService>(),
              getIt<UnprocessedReceiptUpdateUseCase>(),
              receipt,
            ),
          ),
          BlocProvider.value(
            value: context.read<UnprocessedReceiptsBloc>(),
          ),
        ],
        child: UnprocessedReceiptDetailScreen(receipt: receipt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UnprocessedReceiptDetailBloc,
            UnprocessedReceiptDetailState>(
          listener: _handleDetailStateChanges,
        ),
        BlocListener<UnprocessedReceiptEditBloc, UnprocessedReceiptEditState>(
          listener: _handleEditStateChanges,
        ),
      ],
      child:
          BlocBuilder<UnprocessedReceiptEditBloc, UnprocessedReceiptEditState>(
        builder: (context, editState) {
          return BlocBuilder<UnprocessedReceiptDetailBloc,
              UnprocessedReceiptDetailState>(
            builder: (context, detailState) {
              final l10n = AppLocalizations.of(context);

              final currentReceipt = editState.receipt ?? receipt;
              final isProcessing = currentReceipt.status == UnprocessedReceiptStatus.processing;

              return BaseReceiptDetailScreen(
                content: UnprocessedReceiptDetailsContent(
                  receipt: currentReceipt,
                  isEditMode: editState.isEditMode,
                ),
                actionButtons: ReceiptDetailsActionButtons(
                  isEditMode: editState.isEditMode,
                  isDisabled: isProcessing,
                  deleteConfirmMessage:
                      l10n.deleteUnprocessedReceiptConfirmMessage,
                  onCancel: () =>
                      context.read<UnprocessedReceiptEditBloc>().add(
                            const UnprocessedReceiptEditEvent.cancelEdit(),
                          ),
                  onDelete: () => context
                      .read<UnprocessedReceiptDetailBloc>()
                      .add(
                        UnprocessedReceiptDetailEvent.deleteReceipt(receipt.id),
                      ),
                  onEdit: () => context.read<UnprocessedReceiptEditBloc>().add(
                        const UnprocessedReceiptEditEvent.toggleEditMode(),
                      ),
                  onSave: () => context.read<UnprocessedReceiptEditBloc>().add(
                        const UnprocessedReceiptEditEvent.saveChanges(),
                      ),
                ),
                isDeleting: detailState.isDeleting,
                isSaving: editState.isSaving,
                deletingMessage: l10n.deletingUnprocessedReceipt,
                savingMessage: l10n.savingUnprocessedReceipt,
              );
            },
          );
        },
      ),
    );
  }

  void _handleDetailStateChanges(
      BuildContext context, UnprocessedReceiptDetailState state) {
    if (state.error != null) {
      ErrorUtils.showErrorSnackBar(context, state.error!);
    }

    if (state.isDeleted) {
      context.read<UnprocessedReceiptsBloc>().add(
            const UnprocessedReceiptsEvent.refresh(),
          );
      Navigator.of(context).pop();
    }
  }

  void _handleEditStateChanges(
      BuildContext context, UnprocessedReceiptEditState state) {
    if (state.error != null) {
      ErrorUtils.showErrorSnackBar(context, state.error!);
    }

    if (state.isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).unprocessedReceiptUpdated),
          backgroundColor: ExpenseFlowColors.chartMutedGreen,
        ),
      );
      context.read<UnprocessedReceiptsBloc>().add(
            const UnprocessedReceiptsEvent.refresh(),
          );
    }
  }
}
