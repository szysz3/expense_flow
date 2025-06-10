import 'package:domain/model/receipt.dart';
import 'package:domain/use_case/receipt/receipt_delete_use_case.dart';
import 'package:domain/use_case/receipt/receipt_update_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:presentation/screen/receipt_details/widget/receipt_details_content.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/widget/receipt_details_action_buttons.dart';
import '../../../di/di.dart';
import '../../core/widget/receipt/base_receipt_details_screen.dart';
import '../../theme/expense_flow_colors.dart';
import '../receipt_browse/bloc/receipt_browse_bloc.dart';
import '../receipt_browse/bloc/receipt_browse_event.dart';
import 'bloc/receipt_detail_bloc.dart';
import 'bloc/receipt_detail_event.dart';
import 'bloc/receipt_detail_state.dart';
import 'bloc/receipt_edit_bloc.dart';
import 'bloc/receipt_edit_event.dart';
import 'bloc/receipt_edit_state.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final Receipt receipt;

  const ReceiptDetailScreen({
    super.key,
    required this.receipt,
  });

  static Future<void> show(BuildContext context, Receipt receipt) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ReceiptDetailBloc(
              getIt<ReceiptDeleteUseCase>(),
              getIt<Logger>(),
              getIt<LocalizationService>(),
            ),
          ),
          BlocProvider(
            create: (_) => ReceiptEditBloc(
              getIt<Logger>(),
              getIt<LocalizationService>(),
              getIt<ReceiptUpdateUseCase>(),
              receipt,
            ),
          ),
          BlocProvider.value(
            value: context.read<ReceiptBrowseBloc>(),
          ),
        ],
        child: ReceiptDetailScreen(receipt: receipt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ReceiptDetailBloc, ReceiptDetailState>(
          listener: _handleDetailStateChanges,
        ),
        BlocListener<ReceiptEditBloc, ReceiptEditState>(
          listener: _handleEditStateChanges,
        ),
      ],
      child: BlocBuilder<ReceiptEditBloc, ReceiptEditState>(
        builder: (context, editState) {
          return BlocBuilder<ReceiptDetailBloc, ReceiptDetailState>(
            builder: (context, detailState) {
              final l10n = AppLocalizations.of(context);

              return BaseReceiptDetailScreen(
                content: ReceiptDetailsContent(
                  receipt: editState.receipt ?? receipt,
                  isEditMode: editState.isEditMode,
                ),
                actionButtons: ReceiptDetailsActionButtons(
                  isEditMode: editState.isEditMode,
                  deleteConfirmMessage: l10n.deleteReceiptConfirmMessage,
                  onCancel: () => context.read<ReceiptEditBloc>().add(
                        const ReceiptEditEvent.cancelEdit(),
                      ),
                  onDelete: () {
                    if (receipt.id != null) {
                      context.read<ReceiptDetailBloc>().add(
                            ReceiptDetailEvent.deleteReceipt(receipt.id!),
                          );
                    }
                  },
                  onEdit: () => context.read<ReceiptEditBloc>().add(
                        const ReceiptEditEvent.toggleEditMode(),
                      ),
                  onSave: () => context.read<ReceiptEditBloc>().add(
                        const ReceiptEditEvent.saveChanges(),
                      ),
                ),
                isDeleting: detailState.isDeleting,
                isSaving: editState.isSaving,
                deletingMessage: l10n.deletingReceipt,
                savingMessage: l10n.savingReceipt,
              );
            },
          );
        },
      ),
    );
  }

  void _handleDetailStateChanges(
      BuildContext context, ReceiptDetailState state) {
    if (state.error != null) {
      ErrorUtils.showErrorSnackBar(context, state.error!);
    }

    if (state.isDeleted && receipt.id != null) {
      context.read<ReceiptBrowseBloc>().add(
            ReceiptBrowseEvent.notifyReceiptDeleted(receipt.id!),
          );
      Navigator.of(context).pop();
    }
  }

  void _handleEditStateChanges(BuildContext context, ReceiptEditState state) {
    if (state.error != null) {
      ErrorUtils.showErrorSnackBar(context, state.error!);
    }

    if (state.isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).receiptUpdated),
          backgroundColor: ExpenseFlowColors.chartMutedGreen,
        ),
      );
      context.read<ReceiptBrowseBloc>().add(
            ReceiptBrowseEvent.refresh(),
          );
    }
  }
}
