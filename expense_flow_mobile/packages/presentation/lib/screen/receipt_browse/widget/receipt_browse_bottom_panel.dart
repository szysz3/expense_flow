import 'package:flutter/material.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/core/utils/currency_text_formatter.dart';
import 'package:presentation/core/widget/glass_container.dart';
import 'package:presentation/core/widget/app_spacing.dart';

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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GlassContainer(
                width: double.infinity,
                height: 100,
                blur: 20,
                tintOpacity: 0.55,
                borderRadius: BorderRadius.circular(24),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.isFiltered) ...[
                      Text(
                        AppLocalizations.of(context).totalAmountLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter
                            .formatCurrency(state.filteredTotalAmount),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)
                            .itemsFoundLabel(state.filteredItems.length),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ] else ...[
                      Text(
                        AppLocalizations.of(context).showingAllReceiptsLabel,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.9),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)
                            .totalReceiptsLabel(state.totalCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
