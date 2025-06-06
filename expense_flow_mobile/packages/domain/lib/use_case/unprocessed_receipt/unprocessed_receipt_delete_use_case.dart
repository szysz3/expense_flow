import 'package:dartz/dartz.dart';

import '../../model/failure/failures.dart';
import '../../repository/unprocessed_receipt_repository.dart';

class UnprocessedReceiptDeleteParams {
  final String id;

  UnprocessedReceiptDeleteParams({required this.id});
}

class UnprocessedReceiptDeleteUseCase {
  final UnprocessedReceiptRepository _repository;

  UnprocessedReceiptDeleteUseCase(this._repository);

  Future<Either<Failure, bool>> call(
      UnprocessedReceiptDeleteParams params) async {
    return await _repository.deleteUnprocessedReceipt(params.id);
  }
}
