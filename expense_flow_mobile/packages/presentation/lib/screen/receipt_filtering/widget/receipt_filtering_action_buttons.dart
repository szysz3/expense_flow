import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/app_localizations.dart';

import '../bloc/receipt_filtering_bloc.dart';
import '../bloc/receipt_filtering_event.dart';

class ReceiptFilteringActionButtons extends StatelessWidget {
  const ReceiptFilteringActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                context.read<ReceiptFilteringBloc>().add(
                      const ReceiptFilteringEvent.clearFilters(),
                    );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                l10n.clearAllFiltersButton,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Get the current filter params from the bloc state
                final filterParams =
                    context.read<ReceiptFilteringBloc>().state.filterParams;
                // Return the filter params to the calling screen
                Navigator.of(context).pop(filterParams);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                l10n.applyFiltersButton,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
