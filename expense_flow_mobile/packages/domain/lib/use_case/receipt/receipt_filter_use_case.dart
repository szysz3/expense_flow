import 'package:dartz/dartz.dart';

import '../../model/failure/failures.dart';
import '../../model/filtered_receipt_item.dart';
import '../../model/receipt.dart';
import '../../model/receipt_filter_params.dart';
import '../../model/receipt_filter_response.dart';
import '../../repository/receipt_repository.dart';
import '../base/base_use_case.dart';

class ReceiptFilterUseCase
    implements
        BaseUseCase<ReceiptFilterParams,
            Either<Failure, ReceiptFilterResponse>> {
  final ReceiptRepository repository;

  ReceiptFilterUseCase(this.repository);

  @override
  Future<Either<Failure, ReceiptFilterResponse>> call(
      ReceiptFilterParams params) async {
    try {
      final allReceiptsResult = await _getAllReceipts();

      return allReceiptsResult.fold(
        (failure) => Left(failure),
        (allReceipts) {
          final filteredItems = <FilteredReceiptItem>[];

          for (final receipt in allReceipts) {
            if (params.startDate != null &&
                receipt.transactionDateTime.isBefore(params.startDate!)) {
              continue;
            }

            if (params.endDate != null) {
              final endOfEndDate = params.endDate!.add(const Duration(days: 1));
              if (receipt.transactionDateTime.isAfter(endOfEndDate) ||
                  receipt.transactionDateTime.isAtSameMomentAs(endOfEndDate)) {
                continue;
              }
            }

            for (final item in receipt.items) {
              if (params.categories.isNotEmpty &&
                  (item.category == null ||
                      !params.categories.contains(item.category))) {
                continue;
              }

              // TODO: skip search filter for now as requested

              filteredItems.add(FilteredReceiptItem(
                item: item,
                parentReceipt: receipt,
              ));
            }
          }

          final totalAmount = filteredItems.fold(
            0.0,
            (sum, item) => sum + item.amount,
          );

          return Right(ReceiptFilterResponse(
            items: filteredItems,
            totalAmount: totalAmount,
            totalCount: filteredItems.length,
          ));
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Fetches all receipts by paginating through all pages
  Future<Either<Failure, List<Receipt>>> _getAllReceipts() async {
    final allReceipts = <Receipt>[];
    int currentPage = 1;
    const int pageSize = 100;

    while (true) {
      final result = await repository.getReceipts(currentPage, pageSize);

      // Check if this page request failed
      if (result is Left) {
        return result as Either<Failure, List<Receipt>>;
      }

      final response = (result as Right).value;
      allReceipts.addAll(response.receipts);

      // Check if we've received all receipts
      // If we got fewer receipts than the page size, we're done
      // Or if we've fetched all receipts based on total count
      if (response.receipts.length < pageSize ||
          allReceipts.length >= response.totalCount) {
        break;
      }

      currentPage++;
    }

    return Right(allReceipts);
  }
}
