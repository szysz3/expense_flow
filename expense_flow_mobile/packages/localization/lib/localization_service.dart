import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Service to provide localized strings without requiring a BuildContext
class LocalizationService {
  final Locale _locale;
  late final AppLocalizations _localizations;

  LocalizationService({required Locale locale}) : _locale = locale {
    _initializeLocalizations();
  }

  void _initializeLocalizations() {
    _localizations = lookupAppLocalizations(_locale);
  }

  AppLocalizations get localizations => _localizations;

  factory LocalizationService.fromLocaleName(String localeName) {
    return LocalizationService(
      locale: Locale(localeName),
    );
  }
}
