import 'package:domain/model/receipt.dart';
import 'package:domain/use_case/delete_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:localization/localization_service.dart';
import 'package:logger/logger.dart';

import '../../../core/error/error_utils.dart';
import '../../../core/widget/animated_square_button.dart';
import '../../../di/di.dart';
import '../receipt_browse/bloc/receipt_browse_bloc.dart';
import '../receipt_browse/bloc/receipt_browse_event.dart';
import 'bloc/receipt_detail_bloc.dart';
import 'bloc/receipt_detail_event.dart';
import 'bloc/receipt_detail_state.dart';

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
      builder: (modalContext) => BlocProvider(
        create: (_) => ReceiptDetailBloc(
          getIt<DeleteReceiptUseCase>(),
          getIt<Logger>(),
          getIt<LocalizationService>(),
        ),
        child: BlocProvider.value(
          value: context.read<ReceiptBrowseBloc>(),
          child: ReceiptDetailScreen(receipt: receipt),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReceiptDetailBloc, ReceiptDetailState>(
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
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.99,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              _buildModalHeader(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildContent(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _buildDeleteButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMMM dd, yyyy - HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.receiptDetails,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),

        if (receipt.merchant.name.isNotEmpty ||
            receipt.merchant.address.isNotEmpty)
          _buildInfoSection(
            title: l10n.merchant,
            child: Column(
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
            ),
          ),

        // Transaction Information
        _buildInfoSection(
          title: l10n.transactionDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${l10n.transactionDate}: ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    dateFormat.format(receipt.transactionDateTime),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  Text('${l10n.totalChartData}: ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    receipt.total.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),

        _buildInfoSection(
          title: l10n.items,
          child: SizedBox(
            height: 300,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: receipt.items.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white12),
              itemBuilder: (context, index) {
                final item = receipt.items[index];
                return _buildItemRow(context, item);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection({required String title, required Widget child}) {
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

  Widget _buildItemRow(BuildContext context, dynamic item) {
    final categoryIconPath =
        'packages/presentation/assets/icon_${item.category}.svg';

    String categoryDisplayName =
        _getCategoryDisplayName(item.category.toString());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    categoryDisplayName,
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

  String _getCategoryDisplayName(String category) {
    final parts = category.split('_');
    final titleCase = parts
        .map((part) => part.isNotEmpty
            ? '${part[0].toUpperCase()}${part.substring(1)}'
            : '')
        .join(' ');

    return titleCase;
  }

  Widget _buildDeleteButton(BuildContext context) {
    return BlocBuilder<ReceiptDetailBloc, ReceiptDetailState>(
      builder: (context, state) {
        return AnimatedSquareButton(
          isProcessing: state.isDeleting,
          onPressed: () => _confirmDelete(context),
          width: 160.0,
          height: 52.0,
          iconSize: 20.0,
          borderColor: Colors.red,
          backgroundColor: Colors.red.withOpacity(0.3),
          icon: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete,
                color: Colors.red.shade300,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).delete,
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final l10n = AppLocalizations.of(context);

        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(l10n.deleteConfirmation),
          content: Text(l10n.deleteReceiptConfirmMessage),
          actions: [
            TextButton(
              child: Text(
                l10n.cancel,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                l10n.delete,
                style: const TextStyle(color: Colors.red),
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
        );
      },
    );
  }
}
