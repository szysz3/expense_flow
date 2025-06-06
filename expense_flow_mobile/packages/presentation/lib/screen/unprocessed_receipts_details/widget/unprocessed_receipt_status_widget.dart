import 'package:domain/model/unprocessed_receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';

import '../../../theme/expense_flow_colors.dart';

class UnprocessedReceiptStatusWidget extends StatelessWidget {
  final UnprocessedReceiptStatus status;
  final String? errorMessage;

  const UnprocessedReceiptStatusWidget({
    super.key,
    required this.status,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 12),
              Text(
                _getStatusText(l10n),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
              ),
            ],
          ),
          if (status == UnprocessedReceiptStatus.error &&
              errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ExpenseFlowColors.chartRed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    String iconName;
    switch (status) {
      case UnprocessedReceiptStatus.pending:
        iconName = 'icon_pending.svg';
        break;
      case UnprocessedReceiptStatus.processing:
        iconName = 'icon_processing.svg';
        break;
      case UnprocessedReceiptStatus.error:
        iconName = 'icon_error.svg';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SvgPicture.asset(
        'packages/presentation/assets/$iconName',
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(_getStatusColor(), BlendMode.srcIn),
      ),
    );
  }

  String _getStatusText(AppLocalizations l10n) {
    switch (status) {
      case UnprocessedReceiptStatus.pending:
        return l10n.statusPending;
      case UnprocessedReceiptStatus.processing:
        return l10n.statusProcessing;
      case UnprocessedReceiptStatus.error:
        return l10n.statusError;
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case UnprocessedReceiptStatus.pending:
        return Colors.orange;
      case UnprocessedReceiptStatus.processing:
        return Colors.blue;
      case UnprocessedReceiptStatus.error:
        return ExpenseFlowColors.chartRed;
    }
  }
}
