import 'package:domain/model/merchant.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../../../core/utils/category_utils.dart';
import '../../../core/utils/currency_text_formatter.dart';
import '../bloc/receipt_edit_bloc.dart';
import '../bloc/receipt_edit_event.dart';
import 'receipt_details_edit_dialog.dart';

class ReceiptDetailsContent extends StatefulWidget {
  final Receipt receipt;
  final bool isEditMode;

  const ReceiptDetailsContent({
    super.key,
    required this.receipt,
    required this.isEditMode,
  });

  @override
  State<ReceiptDetailsContent> createState() => _ReceiptDetailsContentState();
}

class _ReceiptDetailsContentState extends State<ReceiptDetailsContent> {
  late TextEditingController _merchantNameController;
  late TextEditingController _merchantAddressController;
  late TextEditingController _totalController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant ReceiptDetailsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receipt != widget.receipt ||
        oldWidget.isEditMode != widget.isEditMode) {
      _initControllers();
    }
  }

  void _initControllers() {
    _merchantNameController =
        TextEditingController(text: widget.receipt.merchant.name);
    _merchantAddressController =
        TextEditingController(text: widget.receipt.merchant.address);
    _totalController =
        TextEditingController(text: widget.receipt.total.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _merchantNameController.dispose();
    _merchantAddressController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.receiptDetails,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        if (_hasMerchantInfo(widget.receipt))
          _buildSection(
            context: context,
            title: l10n.merchant,
            child:
                _buildMerchantInfo(context, widget.receipt, widget.isEditMode),
          ),
        _buildSection(
          context: context,
          title: l10n.transactionDetails,
          child:
              _buildTransactionInfo(context, widget.receipt, widget.isEditMode),
        ),
        Text(
          l10n.items,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _buildItemsList(context, widget.receipt, widget.isEditMode),
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
    final theme = Theme.of(context);

    if (isEditMode) {
      return Column(
        children: [
          TextField(
            controller: _merchantNameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).merchantName,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ),
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
          const SizedBox(height: 16),
          TextField(
            controller: _merchantAddressController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).merchantAddress,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ),
            maxLines: 1,
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
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (receipt.merchant.name.isNotEmpty)
              Text(
                receipt.merchant.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (receipt.merchant.name.isNotEmpty &&
                receipt.merchant.address.isNotEmpty)
              const SizedBox(height: 4),
            if (receipt.merchant.address.isNotEmpty)
              Text(
                receipt.merchant.address,
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      );
    }
  }

  Widget _buildTransactionInfo(
      BuildContext context, Receipt receipt, bool isEditMode) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMMM dd, yyyy - HH:mm');
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    if (isEditMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _showDateTimePicker(context, receipt),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.transactionDate,
                suffixIcon: Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
              child: Text(
                dateFormat.format(receipt.transactionDateTime),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _totalController,
            decoration: InputDecoration(
              labelText: l10n.totalChartData,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [CurrencyTextFormatter(locale: locale)],
            onChanged: (value) {},
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                final parsedValue = double.tryParse(value.replaceAll(',', '.'));
                if (parsedValue != null) {
                  context.read<ReceiptEditBloc>().add(
                        ReceiptEditEvent.updateTotal(parsedValue),
                      );
                }
              } else {
                context.read<ReceiptEditBloc>().add(
                      ReceiptEditEvent.updateTotal(0.0),
                    );
              }
            },
          )
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              context: context,
              label: l10n.transactionDate,
              value: dateFormat.format(receipt.transactionDateTime),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context: context,
              label: l10n.totalChartData,
              value: receipt.total.toStringAsFixed(2),
              isHighlighted: true,
            ),
          ],
        ),
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

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDate),
      );

      if (time != null && context.mounted) {
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
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: isHighlighted
              ? theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildItemsList(
      BuildContext context, Receipt receipt, bool isEditMode) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        physics: const ClampingScrollPhysics(),
        itemCount: receipt.items.length,
        separatorBuilder: (_, __) => Divider(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
          height: 1,
        ),
        itemBuilder: (context, index) => _buildItemRow(
            context, receipt.items[index], isEditMode, index, receipt),
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, ReceiptItem item, bool isEditMode,
      int index, Receipt currentReceipt) {
    final categoryIconPath = CategoryUtils.getIconPath(item.category);
    final categoryName = CategoryUtils.getDisplayName(item.category, context);
    final theme = Theme.of(context);

    if (isEditMode) {
      return InkWell(
        onTap: () => _showEditItemDialog(context, item, index, currentReceipt),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          child: _buildItemRowContent(
              context, item, categoryIconPath, categoryName,
              isEditable: true),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        child:
            _buildItemRowContent(context, item, categoryIconPath, categoryName),
      );
    }
  }

  Widget _buildItemRowContent(BuildContext context, ReceiptItem item,
      String categoryIconPath, String categoryName,
      {bool isEditable = false}) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
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
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    categoryName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2)} × ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.totalPrice.toStringAsFixed(2),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        if (isEditable)
          Icon(
            Icons.edit,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
      ],
    );
  }

  void _showEditItemDialog(BuildContext context, ReceiptItem item, int index,
      Receipt currentReceipt) {
    showDialog(
      context: context,
      builder: (dialogContext) => ReceiptDetailsEditDialog(
        item: item,
        onSave: (updatedItem) {
          final newItems = List<ReceiptItem>.from(currentReceipt.items);
          newItems[index] = updatedItem;

          context.read<ReceiptEditBloc>().add(
                ReceiptEditEvent.updateItems(newItems),
              );
        },
      ),
    );
  }

  Widget _buildSection(
      {required BuildContext context,
      required String title,
      required Widget child}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
