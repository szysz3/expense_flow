import 'package:dartz/dartz.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/model/month_summary.dart';
import 'package:domain/model/savings_settings.dart';
import 'package:domain/use_case/base/base_use_case.dart';

class CalculateTotalSavingsParams {
  final List<MonthSummary> months;
  final Map<(int, int), SavingsSettings> savingsMap;

  const CalculateTotalSavingsParams({
    required this.months,
    required this.savingsMap,
  });
}

class CalculateTotalSavingsUseCase
    implements
        BaseUseCase<CalculateTotalSavingsParams, Either<Failure, double>> {
  const CalculateTotalSavingsUseCase();

  @override
  Future<Either<Failure, double>> call(
      CalculateTotalSavingsParams params) async {
    try {
      final months = params.months;
      final savingsMap = params.savingsMap;

      if (months.length <= 1) {
        return const Right(0.0);
      }

      double totalSavings = 0.0;
      // Start from the second month (index 1)
      // We skip the first month because this is a current month
      // so we don't know savings amount for it
      for (int i = 1; i < months.length; i++) {
        final month = months[i];
        final monthNumber = month.monthNumber;
        final year = month.year;
        final key = (monthNumber, year);

        double income = 0.0;
        if (savingsMap.containsKey(key)) {
          income = savingsMap[key]!.income;
        }

        final totalExpenses = month.categories.fold<double>(
          0.0,
          (sum, category) => sum + category.amount,
        );

        final monthlySavings = income - totalExpenses;
        totalSavings += monthlySavings;
      }

      return Right(totalSavings);
    } catch (e) {
      return Left(
          ServerFailure('Failed to calculate total savings: ${e.toString()}'));
    }
  }
}
