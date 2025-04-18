import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:presentation/navigation/bloc/navigation_bloc.dart';
import 'package:presentation/navigation/bloc/navigation_event.dart';
import 'package:presentation/navigation/bloc/navigation_state.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  static const _iconScan = 'icon_scan.svg';
  static const _iconCategories = 'icon_categories.svg';
  static const _iconOrders = 'icon_standing_orders.svg';
  static const _iconSummary = 'icon_summary.svg';
  static const _iconBrowse = 'icon_browse.svg';

  List<(String, String)> _getNavigationItems(BuildContext context) {
    return [
      (AppLocalizations.of(context).scan, _iconScan),
      (AppLocalizations.of(context).orders, _iconOrders),
      (AppLocalizations.of(context).categories, _iconCategories),
      (AppLocalizations.of(context).summary, _iconSummary),
      (AppLocalizations.of(context).browse, _iconBrowse),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withAlpha(50),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: colorScheme.onSurface,
            unselectedItemColor: colorScheme.onSurface.withAlpha(100),
            currentIndex: state.currentIndex,
            onTap: (index) {
              context
                  .read<NavigationBloc>()
                  .add(NavigationEvent.navigateToIndex(index));
            },
            items: _getNavigationItems(context)
                .map(
                  (item) => BottomNavigationBarItem(
                    icon: _buildSvgIcon(
                      item.$2,
                    ),
                    activeIcon: _buildSvgIcon(
                      item.$2,
                    ),
                    backgroundColor: Colors.transparent,
                    label: item.$1,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSvgIcon(String assetName) {
    return SvgPicture.asset(
      'packages/presentation/assets/$assetName',
      width: 24,
      height: 24,
    );
  }
}
