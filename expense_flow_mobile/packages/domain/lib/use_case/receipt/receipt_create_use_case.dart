import 'package:dartz/dartz.dart';
import 'package:domain/model/receipt_item.dart';

import '../../model/failure/failures.dart';
import '../../model/receipt.dart';
import '../../repository/receipt_repository.dart';
import '../base/base_use_case.dart';

class ReceiptCreateUseCase
    implements BaseUseCase<ReceiptItem, Either<Failure, Receipt>> {
  final ReceiptRepository repository;

  ReceiptCreateUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(ReceiptItem params) async {
    return await repository.createReceipt(receiptItem: params);
  }
}
