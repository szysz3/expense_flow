import 'package:dartz/dartz.dart';

import '../../model/failure/failures.dart';
import '../../model/unprocessed_receipt.dart';
import '../../repository/unprocessed_receipt_repository.dart';

class UnprocessedReceiptUpdateUseCase {
  final UnprocessedReceiptRepository _repository;

  UnprocessedReceiptUpdateUseCase(this._repository);

  Future<Either<Failure, UnprocessedReceipt>> call(
      UnprocessedReceipt receipt) async {
    return await _repository.updateUnprocessedReceipt(receipt);
  }
}
