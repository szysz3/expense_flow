import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localization/app_localizations.dart';
import 'package:presentation/config/flavor_config.dart';
import 'package:presentation/di/di.dart';
import 'package:presentation/screen/main/main_screen.dart';
import 'package:presentation/theme/expense_flow_theme.dart';

Future<void> main() async {
  if (FlavorConfig.appFlavor == null) {
    throw Exception('App must be started with a flavor. Use:\n'
        '- flutter run --flavor prod -t lib/main_prod.dart\n'
        '- flutter run --flavor demo -t lib/main_demo.dart');
  }

  print('---> Running with flavor: ${FlavorConfig.name}');

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await configureDependencies();
  runApp(const ExpenseFlowApp());
}

class ExpenseFlowApp extends StatelessWidget {
  const ExpenseFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: FlavorConfig.title,
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
