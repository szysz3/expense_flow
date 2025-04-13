import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/repository/receipt_repository.dart';
import 'package:domain/use_case/base/base_use_case.dart';

class GetReceiptsParams {
  final int page;
  final int pageSize;

  GetReceiptsParams({
    required this.page,
    required this.pageSize,
  });
}

class ReceiptsResponse {
  final List<Receipt> receipts;
  final int totalCount;

  ReceiptsResponse({
    required this.receipts,
    required this.totalCount,
  });
}

class GetReceiptsUseCase
    implements
        BaseUseCase<GetReceiptsParams, Either<Failure, ReceiptsResponse>> {
  final ReceiptRepository repository;

  GetReceiptsUseCase(this.repository);

  @override
  Future<Either<Failure, ReceiptsResponse>> call(
      GetReceiptsParams params) async {
    return await repository.getReceipts(params.page, params.pageSize);
  }
}
