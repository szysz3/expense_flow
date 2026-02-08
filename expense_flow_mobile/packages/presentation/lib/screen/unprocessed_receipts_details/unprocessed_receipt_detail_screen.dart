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
import '../../core/widget/full_screen_loading_overlay.dart';
import '../../core/widget/receipt/base_receipt_details_screen.dart';
import '../unprocessed_receipts/bloc/unprocessed_receipts_bloc.dart';
import '../unprocessed_receipts/bloc/unprocessed_receipts_event.dart';
import 'bloc/unprocessed_receipt_detail_bloc.dart';
import 'bloc/unprocessed_receipt_detail_event.dart';
import 'bloc/unprocessed_receipt_detail_state.dart';
import 'bloc/unprocessed_receipt_edit_bloc.dart';
import 'bloc/unprocessed_receipt_edit_event.dart';
import 'bloc/unprocessed_receipt_edit_state.dart';

class UnprocessedReceiptDetailScreen extends StatefulWidget {
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
  State<UnprocessedReceiptDetailScreen> createState() =>
      _UnprocessedReceiptDetailScreenState();
}

class _UnprocessedReceiptDetailScreenState
    extends State<UnprocessedReceiptDetailScreen> {
  static const _successDisplayDuration = Duration(milliseconds: 1500);

  final _loadingOverlay = FullScreenLoadingOverlay();

  @override
  void dispose() {
    _loadingOverlay.dispose();
    super.dispose();
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
              final currentReceipt = editState.receipt ?? widget.receipt;
              final isProcessing =
                  currentReceipt.status == UnprocessedReceiptStatus.processing;

              return BaseReceiptDetailScreen(
                content: UnprocessedReceiptDetailsContent(
                  receipt: currentReceipt,
                  isEditMode: editState.isEditMode,
                ),
                actionButtons: ReceiptDetailsActionButtons(
                  isEditMode: editState.isEditMode,
                  isDisabled: isProcessing,
                  deleteConfirmMessage: AppLocalizations.of(context)
                      .deleteUnprocessedReceiptConfirmMessage,
                  onCancel: () =>
                      context.read<UnprocessedReceiptEditBloc>().add(
                            const UnprocessedReceiptEditEvent.cancelEdit(),
                          ),
                  onDelete: () =>
                      context.read<UnprocessedReceiptDetailBloc>().add(
                            UnprocessedReceiptDetailEvent.deleteReceipt(
                                widget.receipt.id),
                          ),
                  onEdit: () =>
                      context.read<UnprocessedReceiptEditBloc>().add(
                            const UnprocessedReceiptEditEvent.toggleEditMode(),
                          ),
                  onSave: () =>
                      context.read<UnprocessedReceiptEditBloc>().add(
                            const UnprocessedReceiptEditEvent.saveChanges(),
                          ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleDetailStateChanges(
      BuildContext context, UnprocessedReceiptDetailState state) {
    if (state.isDeleted) {
      _loadingOverlay.update(isSuccess: true);
      if (!_loadingOverlay.isShowing) {
        _loadingOverlay.show(context);
      }
      final navigator = Navigator.of(context);
      final receiptsBloc = context.read<UnprocessedReceiptsBloc>();
      Future.delayed(_successDisplayDuration, () {
        if (!mounted) return;
        _loadingOverlay.hide();
        receiptsBloc.add(const UnprocessedReceiptsEvent.refresh());
        navigator.pop();
      });
      return;
    }

    if (state.isDeleting) {
      if (!_loadingOverlay.isShowing) {
        _loadingOverlay.show(context);
      }
      return;
    }

    _loadingOverlay.hide();

    if (state.error != null) {
      ErrorUtils.showErrorSnackBar(context, state.error!);
    }
  }

  void _handleEditStateChanges(
      BuildContext context, UnprocessedReceiptEditState state) {
    if (state.isSaved) {
      _loadingOverlay.update(isSuccess: true);
      if (!_loadingOverlay.isShowing) {
        _loadingOverlay.show(context);
      }
      final receiptsBloc = context.read<UnprocessedReceiptsBloc>();
      Future.delayed(_successDisplayDuration, () {
        if (!mounted) return;
        _loadingOverlay.hide();
        receiptsBloc.add(const UnprocessedReceiptsEvent.refresh());
      });
      return;
    }

    if (state.isSaving) {
      if (!_loadingOverlay.isShowing) {
        _loadingOverlay.show(context);
      }
      return;
    }

    _loadingOverlay.hide();

    if (state.error != null) {
      ErrorUtils.showErrorSnackBar(context, state.error!);
    }
  }
}
