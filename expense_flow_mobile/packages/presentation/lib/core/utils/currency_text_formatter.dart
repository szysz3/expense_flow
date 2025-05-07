import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyTextFormatter extends TextInputFormatter {
  final String locale;

  CurrencyTextFormatter({required this.locale});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final format = NumberFormat.decimalPattern(locale);
    final decimalSeparator = format.symbols.DECIMAL_SEP;
    final regExp = RegExp('[0-9.,]');

    String filtered =
        newValue.text.split('').where((char) => regExp.hasMatch(char)).join();

    if (filtered.contains('.') || filtered.contains(',')) {
      filtered = filtered
          .replaceAll(',', decimalSeparator)
          .replaceAll('.', decimalSeparator);

      final parts = filtered.split(decimalSeparator);
      if (parts.length > 2) {
        filtered = parts[0] + decimalSeparator + parts.sublist(1).join('');
      }
    }

    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }

  static String normalizeNumberString(String value, String locale) {
    final format = NumberFormat.decimalPattern(locale);
    final decimalSeparator = format.symbols.DECIMAL_SEP;

    if (decimalSeparator != '.') {
      return value.replaceAll(decimalSeparator, '.');
    }
    return value;
  }

  String formatCurrency(double amount,
      {String? symbol, int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '',
      decimalDigits: decimalDigits,
    );

    return formatter.format(amount);
  }
}
