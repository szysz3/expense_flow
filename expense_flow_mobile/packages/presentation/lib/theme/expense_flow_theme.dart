import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:presentation/theme/expense_flow_colors.dart';

class ExpenseFlowTheme {
  static final lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: ExpenseFlowColors.lightPrimary,
    onPrimary: ExpenseFlowColors.lightOnPrimary,
    secondary: ExpenseFlowColors.lightSecondary,
    onSecondary: ExpenseFlowColors.lightOnSecondary,
    error: ExpenseFlowColors.lightError,
    onError: Colors.white,
    surface: ExpenseFlowColors.lightSurface,
    onSurface: Colors.black,
  );

  static final darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: ExpenseFlowColors.darkPrimary,
    onPrimary: ExpenseFlowColors.darkOnPrimary,
    secondary: ExpenseFlowColors.darkSecondary,
    onSecondary: ExpenseFlowColors.darkOnSecondary,
    error: ExpenseFlowColors.darkError,
    onError: Colors.white,
    surface: ExpenseFlowColors.darkBackground,
    onSurface: Colors.white,
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    textTheme: GoogleFonts.chakraPetchTextTheme(ThemeData.dark().textTheme),
  );
}
