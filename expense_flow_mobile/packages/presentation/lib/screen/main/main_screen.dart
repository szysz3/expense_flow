import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presentation/navigation/bloc/navigation_bloc.dart';
import 'package:presentation/navigation/bloc/navigation_state.dart';
import 'package:presentation/navigation/widget/bottom_navigation.dart';
import 'package:presentation/screen/receipt_scan/receipt_scan_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavigationBloc(),
      child: Scaffold(
        body: BlocBuilder<NavigationBloc, NavigationState>(
          builder: (context, state) {
            return IndexedStack(
              index: state.currentIndex,
              children: const [
                ReceiptScanScreen(),
                Center(child: Text('Categories')),
                Center(child: Text('Orders')),
                Center(child: Text('Summary')),
              ],
            );
          },
        ),
        bottomNavigationBar: const BottomNavigation(),
      ),
    );
  }
}
