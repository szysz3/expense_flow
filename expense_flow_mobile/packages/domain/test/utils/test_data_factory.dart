import 'package:domain/model/autocomplete_suggestion.dart';
import 'package:domain/model/category_item.dart';
import 'package:domain/model/category_summary.dart';
import 'package:domain/model/category_with_items.dart';
import 'package:domain/model/daily_expense.dart';
import 'package:domain/model/month_summary.dart';
import 'package:domain/model/savings_settings.dart';

class TestDataFactory {
  static List<AutocompleteSuggestion> createAutocompleteSuggestions(
      {int count = 3}) {
    return List.generate(count, (index) {
      switch (index) {
        case 0:
          return const AutocompleteSuggestion(
            description: 'Groceries',
            category: 'Food & Dining',
            score: 0.95,
          );
        case 1:
          return const AutocompleteSuggestion(
            description: 'Coffee',
            category: 'Food & Dining',
            score: 0.87,
          );
        case 2:
          return const AutocompleteSuggestion(
            description: 'Gasoline',
            category: 'Transportation',
            score: 0.82,
          );
        case 3:
          return const AutocompleteSuggestion(
            description: 'Restaurant',
            category: 'Food & Dining',
            score: 0.78,
          );
        case 4:
          return const AutocompleteSuggestion(
            description: 'Pharmacy',
            category: 'Health & Medical',
            score: 0.75,
          );
        default:
          return AutocompleteSuggestion(
            description: 'Test Item $index',
            category: 'Test Category',
            score: 0.5 + (index * 0.1),
          );
      }
    });
  }

  static AutocompleteSuggestion createSingleAutocompleteSuggestion({
    String description = 'Test Description',
    String category = 'Test Category',
    double score = 0.8,
  }) {
    return AutocompleteSuggestion(
      description: description,
      category: category,
      score: score,
    );
  }

  static List<CategorySummary> createCategorySummaries() {
    return [
      const CategorySummary(
        id: 'cat1',
        name: 'Groceries',
        iconName: 'shopping_cart',
        amount: 75.0,
        previousMonthAmount: 65.0,
      ),
      const CategorySummary(
        id: 'cat2',
        name: 'Entertainment',
        iconName: 'movie',
        amount: 25.0,
        previousMonthAmount: 30.0,
      ),
    ];
  }

  static SavingsSettings createSavingsSettings({
    int month = 1,
    int year = 2023,
    double savingsAmount = 0.0,
    double income = 1000.0,
  }) {
    return SavingsSettings(
      month: month,
      year: year,
      savingsAmount: savingsAmount,
      income: income,
    );
  }

  static Map<(int, int), SavingsSettings> createSavingsMap() {
    return {
      (1, 2023): SavingsSettings(month: 1, year: 2023, income: 3000.0),
      (2, 2023): SavingsSettings(month: 2, year: 2023, income: 3200.0),
      (3, 2023): SavingsSettings(month: 3, year: 2023, income: 3100.0),
    };
  }

  static List<MonthSummary> createMonthsForSavingsCalculation() {
    return [
      MonthSummary(
        id: 'jan2023',
        monthNumber: 1,
        year: 2023,
        previousMonthTotal: 0.0,
        categories: [
          const CategorySummary(
              id: 'cat1',
              name: 'Food',
              iconName: 'food',
              amount: 500.0,
              previousMonthAmount: 450.0),
          const CategorySummary(
              id: 'cat2',
              name: 'Transport',
              iconName: 'car',
              amount: 200.0,
              previousMonthAmount: 180.0),
        ],
      ),
      MonthSummary(
        id: 'feb2023',
        monthNumber: 2,
        year: 2023,
        previousMonthTotal: 700.0,
        categories: [
          const CategorySummary(
              id: 'cat1',
              name: 'Food',
              iconName: 'food',
              amount: 600.0,
              previousMonthAmount: 500.0),
          const CategorySummary(
              id: 'cat2',
              name: 'Transport',
              iconName: 'car',
              amount: 250.0,
              previousMonthAmount: 200.0),
        ],
      ),
      MonthSummary(
        id: 'mar2023',
        monthNumber: 3,
        year: 2023,
        previousMonthTotal: 850.0,
        categories: [
          const CategorySummary(
              id: 'cat1',
              name: 'Food',
              iconName: 'food',
              amount: 550.0,
              previousMonthAmount: 600.0),
          const CategorySummary(
              id: 'cat2',
              name: 'Transport',
              iconName: 'car',
              amount: 300.0,
              previousMonthAmount: 250.0),
        ],
      ),
    ];
  }

