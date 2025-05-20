import 'package:domain/model/category_summary.dart' as domain;
import 'package:domain/model/month_summary.dart' as domain;
import 'package:intl/intl.dart';

import '../model/category_summary.dart' as presentation;
import '../model/month_summary.dart' as presentation;

class MonthSummaryMapper {
  static String getMonthName(int monthNumber) {
    if (monthNumber < 1 || monthNumber > 12) return 'Unknown';
    final dateTime = DateTime(DateTime.now().year, monthNumber);
    return DateFormat('MMMM').format(dateTime);
  }

  static presentation.MonthSummary mapDomainToPresentation(
      domain.MonthSummary domainMonth,
      {double income = 0.0,
      double expectedSavingsAmount = 0.0}) {
    return presentation.MonthSummary(
      id: domainMonth.id,
      monthNumber: domainMonth.monthNumber,
      monthName: getMonthName(domainMonth.monthNumber),
      year: domainMonth.year,
      previousMonthAmount: domainMonth.previousMonthTotal,
      categories: domainMonth.categories
          .map<presentation.CategorySummary>(
              (domain.CategorySummary category) => presentation.CategorySummary(
                    id: category.id,
                    name: category.name,
                    iconName: category.iconName,
                    amount: category.amount,
                    previousMonthAmount: category.previousMonthAmount,
                  ))
          .toList(),
      income: income,
      expectedSavingsAmount: expectedSavingsAmount,
    );
  }
}
