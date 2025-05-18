import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';

class ReceiptDeleteParams {
  final String id;

  ReceiptDeleteParams({required this.id});
}

class ReceiptDeleteUseCase
    implements BaseUseCase<ReceiptDeleteParams, Either<Failure, bool>> {
  final ReceiptRepository repository;

  ReceiptDeleteUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ReceiptDeleteParams params) async {
    return await repository.deleteReceipt(params.id);
  }
}
