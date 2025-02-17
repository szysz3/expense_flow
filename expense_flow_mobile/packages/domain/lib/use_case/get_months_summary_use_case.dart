import 'package:dartz/dartz.dart';

import '../model/failure/failures.dart';
import '../model/month_summary.dart';
import '../repository/receipt_repository.dart';
import 'base/base_use_case.dart';

class GetMonthsSummaryUseCase
    implements BaseUseCase<NoParams, Either<Failure, List<MonthSummary>>> {
  final ReceiptRepository repository;

  GetMonthsSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, List<MonthSummary>>> call(NoParams params) async {
    return await repository.getMonthsSummary();
  }
}
