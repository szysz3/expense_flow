import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';

import '../../model/receipt_get_response.dart';

class ReceiptGetParams {
  final int page;
  final int pageSize;

  ReceiptGetParams({
    required this.page,
    required this.pageSize,
  });
}

class ReceiptGetUseCase
    implements
        BaseUseCase<ReceiptGetParams, Either<Failure, ReceiptGetResponse>> {
  final ReceiptRepository repository;

  ReceiptGetUseCase(this.repository);

  @override
  Future<Either<Failure, ReceiptGetResponse>> call(
      ReceiptGetParams params) async {
    return await repository.getReceipts(params.page, params.pageSize);
  }
}
