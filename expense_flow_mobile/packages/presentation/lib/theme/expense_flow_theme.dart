import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:presentation/theme/expense_flow_colors.dart';

class ExpenseFlowTheme {
  static final darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: ExpenseFlowColors.darkPrimary,
    onPrimary: ExpenseFlowColors.darkOnPrimary,
    secondary: ExpenseFlowColors.darkSecondary,
    onSecondary: ExpenseFlowColors.darkOnSecondary,
    error: ExpenseFlowColors.darkError,
    errorContainer: ExpenseFlowColors.darkError,
    onError: Colors.white,
    surface: ExpenseFlowColors.darkBackground,
    onSurface: Colors.white,
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    textTheme: GoogleFonts.chakraPetchTextTheme(ThemeData.dark().textTheme),
  );
}
