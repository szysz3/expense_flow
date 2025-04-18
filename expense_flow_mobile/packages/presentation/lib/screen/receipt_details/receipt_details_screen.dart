import 'package:domain/model/merchant.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:domain/use_case/delete_use_case.dart';
import 'package:domain/use_case/update_receipts_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';
import 'package:presentation/core/utils/string_utils.dart';

import '../../../core/error/error_utils.dart';
import '../../../di/di.dart';
import '../../core/widget/animated_square_button.dart';
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
              getIt<DeleteReceiptUseCase>(),
              getIt<Logger>(),
              getIt<LocalizationService>(),
            ),
          ),
          BlocProvider(
            create: (_) => ReceiptEditBloc(
              getIt<Logger>(),
              getIt<LocalizationService>(),
              getIt<UpdateReceiptUseCase>(),
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
          listener: (context, state) {
            if (state.error != null) {
              ErrorUtils.showErrorSnackBar(context, state.error!);
            }

            if (state.isDeleted && receipt.id != null) {
              context.read<ReceiptBrowseBloc>().add(
                    ReceiptBrowseEvent.notifyReceiptDeleted(receipt.id!),
                  );
              Navigator.of(context).pop();
            }
          },
        ),
        BlocListener<ReceiptEditBloc, ReceiptEditState>(
          listener: (context, state) {
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
          },
        ),
      ],
      child: _buildModalContent(context),
    );
  }

  Widget _buildModalContent(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: BlocBuilder<ReceiptEditBloc, ReceiptEditState>(
        builder: (context, editState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
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
                        child: _buildReceiptDetails(context, editState),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 16,
                  right: 56,
                  child: _buildDeleteButton(context),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildEditButton(context, editState),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  Widget _buildReceiptDetails(
      BuildContext context, ReceiptEditState editState) {
    final l10n = AppLocalizations.of(context);
    final currentReceipt = editState.receipt ?? receipt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.receiptDetails,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        if (_hasMerchantInfo(currentReceipt))
          _buildSection(
            title: l10n.merchant,
            child: _buildMerchantInfo(
                context, currentReceipt, editState.isEditMode),
          ),
        _buildSection(
          title: l10n.transactionDetails,
          child: _buildTransactionInfo(
              context, currentReceipt, editState.isEditMode),
        ),
        Text(
          l10n.items,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildItemsList(context, currentReceipt, editState.isEditMode),
        ),
      ],
    );
  }

  bool _hasMerchantInfo(Receipt receipt) {
    return receipt.merchant.name.isNotEmpty ||
        receipt.merchant.address.isNotEmpty;
  }

  Widget _buildMerchantInfo(
      BuildContext context, Receipt receipt, bool isEditMode) {
    if (isEditMode) {
      return Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).merchantName,
            ),
            controller: TextEditingController(text: receipt.merchant.name),
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
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).merchantAddress,
            ),
            controller: TextEditingController(text: receipt.merchant.address),
            maxLines: 2,
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
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (receipt.merchant.name.isNotEmpty)
            Text(
              receipt.merchant.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          if (receipt.merchant.address.isNotEmpty)
            Text(
              receipt.merchant.address,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      );
    }
  }

  Widget _buildTransactionInfo(
      BuildContext context, Receipt receipt, bool isEditMode) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMMM dd, yyyy - HH:mm');

    if (isEditMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _showDateTimePicker(context, receipt),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.transactionDate,
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(dateFormat.format(receipt.transactionDateTime)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: l10n.totalChartData,
            ),
            controller:
                TextEditingController(text: receipt.total.toStringAsFixed(2)),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final total = double.tryParse(value) ?? receipt.total;
              context.read<ReceiptEditBloc>().add(
                    ReceiptEditEvent.updateTotal(total),
                  );
            },
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context: context,
            label: l10n.transactionDate,
            value: dateFormat.format(receipt.transactionDateTime),
          ),
          _buildInfoRow(
            context: context,
            label: l10n.totalChartData,
            value: receipt.total.toStringAsFixed(2),
            isHighlighted: true,
          ),
        ],
      );
    }
  }

  void _showDateTimePicker(BuildContext context, Receipt receipt) async {
    final currentDate = receipt.transactionDateTime;

    final date = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDate),
      );

      if (time != null) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        context.read<ReceiptEditBloc>().add(
              ReceiptEditEvent.updateTransactionDateTime(newDateTime),
            );
      }
    }
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: isHighlighted
              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )
              : Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildItemsList(
      BuildContext context, Receipt receipt, bool isEditMode) {
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      itemCount: receipt.items.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12),
      itemBuilder: (context, index) => _buildItemRow(
          context, receipt.items[index], isEditMode, index, receipt),
    );
  }

  Widget _buildItemRow(BuildContext context, ReceiptItem item, bool isEditMode,
      int index, Receipt currentReceipt) {
    final categoryIconPath =
        'packages/presentation/assets/icon_${item.category}.svg';
    final categoryName =
        StringUtils.formatCategoryName(item.category.toString());

    if (isEditMode) {
      return InkWell(
        onTap: () => _showEditItemDialog(context, item, index, currentReceipt),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  categoryIconPath,
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Text(
                          categoryName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${item.quantity.toStringAsFixed(2)} × ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          item.totalPrice.toStringAsFixed(2),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit,
                size: 16,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
            ],
          ),
        ),
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset(
              categoryIconPath,
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      categoryName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item.quantity.toStringAsFixed(2)} × ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      item.totalPrice.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  void _showEditItemDialog(BuildContext context, ReceiptItem item, int index,
      Receipt currentReceipt) {
    final TextEditingController descController =
        TextEditingController(text: item.description);
    final TextEditingController quantityController =
        TextEditingController(text: item.quantity.toString());
    final TextEditingController priceController =
        TextEditingController(text: item.totalPrice.toString());
    String? selectedCategory = item.category;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context).editItem),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).description,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).quantity,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).totalPrice,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).category,
                ),
                items: [
                  'groceries',
                  'alcoholic_beverages',
                  'personal_care',
                  'household',
                  'clothing',
                  'entertainment',
                  'transportation',
                  'pet',
                  'other',
                  'standing_orders',
                ]
                    .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(StringUtils.formatCategoryName(category)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              final description = descController.text;
              final quantity =
                  double.tryParse(quantityController.text) ?? item.quantity;
              final price =
                  double.tryParse(priceController.text) ?? item.totalPrice;

              if (description.isNotEmpty && price > 0) {
                final updatedItem = ReceiptItem(
                  description: description,
                  quantity: quantity,
                  totalPrice: price,
                  category: selectedCategory,
                );

                final newItems = List<ReceiptItem>.from(currentReceipt.items);
                newItems[index] = updatedItem;

                context.read<ReceiptEditBloc>().add(
                      ReceiptEditEvent.updateItems(newItems),
                    );

                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
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

  Widget _buildDeleteButton(BuildContext context) {
    return BlocBuilder<ReceiptEditBloc, ReceiptEditState>(
      builder: (context, editState) {
        return BlocBuilder<ReceiptDetailBloc, ReceiptDetailState>(
          builder: (context, state) {
            if (editState.isEditMode) {
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
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              );
            }

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
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            );
          },
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

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
