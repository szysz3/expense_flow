import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:presentation/navigation/bloc/navigation_bloc.dart';
import 'package:presentation/navigation/bloc/navigation_event.dart';
import 'package:presentation/navigation/bloc/navigation_state.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  // Constants for icon assets
  static const _iconScan = 'icon_scan.svg';
  static const _iconCategories = 'icon_categories.svg';
  static const _iconOrders = 'icon_orders.svg';
  static const _iconSummary = 'icon_summary.svg';

  // Navigation items configuration
  static const _navigationItems = [
    ('Scan', _iconScan),
    ('Orders', _iconOrders),
    ('Categories', _iconCategories),
    ('Summary', _iconSummary),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return BottomNavigationBar(
          elevation: 0,
          selectedItemColor: colorScheme.onSurface,
          unselectedItemColor: colorScheme.onSurface.withAlpha(100),
          currentIndex: state.currentIndex,
          onTap: (index) {
            context.read<NavigationBloc>().add(NavigateToIndex(index));
          },
          items: _navigationItems
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
