import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/service/camera/camera_service.dart';
import '../../di/di.dart';
import '../../navigation/bloc/navigation_bloc.dart';
import '../../navigation/bloc/navigation_state.dart';
import '../../navigation/widget/bottom_navigation.dart';
import '../add_item/add_item_screen.dart';
import '../categories/categories_screen.dart';
import '../receipt_scan/receipt_scan_screen.dart';
import '../summary/summary_screen.dart';
import '../unprocessed_receipts/unprocessed_receipts_screen.dart';
import 'bloc/camera_preview_bloc.dart';
import 'bloc/camera_preview_event.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => NavigationBloc()),
        BlocProvider(
            create: (context) => CameraPreviewBloc(getIt<CameraService>())
              ..add(const CameraPreviewEvent.initialize())),
      ],
      child: Scaffold(
        extendBody: true,
        body: BlocBuilder<NavigationBloc, NavigationState>(
          builder: (context, state) {
            return SafeArea(
                child: IndexedStack(
              index: state.currentIndex,
              children: const [
                ReceiptScanScreen(),
                AddItemScreen(),
                CategoriesScreen(),
                SummaryScreen(),
                UnprocessedReceiptsScreen()
              ],
            ));
          },
        ),
        bottomNavigationBar: const BottomNavigation(),
      ),
    );
  }
}
