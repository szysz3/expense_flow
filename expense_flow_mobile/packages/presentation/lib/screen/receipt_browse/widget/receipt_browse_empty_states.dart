import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';

import '../../../core/widget/animated_square_button.dart';
import '../../../core/widget/app_spacing.dart';
import '../../receipt_filtering/receipt_filtering_screen.dart';
import '../bloc/receipt_browse_bloc.dart';
import '../bloc/receipt_browse_event.dart';
import '../bloc/receipt_browse_state.dart';
import 'receipt_browse_bottom_panel.dart';

class ReceiptBrowseEmptyState extends StatelessWidget {
  final ReceiptBrowseState state;

  const ReceiptBrowseEmptyState({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'packages/presentation/assets/icon_scan.svg',
                width: 64,
                height: 64,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppLocalizations.of(context).appBarBrowseReceiptsTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context).noReceiptsFound,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSquareButton(
                isProcessing: false,
                onPressed: () {
                  context.read<ReceiptBrowseBloc>().add(
                        const ReceiptBrowseEvent.refresh(),
                      );
                },
                width: 124.0,
                height: 52.0,
                iconSize: 20.0,
                borderColor: Theme.of(context).colorScheme.outline,
                backgroundColor: Theme.of(context).colorScheme.surface,
                icon: Text(
                  AppLocalizations.of(context).refresh,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            ],
          ),
        ),
        ReceiptBrowseBottomPanel(state: state),
        _buildSearchButton(context),
      ],
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 24,
      child: AnimatedSquareButton.square(
        isProcessing: false,
        onPressed: () => _onFilterPressed(context),
        icon: SvgPicture.asset(
          'packages/presentation/assets/icon_search.svg',
          width: 40,
          height: 40,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),
        size: 64,
        iconSize: 40,
      ),
    );
  }

  Future<void> _onFilterPressed(BuildContext context) async {
    final filterParams = await ReceiptFilteringScreen.show(
      context,
      initialParams: state.filterParams,
    );

    if (filterParams != null && context.mounted) {
      if (filterParams.hasActiveFilters) {
        context.read<ReceiptBrowseBloc>().add(
              ReceiptBrowseEvent.applyFilters(filterParams),
            );
      } else {
        context.read<ReceiptBrowseBloc>().add(
              const ReceiptBrowseEvent.clearFilters(),
            );
      }
    }
  }
}

class ReceiptBrowseEmptyFilteredState extends StatelessWidget {
  final ReceiptBrowseState state;

  const ReceiptBrowseEmptyFilteredState({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_off,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppLocalizations.of(context).noItemsMatchFiltersLabel,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context).adjustFiltersHintLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSquareButton(
                isProcessing: false,
                onPressed: () {
                  context.read<ReceiptBrowseBloc>().add(
                        const ReceiptBrowseEvent.clearFilters(),
                      );
                },
                width: 124.0,
                height: 52.0,
                iconSize: 20.0,
                borderColor: Theme.of(context).colorScheme.outline,
                backgroundColor: Theme.of(context).colorScheme.surface,
                icon: Text(
                  AppLocalizations.of(context).clearFiltersLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            ],
          ),
        ),
        ReceiptBrowseBottomPanel(state: state),
        _buildSpeedDialMenu(context),
      ],
    );
  }

  Widget _buildSpeedDialMenu(BuildContext context) {
    return Positioned(
      right: 24,
      bottom: 24,
      child: AnimatedSquareButton.square(
        isProcessing: false,
        onPressed: () => _onFilterPressed(context),
        icon: SvgPicture.asset(
          'packages/presentation/assets/icon_search.svg',
          width: 40,
          height: 40,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),
        size: 64,
        iconSize: 40,
      ),
    );
  }

  Future<void> _onFilterPressed(BuildContext context) async {
    final filterParams = await ReceiptFilteringScreen.show(
      context,
      initialParams: state.filterParams,
    );

    if (filterParams != null && context.mounted) {
      if (filterParams.hasActiveFilters) {
        context.read<ReceiptBrowseBloc>().add(
              ReceiptBrowseEvent.applyFilters(filterParams),
            );
      } else {
        context.read<ReceiptBrowseBloc>().add(
              const ReceiptBrowseEvent.clearFilters(),
            );
      }
    }
  }
}
