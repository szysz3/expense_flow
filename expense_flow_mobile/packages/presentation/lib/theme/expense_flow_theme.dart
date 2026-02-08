import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:presentation/theme/expense_flow_colors.dart';

class ExpenseFlowTheme {
  static final darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: ExpenseFlowColors.darkPrimary,
    onPrimary: ExpenseFlowColors.darkOnPrimary,
    primaryContainer: ExpenseFlowColors.darkAccentNormal,
    onPrimaryContainer: ExpenseFlowColors.darkOnSurface,
    secondary: ExpenseFlowColors.darkSecondary,
    onSecondary: ExpenseFlowColors.darkOnSecondary,
    secondaryContainer: ExpenseFlowColors.darkAccentMild,
    onSecondaryContainer: ExpenseFlowColors.darkOnSurface,
    tertiary: ExpenseFlowColors.darkTertiary,
    onTertiary: ExpenseFlowColors.darkOnTertiary,
    tertiaryContainer: ExpenseFlowColors.darkAccentIntense,
    onTertiaryContainer: ExpenseFlowColors.darkOnSurface,
    error: ExpenseFlowColors.darkError,
    onError: ExpenseFlowColors.darkOnSurface,
    errorContainer: ExpenseFlowColors.darkError.withValues(alpha: 0.35),
    onErrorContainer: ExpenseFlowColors.darkOnSurface,
    surface: ExpenseFlowColors.darkSurface,
    onSurface: ExpenseFlowColors.darkOnSurface,
    surfaceVariant: ExpenseFlowColors.darkAccentMild,
    onSurfaceVariant: ExpenseFlowColors.darkOnSurface.withValues(alpha: 0.8),
    outline: ExpenseFlowColors.darkOutline,
    outlineVariant: ExpenseFlowColors.darkOutline.withValues(alpha: 0.6),
    shadow: ExpenseFlowColors.darkShadow,
    scrim: ExpenseFlowColors.darkShadow.withValues(alpha: 0.6),
    inverseSurface: ExpenseFlowColors.darkOnSurface,
    onInverseSurface: ExpenseFlowColors.darkSurface,
    inversePrimary: ExpenseFlowColors.darkPrimary,
    surfaceTint: ExpenseFlowColors.darkPrimary,
    background: ExpenseFlowColors.darkBackground,
    onBackground: ExpenseFlowColors.darkOnSurface,
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: ExpenseFlowColors.darkBackground,
    textTheme: _buildTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ExpenseFlowColors.darkOnSurface,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ExpenseFlowColors.darkOnSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: ExpenseFlowColors.darkSurface.withValues(alpha: 0.7),
      elevation: 0,
      shadowColor: ExpenseFlowColors.darkShadow.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: ExpenseFlowColors.darkOnSurface,
      unselectedItemColor:
          ExpenseFlowColors.darkOnSurface.withValues(alpha: 0.6),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ExpenseFlowColors.darkSurface.withValues(alpha: 0.9),
      contentTextStyle: GoogleFonts.manrope(
        color: ExpenseFlowColors.darkOnSurface,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: InputBorder.none,
      labelStyle: GoogleFonts.manrope(
        color: ExpenseFlowColors.darkOnSurface.withValues(alpha: 0.7),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.manrope(
        color: ExpenseFlowColors.darkOnSurface.withValues(alpha: 0.5),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: ExpenseFlowColors.darkOutline.withValues(alpha: 0.5),
      thickness: 1,
    ),
    iconTheme: const IconThemeData(
      color: ExpenseFlowColors.darkOnSurface,
    ),
  );

  static TextTheme _buildTextTheme() {
    final base = GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme);
    final display = GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme);

    return base.copyWith(
      displayLarge: display.displayLarge,
      displayMedium: display.displayMedium,
      displaySmall: display.displaySmall,
      headlineLarge: display.headlineLarge,
      headlineMedium: display.headlineMedium,
      headlineSmall: display.headlineSmall,
      titleLarge: display.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: display.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
