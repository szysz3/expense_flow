import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/navigation/bloc/navigation_bloc.dart';
import 'package:presentation/navigation/bloc/navigation_event.dart';
import 'package:presentation/navigation/bloc/navigation_state.dart';

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return BottomNavigationBar(
          currentIndex: state.currentIndex,
          onTap: (index) {
            context.read<NavigationBloc>().add(NavigateToIndex(index));
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.photo),
              backgroundColor: Colors.deepOrange,
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category),
              backgroundColor: Colors.blueGrey,
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.money),
              backgroundColor: Colors.amber,
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.summarize),
              backgroundColor: Colors.indigo,
              label: 'Summary',
            ),
          ],
        );
      },
    );
  }
}
