import 'package:presentation/screen/summary/model/category_summary.dart';
import 'package:presentation/screen/summary/model/month_summary.dart';

abstract class SummaryDataService {
  Future<List<MonthSummary>> getMonthsSummary();
}

class MockSummaryDataService implements SummaryDataService {
  @override
  Future<List<MonthSummary>> getMonthsSummary() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      MonthSummary(
        id: '1',
        month: 'January 2024',
        previousMonthTotal: 850.00,
        categories: [
          CategorySummary(id: '1', name: 'Groceries', amount: 320.50),
          CategorySummary(id: '2', name: 'Transportation', amount: 150.00),
          CategorySummary(id: '3', name: 'Entertainment', amount: 200.00),
          CategorySummary(id: '4', name: 'Utilities', amount: 180.00),
        ],
      ),
      MonthSummary(
        id: '2',
        month: 'February 2024',
        previousMonthTotal: 850.50,
        categories: [
          CategorySummary(id: '1', name: 'Groceries', amount: 290.50),
          CategorySummary(id: '2', name: 'Transportation', amount: 120.00),
          CategorySummary(id: '3', name: 'Entertainment', amount: 180.00),
          CategorySummary(id: '4', name: 'Utilities', amount: 185.00),
        ],
      ),
      MonthSummary(
        id: '3',
        month: 'March 2024',
        previousMonthTotal: 775.50,
        categories: [
          CategorySummary(id: '1', name: 'Groceries', amount: 350.50),
          CategorySummary(id: '2', name: 'Transportation', amount: 180.00),
          CategorySummary(id: '3', name: 'Entertainment', amount: 220.00),
          CategorySummary(id: '4', name: 'Utilities', amount: 190.00),
        ],
      ),
    ];
  }
}
