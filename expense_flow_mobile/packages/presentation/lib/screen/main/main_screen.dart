import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:localization/app_localizations.dart';
import 'package:logger/logger.dart';

import '../../core/service/camera/camera_service.dart';
import '../../core/service/notification/notification_service.dart';
import '../../di/di.dart';
import '../../navigation/bloc/navigation_bloc.dart';
import '../../navigation/bloc/navigation_event.dart';
import '../../navigation/bloc/navigation_state.dart';
import '../../navigation/widget/bottom_navigation.dart';
import '../../navigation/widget/drawer_menu.dart';
import '../add_item/add_item_screen.dart';
import '../categories/categories_screen.dart';
import '../receipt_browse/receipt_browse_screen.dart';
import '../receipt_scan/receipt_scan_screen.dart';
import '../summary/summary_screen.dart';
import 'bloc/camera_preview_bloc.dart';
import 'bloc/camera_preview_event.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const int _receiptBrowseTabIndex = 4;
  static const Duration _snackbarDuration = Duration(seconds: 4);

  final _logger = getIt<Logger>();
  final _notificationService = getIt<NotificationService>();

  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
    _checkInitialMessage();
  }

  void _setupNotificationHandlers() {
    _notificationService.setupNotificationHandlers(
      onMessageReceived: _handleForegroundMessage,
      onMessageOpenedApp: _handleNotificationTap,
    );
  }

  Future<void> _checkInitialMessage() async {
    // Check if app was opened from a terminated state via notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _logger.i('App opened from notification (terminated): ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Foreground message received: ${message.notification?.title}');

    // Show in-app notification snackbar
    if (message.notification != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification!.title ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (message.notification!.body != null)
                Text(message.notification!.body!),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _handleNotificationTap(message),
          ),
          duration: _snackbarDuration,
        ),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('Notification tapped: ${message.data}');

    final receiptId = message.data['receipt_id'];
    if (receiptId != null && mounted) {
      _logger.i('Navigating to receipt: $receiptId');

      context.read<NavigationBloc>().add(
        NavigationEvent.navigateToIndex(_receiptBrowseTabIndex),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Receipt processed: ${message.data['merchant_name'] ?? 'Unknown'}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      });
    }
  }

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
        drawer: const DrawerMenu(),
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
                          .appBarBrowseReceiptsTitle);
                    default:
                      return const Text('');
                  }
                },
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: SvgPicture.asset(
                    'packages/presentation/assets/icon_menu.svg',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip:
                      MaterialLocalizations.of(context).openAppDrawerTooltip,
                ),
              ),
              centerTitle: true,
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
                ReceiptBrowseScreen(),
              ],
            ));
          },
        ),
        bottomNavigationBar: const BottomNavigation(),
      ),
    );
  }
}
