import 'package:flutter/material.dart';
import 'package:localization/app_localizations.dart';

class ReceiptFilteringSearchSection extends StatelessWidget {
  const ReceiptFilteringSearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.searchLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        const SearchTextField(),
      ],
    );
  }
}

class SearchTextField extends StatelessWidget {
  const SearchTextField({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.4),
      ),
      child: TextField(
        textInputAction: TextInputAction.done,
        onSubmitted: (value) {
          FocusScope.of(context).unfocus();
        },
        decoration: InputDecoration(
          labelText: l10n.searchReceiptsHint,
          hintText: l10n.searchDescriptionHint,
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.clear,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              // TODO: Add bloc event to clear search
            },
          ),
        ),
        onChanged: (value) {
          // TODO: Add bloc event
        },
      ),
    );
  }
}
