import 'package:flutter/material.dart';
import 'package:presentation/screen/main/main_screen.dart';
import 'package:presentation/theme/expense_flow_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExpenseFlowApp());
}

class ExpenseFlowApp extends StatelessWidget {
  const ExpenseFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Flow',
      theme: ExpenseFlowTheme.lightTheme,
      darkTheme: ExpenseFlowTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: MainScreen(),
    );
  }
}
