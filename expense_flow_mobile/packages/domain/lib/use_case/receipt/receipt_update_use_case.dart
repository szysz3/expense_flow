import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';

class ReceiptUpdateUseCase
    implements BaseUseCase<Receipt, Either<Failure, Receipt>> {
  final ReceiptRepository repository;

  ReceiptUpdateUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(Receipt params) async {
    return await repository.updateReceipt(params);
  }
}
