import '../consts/api_constants.dart';

class ApiEndpoints {
  static const String analyze = ApiConstants.analyze;
  static const String receipt = ApiConstants.receipt;
  static const String search = ApiConstants.search;
  static const String categories = ApiConstants.categories;
  static const String monthsSummary = ApiConstants.monthsSummary;
  static const String createReceipt = ApiConstants.createReceipt;
  static const String unprocessedReceipts = ApiConstants.unprocessedReceipts;
  static const String receipts = ApiConstants.receiptPrefix;
  static const String autocomplete = ApiConstants.autocomplete;

  static String dailyExpenses(int year, int month) => ApiConstants.dailyExpenses
      .replaceAll('{year}', year.toString())
      .replaceAll('{month}', month.toString());
}
