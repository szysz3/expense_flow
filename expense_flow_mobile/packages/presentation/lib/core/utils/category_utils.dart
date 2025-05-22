import 'package:domain/model/category.dart';
import 'package:flutter/material.dart';
import 'package:localization/app_localizations.dart';

class CategoryUtils {
  CategoryUtils._();

  static String getDisplayName(String? categoryId, [BuildContext? context]) {
    final id = Category.ensureValid(categoryId);

    if (context != null) {
      final l10n = AppLocalizations.of(context);
      switch (id) {
        case Category.groceries:
          return l10n.groceries;
        case Category.alcoholicBeverages:
          return l10n.alcohol;
        case Category.personalCare:
          return l10n.personalCare;
        case Category.household:
          return l10n.household;
        case Category.clothing:
          return l10n.clothing;
        case Category.entertainment:
          return l10n.entertainment;
        case Category.transportation:
          return l10n.transportation;
        case Category.pet:
          return l10n.pet;
        case Category.standingOrders:
          return l10n.standingOrders;
        case Category.other:
        default:
          return l10n.other;
      }
    }

    return _formatCategoryId(id);
  }

  static String getIconPath(String? categoryId) {
    final id = Category.ensureValid(categoryId);
    return 'packages/presentation/assets/icon_$id.svg';
  }

  static String _formatCategoryId(String id) {
    return id
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  static List<MapEntry<String, String>> getAllCategoriesForDropdown(
      BuildContext context) {
    return Category.all.map((id) {
      return MapEntry(id, getDisplayName(id, context));
    }).toList();
  }
}
