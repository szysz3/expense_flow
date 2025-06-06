class ApiConstants {
  static const String apiPrefix = '/api';
  static const String receiptPrefix = '$apiPrefix/receipts';
  static const String tempReceiptPrefix = '$apiPrefix/temp-receipts';

  static const String analyze = '$receiptPrefix/analyze';
  static const String receipt = '$receiptPrefix/';
  static const String search = '$receiptPrefix/search';
  static const String categories = '$apiPrefix/categories';
  static const String monthsSummary = '$apiPrefix/months/summary';
  static const String createReceipt = '$receiptPrefix/create';
  static const String unprocessedReceipts = '$receiptPrefix/unprocessed';
  static const String dailyExpenses =
      '$apiPrefix/months/{year}/{month}/daily-expenses';
  static const String autocomplete = '$apiPrefix/autocomplete';
  static const String tempReceipt = '$tempReceiptPrefix/';
}
