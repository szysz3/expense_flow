import 'package:dartz/dartz.dart';

import '../model/failure/failures.dart';
import '../model/receipt.dart';
import '../repository/receipt_repository.dart';
import 'base/base_use_case.dart';

class AnalyzeReceiptParams {
  final String filePath;
  final String llmType;

  AnalyzeReceiptParams({
    required this.filePath,
    this.llmType = 'local',
  });
}

class AnalyzeReceiptUseCase
    implements BaseUseCase<AnalyzeReceiptParams, Either<Failure, Receipt>> {
  final ReceiptRepository repository;

  AnalyzeReceiptUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(AnalyzeReceiptParams params) async {
    return await repository.analyzeReceipt(
      params.filePath,
      llmType: params.llmType,
    );
  }
}
