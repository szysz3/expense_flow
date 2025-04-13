import 'package:dartz/dartz.dart';

import '../model/category_with_items.dart';
import '../model/daily_expense.dart';
import '../model/failure/failures.dart';
import '../model/month_summary.dart';
import '../model/receipt.dart';
import '../model/receipt_item.dart';
import '../model/receipt_query.dart';
import '../model/search_result.dart';
import '../model/unprocessed_receipt.dart';
import '../use_case/get_receipts_use_case.dart';

abstract class ReceiptRepository {
  Future<Either<Failure, Receipt>> analyzeReceipt(String filePath,
      {String llmType = 'local'});

  Future<Either<Failure, Receipt>> getReceipt(String id);

  Future<Either<Failure, SearchResult>> searchReceipts(ReceiptQuery query);

  Future<Either<Failure, List<CategoryWithItems>>> getCategories();

  Future<Either<Failure, List<MonthSummary>>> getMonthsSummary();

  Future<Either<Failure, Receipt>> createReceipt(
      {required ReceiptItem receiptItem});

  Future<Either<Failure, UnprocessedReceiptsResponse>> getUnprocessedReceipts();

  Future<Either<Failure, List<DailyExpense>>> getDailyExpenses(
      int year, int month);

  Future<Either<Failure, ReceiptsResponse>> getReceipts(int page, int pageSize);
}
