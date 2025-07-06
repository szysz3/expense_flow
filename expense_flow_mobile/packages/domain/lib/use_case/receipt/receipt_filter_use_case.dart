import 'package:dartz/dartz.dart';

import '../../model/failure/failures.dart';
import '../../model/filtered_receipt_item.dart';
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
      // TODO: Get all receipts (you might want to implement pagination here)
      final result = await repository.getReceipts(1, 100);

      return result.fold(
        (failure) => Left(failure),
        (response) {
          final filteredItems = <FilteredReceiptItem>[];

          for (final receipt in response.receipts) {
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
}