  static List<MonthSummary> createSingleMonthList() {
    return [
      MonthSummary(
        id: 'jan2023',
        monthNumber: 1,
        year: 2023,
        previousMonthTotal: 0.0,
        categories: createCategorySummaries(),
      ),
    ];
  }

  static Map<(int, int), SavingsSettings> createEmptySavingsMap() {
    return <(int, int), SavingsSettings>{};
  }

  static CategorySummary createSingleCategorySummary({
    String id = 'test-cat',
    String name = 'Test Category',
    String iconName = 'test_icon',
    double amount = 50.0,
    double previousMonthAmount = 40.0,
  }) {
    return CategorySummary(
      id: id,
      name: name,
      iconName: iconName,
      amount: amount,
      previousMonthAmount: previousMonthAmount,
    );
  }

  static List<MonthSummary> createMonthsSummary() {
    final categories = createCategorySummaries();
    return [
      MonthSummary(
        id: 'jan2023',
        monthNumber: 1,
        year: 2023,
        previousMonthTotal: 0.0,
        categories: categories,
      ),
      MonthSummary(
        id: 'feb2023',
        monthNumber: 2,
        year: 2023,
        previousMonthTotal: 100.0,
        categories: categories,
      ),
    ];
  }

  static MonthSummary createSingleMonthSummary({
    String id = 'test-month',
    int monthNumber = 1,
    int year = 2023,
    double previousMonthTotal = 0.0,
    List<CategorySummary>? categories,
  }) {
    return MonthSummary(
      id: id,
      monthNumber: monthNumber,
      year: year,
      previousMonthTotal: previousMonthTotal,
      categories: categories ?? createCategorySummaries(),
    );
  }

  static List<DailyExpense> createDailyExpenses() {
    return [
      DailyExpense(
        day: 1,
        total: 45.67,
        transactionDatetime: DateTime(2023, 5, 1, 14, 30),
      ),
      DailyExpense(
        day: 3,
        total: 23.45,
        transactionDatetime: DateTime(2023, 5, 3, 10, 15),
      ),
      DailyExpense(
        day: 5,
        total: 78.90,
        transactionDatetime: DateTime(2023, 5, 5, 18, 45),
      ),
      DailyExpense(
        day: 10,
        total: 156.34,
        transactionDatetime: DateTime(2023, 5, 10, 12, 0),
      ),
      DailyExpense(
        day: 15,
        total: 89.12,
        transactionDatetime: DateTime(2023, 5, 15, 16, 20),
      ),
    ];
  }

  static DailyExpense createSingleDailyExpense({
    int day = 1,
    double total = 50.0,
    DateTime? transactionDatetime,
  }) {
    return DailyExpense(
      day: day,
      total: total,
      transactionDatetime: transactionDatetime ?? DateTime(2023, 5, day, 12, 0),
    );
  }

