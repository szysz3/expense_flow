import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                  width: 1,
                ),
              ),
            ),
            child: AppBar(
              title: BlocBuilder<NavigationBloc, NavigationState>(
                builder: (context, state) {
                  switch (state.currentIndex) {
                    case 0:
                      return Text(
                          AppLocalizations.of(context).appBarScanReceiptsTitle);
                    case 1:
                      return Text(
                          AppLocalizations.of(context).appBarAddItemTitle);
                    case 2:
                      return Text(
                          AppLocalizations.of(context).appBarCategoriesTitle);
                    case 3:
                      return Text(
                          AppLocalizations.of(context).appBarSummaryTitle);
                    case 4:
                      return Text(AppLocalizations.of(context)
                          .appBarUnprocessedReceiptsTitle);
                    default:
                      return const Text('');
                  }
                },
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // TODO: Navigate to settings screen
                  },
                  tooltip: 'Settings',
                ),
              ],
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
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
