import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';

class DeleteReceiptParams {
  final String id;

  DeleteReceiptParams({required this.id});
}

class DeleteReceiptUseCase
    implements BaseUseCase<DeleteReceiptParams, Either<Failure, bool>> {
  final ReceiptRepository repository;

  DeleteReceiptUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteReceiptParams params) async {
    return await repository.deleteReceipt(params.id);
  }
}