  static List<CategoryWithItems> createCategoriesWithItems() {
    return [
      CategoryWithItems(
        id: 'cat1',
        name: 'Groceries',
        iconName: 'shopping_cart',
        items: [
          CategoryItem(id: 'item3', name: 'Bakery', amount: 12.20, count: 1),
          CategoryItem(
              id: 'item1', name: 'Supermarket', amount: 75.50, count: 3),
          CategoryItem(
              id: 'item2', name: 'Local Store', amount: 45.30, count: 2),
        ],
      ),
      CategoryWithItems(
        id: 'cat2',
        name: 'Entertainment',
        iconName: 'movie',
        items: [
          CategoryItem(id: 'item4', name: 'Cinema', amount: 35.00, count: 1),
          CategoryItem(id: 'item6', name: 'Streaming', amount: 15.99, count: 2),
          CategoryItem(id: 'item5', name: 'Concert', amount: 85.00, count: 1),
        ],
      ),
      CategoryWithItems(
        id: 'cat3',
        name: 'Transportation',
        iconName: 'car',
        items: [
          CategoryItem(
              id: 'item8', name: 'Public Transport', amount: 25.50, count: 10),
          CategoryItem(
              id: 'item7', name: 'Gas Station', amount: 60.00, count: 4),
        ],
      ),
    ];
  }

  static CategoryWithItems createSingleCategoryWithItems({
    String id = 'test-cat',
    String name = 'Test Category',
    String iconName = 'test_icon',
    List<CategoryItem>? items,
  }) {
    return CategoryWithItems(
      id: id,
      name: name,
      iconName: iconName,
      items: items ??
          [
            CategoryItem(
                id: 'test-item1', name: 'Test Item 1', amount: 50.0, count: 2),
            CategoryItem(
                id: 'test-item2', name: 'Test Item 2', amount: 30.0, count: 1),
          ],
    );
  }

  static CategoryItem createCategoryItem({
    String id = 'test-item',
    String name = 'Test Item',
    double amount = 25.0,
    int count = 1,
  }) {
    return CategoryItem(
      id: id,
      name: name,
      amount: amount,
      count: count,
    );
  }

  static List<CategoryWithItems> createCategoriesWithUnsortedItems() {
    return [
      CategoryWithItems(
        id: 'cat1',
        name: 'Food',
        iconName: 'restaurant',
        items: [
          CategoryItem(
              id: 'item1', name: 'Small Purchase', amount: 12.50, count: 1),
          CategoryItem(
              id: 'item2', name: 'Large Purchase', amount: 89.99, count: 2),
          CategoryItem(
              id: 'item3', name: 'Medium Purchase', amount: 45.75, count: 1),
        ],
      ),
    ];
  }

  static List<CategoryWithItems> createCategoriesWithSortedItems() {
    return [
      CategoryWithItems(
        id: 'cat1',
        name: 'Food',
        iconName: 'restaurant',
        items: [
          CategoryItem(
              id: 'item2', name: 'Large Purchase', amount: 89.99, count: 2),
          CategoryItem(
              id: 'item3', name: 'Medium Purchase', amount: 45.75, count: 1),
          CategoryItem(
              id: 'item1', name: 'Small Purchase', amount: 12.50, count: 1),
        ],
      ),
    ];
  }

  static List<CategoryWithItems> createCategoriesWithItemsSorted() {
    return [
      CategoryWithItems(
        id: 'cat1',
        name: 'Groceries',
        iconName: 'shopping_cart',
        items: [
          CategoryItem(
              id: 'item1', name: 'Supermarket', amount: 75.50, count: 3),
          CategoryItem(
              id: 'item2', name: 'Local Store', amount: 45.30, count: 2),
          CategoryItem(id: 'item3', name: 'Bakery', amount: 12.20, count: 1),
        ],
      ),
      CategoryWithItems(
        id: 'cat2',
        name: 'Entertainment',
        iconName: 'movie',
        items: [
          CategoryItem(id: 'item5', name: 'Concert', amount: 85.00, count: 1),
          CategoryItem(id: 'item4', name: 'Cinema', amount: 35.00, count: 1),
          CategoryItem(id: 'item6', name: 'Streaming', amount: 15.99, count: 2),
        ],
      ),
      CategoryWithItems(
        id: 'cat3',
        name: 'Transportation',
        iconName: 'car',
        items: [
          CategoryItem(
              id: 'item7', name: 'Gas Station', amount: 60.00, count: 4),
          CategoryItem(
              id: 'item8', name: 'Public Transport', amount: 25.50, count: 10),
        ],
      ),
    ];
  }
}
