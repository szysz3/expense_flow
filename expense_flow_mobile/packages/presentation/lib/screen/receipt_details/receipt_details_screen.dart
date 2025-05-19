import 'package:domain/model/receipt.dart';
import 'package:domain/use_case/receipt/receipt_delete_use_case.dart';
import 'package:domain/use_case/receipt/receipt_update_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:presentation/screen/receipt_details/widget/receipt_details_action_buttons.dart';
import 'package:presentation/screen/receipt_details/widget/receipt_details_content.dart';

import '../../../core/error/error_utils.dart';
import '../../../di/di.dart';
import '../../theme/expense_flow_colors.dart';
import '../receipt_browse/bloc/receipt_browse_bloc.dart';
import '../receipt_browse/bloc/receipt_browse_event.dart';
import 'bloc/receipt_detail_bloc.dart';
import 'bloc/receipt_detail_state.dart';
import 'bloc/receipt_edit_bloc.dart';
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
      child: _buildModalContent(context),
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

  Widget _buildModalContent(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: BlocBuilder<ReceiptEditBloc, ReceiptEditState>(
        builder: (context, editState) {
          return Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.90,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.9),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildDragHandle(context),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ReceiptDetailsContent(
                              receipt: editState.receipt ?? receipt,
                              isEditMode: editState.isEditMode,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ReceiptDetailsActionButtons(receipt: receipt),
                  ],
                ),
              ),
              BlocBuilder<ReceiptDetailBloc, ReceiptDetailState>(
                builder: (context, state) {
                  if (state.isDeleting) {
                    return _buildLoadingOverlay(
                        context, AppLocalizations.of(context).deletingReceipt);
                  }
                  return const SizedBox.shrink();
                },
              ),
              BlocBuilder<ReceiptEditBloc, ReceiptEditState>(
                builder: (context, state) {
                  if (state.isSaving) {
                    return _buildLoadingOverlay(
                        context, AppLocalizations.of(context).savingReceipt);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context, String message) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }
}
