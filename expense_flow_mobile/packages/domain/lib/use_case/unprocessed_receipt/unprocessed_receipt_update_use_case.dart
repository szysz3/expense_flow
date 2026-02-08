import 'package:dartz/dartz.dart';

import '../../model/failure/failures.dart';
import '../../model/unprocessed_receipt.dart';
import '../../repository/unprocessed_receipt_repository.dart';

class UnprocessedReceiptUpdateUseCase {
  final UnprocessedReceiptRepository _repository;

  UnprocessedReceiptUpdateUseCase(this._repository);

  Future<Either<Failure, UnprocessedReceipt>> call(
      UnprocessedReceipt receipt) async {
    final normalizedReceipt = _normalizeTransactionDate(receipt);
    return await _repository.updateUnprocessedReceipt(normalizedReceipt);
  }

  /// Ensures transactionDatetime is never null when persisting.
  /// Falls back to createdAt if the original date was invalid/missing.
  UnprocessedReceipt _normalizeTransactionDate(UnprocessedReceipt receipt) {
    if (receipt.rawData.transactionDatetime != null) {
      return receipt;
    }

    return receipt.copyWith(
      rawData: receipt.rawData.copyWith(
        transactionDatetime: receipt.createdAt,
      ),
    );
  }
}
