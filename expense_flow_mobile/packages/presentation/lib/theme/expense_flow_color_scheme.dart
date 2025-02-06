import 'package:flutter/material.dart';
import 'package:presentation/theme/expense_flow_colors.dart';

extension CustomColorScheme on ColorScheme {
  Color get accentDelicate => brightness == Brightness.light
      ? ExpenseFlowColors.lightAccentDelicate
      : ExpenseFlowColors.darkAccentDelicate;

  Color get accentMild => brightness == Brightness.light
      ? ExpenseFlowColors.lightAccentMild
      : ExpenseFlowColors.darkAccentMild;

  Color get accentNormal => brightness == Brightness.light
      ? ExpenseFlowColors.lightAccentNormal
      : ExpenseFlowColors.darkAccentNormal;

  Color get accentIntense => brightness == Brightness.light
      ? ExpenseFlowColors.lightAccentIntense
      : ExpenseFlowColors.darkAccentIntense;
}
