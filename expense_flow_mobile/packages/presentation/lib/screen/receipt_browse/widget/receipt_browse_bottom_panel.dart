import 'package:flutter/material.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/core/utils/currency_text_formatter.dart';

import '../bloc/receipt_browse_state.dart';

class ReceiptBrowseBottomPanel extends StatelessWidget {
  final ReceiptBrowseState state;

  const ReceiptBrowseBottomPanel({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final currencyFormatter = CurrencyTextFormatter(locale: locale);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          ),
          Container(
            height: 112,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(50),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 80, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state.isFiltered) ...[
                    Text(
                      AppLocalizations.of(context).totalAmountLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter
                          .formatCurrency(state.filteredTotalAmount),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)
                          .itemsFoundLabel(state.filteredItems.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                    ),
                  ] else ...[
                    Text(
                      AppLocalizations.of(context).showingAllReceiptsLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)
                          .totalReceiptsLabel(state.totalCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
