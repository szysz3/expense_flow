import 'package:dartz/dartz.dart';

import '../model/failure/failures.dart';
import '../model/unprocessed_receipt.dart';

abstract class UnprocessedReceiptRepository {
  Future<Either<Failure, UnprocessedReceiptsResponse>> getUnprocessedReceipts();

  Future<Either<Failure, bool>> deleteUnprocessedReceipt(String id);

  Future<Either<Failure, UnprocessedReceipt>> updateUnprocessedReceipt(
      UnprocessedReceipt receipt);
}
