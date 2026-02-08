import 'package:flutter/material.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/core/widget/glass_container.dart';
import 'package:presentation/core/widget/app_spacing.dart';

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
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
    final theme = Theme.of(context);

    return GlassContainer(
      blur: 16,
      tintOpacity: 0.5,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.clear,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
