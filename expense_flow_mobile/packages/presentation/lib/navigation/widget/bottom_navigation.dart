import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/navigation/bloc/navigation_bloc.dart';
import 'package:presentation/navigation/bloc/navigation_event.dart';
import 'package:presentation/navigation/bloc/navigation_state.dart';
import 'package:presentation/theme/expense_flow_color_scheme.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

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
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.photo),
              backgroundColor: colorScheme.accentDelicate.withAlpha(100),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category),
              backgroundColor: colorScheme.accentMild,
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.money),
              backgroundColor: colorScheme.accentNormal,
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.summarize),
              backgroundColor: colorScheme.accentIntense,
              label: 'Summary',
            ),
          ],
        );
      },
    );
  }
}
