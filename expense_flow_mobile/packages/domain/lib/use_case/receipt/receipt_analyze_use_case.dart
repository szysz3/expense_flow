import 'package:dartz/dartz.dart';

import '../../model/failure/failures.dart';
import '../../model/receipt.dart';
import '../../repository/receipt_repository.dart';
import '../base/base_use_case.dart';

class ReceiptAnalyzeParams {
  final String filePath;
  final String llmType;

  ReceiptAnalyzeParams({
    required this.filePath,
    this.llmType = 'local',
  });
}

class ReceiptAnalyzeUseCase
    implements BaseUseCase<ReceiptAnalyzeParams, Either<Failure, Receipt>> {
  final ReceiptRepository repository;

  ReceiptAnalyzeUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(ReceiptAnalyzeParams params) async {
    return await repository.analyzeReceipt(
      params.filePath,
      llmType: params.llmType,
    );
  }
}
