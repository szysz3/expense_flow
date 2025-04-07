import 'package:dartz/dartz.dart';
import 'package:domain/model/daily_expense.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/repository/receipt_repository.dart';

import 'base/base_use_case.dart';

class GetDailyExpensesParams {
  final int year;
  final int month;

  GetDailyExpensesParams({
    required this.year,
    required this.month,
  });
}

class GetDailyExpensesUseCase
    implements
        BaseUseCase<GetDailyExpensesParams,
            Either<Failure, List<DailyExpense>>> {
  final ReceiptRepository repository;

  GetDailyExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, List<DailyExpense>>> call(
      GetDailyExpensesParams params) async {
    return await repository.getDailyExpenses(params.year, params.month);
  }
}
