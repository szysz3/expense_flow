import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localization/app_localizations.dart';
import 'package:logger/logger.dart';
import 'package:presentation/config/flavor_config.dart';
import 'package:presentation/core/service/notification/notification_service.dart';
import 'package:presentation/di/di.dart';
import 'package:presentation/screen/main/main_screen.dart';
import 'package:presentation/theme/expense_flow_theme.dart';

import 'notification_handler.dart';

Future<void> main() async {
  if (FlavorConfig.appFlavor == null) {
    throw Exception('App must be started with a flavor. Use:\n'
        '- flutter run --flavor prod -t lib/main_prod.dart\n'
        '- flutter run --flavor demo -t lib/main_demo.dart');
  }

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await configureDependencies();

  final logger = getIt<Logger>();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize notifications in background without blocking app startup
    // Token registration will complete asynchronously while app is already usable
    final notificationService = getIt<NotificationService>();
    notificationService.initialize().catchError((e, stackTrace) {
      logger.e(
        'Failed to initialize notifications - app will continue without push notifications',
        error: e,
        stackTrace: stackTrace,
      );
    });
  } catch (e, stackTrace) {
    logger.e(
      'Failed to initialize Firebase',
      error: e,
      stackTrace: stackTrace,
    );
  }

  runApp(const ExpenseFlowApp());
}

class ExpenseFlowApp extends StatelessWidget {
  const ExpenseFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: FlavorConfig.title,
      scrollBehavior: const NoGlowScrollBehavior(),
      theme: ExpenseFlowTheme.darkTheme,
      darkTheme: ExpenseFlowTheme.darkTheme,
      themeMode: ThemeMode.dark,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate],
      home: FlavorConfig.isDemo
          ? Banner(
              message: 'DEMO',
              location: BannerLocation.topStart,
              child: MainScreen(),
            )
          : MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NoGlowScrollBehavior extends ScrollBehavior {
  const NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
