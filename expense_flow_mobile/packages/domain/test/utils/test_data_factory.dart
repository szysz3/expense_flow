import 'package:domain/model/autocomplete_suggestion.dart';
import 'package:domain/model/category_item.dart';
import 'package:domain/model/category_summary.dart';
import 'package:domain/model/category_with_items.dart';
import 'package:domain/model/chat_message.dart';
import 'package:domain/model/daily_expense.dart';
import 'package:domain/model/merchant.dart';
import 'package:domain/model/month_summary.dart';
import 'package:domain/model/receipt.dart';
import 'package:domain/model/receipt_get_response.dart';
import 'package:domain/model/receipt_item.dart';
import 'package:domain/model/savings_settings.dart';
import 'package:domain/model/settings.dart';

class TestDataFactory {
  static const _defaultYear = 2023;
  static const _defaultMonth = 1;
  static const _defaultIncome = 3000.0;
  static const _defaultSavingsAmount = 500.0;
  static const _defaultAmount = 50.0;
  static const _defaultScore = 0.8;

  static const _predefinedSuggestions = [
    AutocompleteSuggestion(
        description: 'Groceries', category: 'Food & Dining', score: 0.95),
    AutocompleteSuggestion(
        description: 'Coffee', category: 'Food & Dining', score: 0.87),
    AutocompleteSuggestion(
        description: 'Gasoline', category: 'Transportation', score: 0.82),
    AutocompleteSuggestion(
        description: 'Restaurant', category: 'Food & Dining', score: 0.78),
    AutocompleteSuggestion(
        description: 'Pharmacy', category: 'Health & Medical', score: 0.75),
  ];

  static const _predefinedCategories = [
    CategorySummary(
        id: 'cat1',
        name: 'Groceries',
        iconName: 'shopping_cart',
        amount: 75.0,
        previousMonthAmount: 65.0),
    CategorySummary(
        id: 'cat2',
        name: 'Entertainment',
        iconName: 'movie',
        amount: 25.0,
        previousMonthAmount: 30.0),
  ];

  // Receipt-related factory methods
  static Merchant createMerchant({
    String name = 'Test Store',
    String address = '123 Test Street',
  }) =>
      Merchant(
        name: name,
        address: address,
      );

  static ReceiptItem createReceiptItem({
    String description = 'Test Item',
    double quantity = 1.0,
    double totalPrice = 25.50,
    String? category = 'Test Category',
  }) =>
      ReceiptItem(
        description: description,
        quantity: quantity,
        totalPrice: totalPrice,
        category: category,
      );

  static List<ReceiptItem> createReceiptItems({int count = 3}) => [
        createReceiptItem(
          description: 'Bread',
          quantity: 2.0,
          totalPrice: 7.00,
          category: 'Food & Dining',
        ),
        createReceiptItem(
          description: 'Milk',
          quantity: 1.0,
          totalPrice: 4.25,
          category: 'Food & Dining',
        ),
        createReceiptItem(
          description: 'Coffee',
          quantity: 1.0,
          totalPrice: 12.99,
          category: 'Food & Dining',
        ),
      ].take(count).toList();

  static Receipt createReceipt({
    String? id = 'test-receipt-id',
    Merchant? merchant,
    List<ReceiptItem>? items,
    double? total,
    DateTime? transactionDateTime,
    DateTime? addedDateTime,
  }) =>
      Receipt(
        id: id,
        merchant: merchant ?? createMerchant(),
        items: items ?? createReceiptItems(),
        total: total ?? 24.24,
        transactionDateTime:
            transactionDateTime ?? DateTime(2023, 12, 15, 14, 30),
        addedDateTime: addedDateTime ?? DateTime(2023, 12, 15, 15, 0),
      );

  static List<Receipt> createReceiptsList({int count = 3}) => List.generate(
        count,
        (index) => createReceipt(
          id: 'receipt-${index + 1}',
          total: 20.0 + (index * 10),
          transactionDateTime: DateTime(2023, 12, 15 + index, 14, 30),
        ),
      );

  static ReceiptGetResponse createReceiptGetResponse({
    List<Receipt>? receipts,
    int? totalCount,
  }) =>
      ReceiptGetResponse(
        receipts: receipts ?? createReceiptsList(),
        totalCount: totalCount ?? 50,
      );

  // Chat-related factory methods
  static ChatMessage createChatMessage({
    String id = 'test-message-id',
    String content = 'Test message content',
    String sender = 'user',
    DateTime? timestamp,
  }) =>
      ChatMessage(
        id: id,
        content: content,
        sender: sender,
        timestamp: timestamp ?? DateTime(2023, 12, 15, 10, 30),
      );

  static List<ChatMessage> createChatMessages({int count = 3}) => List.generate(
        count,
        (index) => createChatMessage(
          id: 'message-${index + 1}',
          content: 'Test message ${index + 1}',
          sender: index % 2 == 0 ? 'user' : 'assistant',
          timestamp: DateTime(2023, 12, 15, 10, 30 + index),
        ),
      );

  // Existing methods from original TestDataFactory
  static List<T> createList<T>(T Function(int index) builder, {int count = 3}) {
    return List.generate(count, builder);
  }

  static List<T> createPredefinedList<T>(List<T> predefined, {int? count}) {
    if (count == null || count <= predefined.length) {
      return predefined.take(count ?? predefined.length).toList();
    }

    final result = List<T>.from(predefined);
    for (int i = predefined.length; i < count; i++) {
      if (T == AutocompleteSuggestion) {
        result.add(AutocompleteSuggestion(
          description: 'Test Item $i',
          category: 'Test Category',
          score: 0.5 + (i * 0.1),
        ) as T);
      }
    }
    return result;
  }

  static List<AutocompleteSuggestion> createAutocompleteSuggestions(
          {int count = 3}) =>
      createPredefinedList(_predefinedSuggestions, count: count);

  static AutocompleteSuggestion createSingleAutocompleteSuggestion({
    String description = 'Test Description',
    String category = 'Test Category',
    double score = _defaultScore,
  }) =>
      AutocompleteSuggestion(
          description: description, category: category, score: score);

  static List<CategorySummary> createCategorySummaries() =>
      List.from(_predefinedCategories);

  static CategorySummary createSingleCategorySummary({
    String id = 'test-cat',
    String name = 'Test Category',
    String iconName = 'test_icon',
    double amount = _defaultAmount,
    double previousMonthAmount = 40.0,
  }) =>
      CategorySummary(
        id: id,
        name: name,
        iconName: iconName,
        amount: amount,
        previousMonthAmount: previousMonthAmount,
      );

  static SavingsSettings createSavingsSettings({
    int month = _defaultMonth,
    int year = _defaultYear,
    int? endMonth,
    int? endYear,
    double savingsAmount = _defaultSavingsAmount,
    double income = _defaultIncome,
    bool openEnded = false,
  }) =>
      SavingsSettings(
        startMonth: month,
        startYear: year,
        endMonth: openEnded ? null : (endMonth ?? month),
        endYear: openEnded ? null : (endYear ?? year),
        savingsAmount: savingsAmount,
        income: income,
      );

  static Map<(int, int), SavingsSettings> createSavingsMap() => {
        (1, _defaultYear): createSavingsSettings(month: 1, income: 3000.0),
        (2, _defaultYear): createSavingsSettings(month: 2, income: 3200.0),
        (3, _defaultYear): createSavingsSettings(month: 3, income: 3100.0),
      };

  static Map<(int, int), SavingsSettings> createEmptySavingsMap() => {};

  static List<SavingsSettings> createSavingsSettingsList() => [
        createSavingsSettings(month: 1, income: 3000.0, savingsAmount: 500.0),
        createSavingsSettings(month: 2, income: 3200.0, savingsAmount: 600.0),
        createSavingsSettings(month: 3, income: 3100.0, savingsAmount: 550.0),
      ];

  static MonthSummary createSingleMonthSummary({
    String id = 'test-month',
    int monthNumber = _defaultMonth,
    int year = _defaultYear,
    double previousMonthTotal = 0.0,
    List<CategorySummary>? categories,
  }) =>
      MonthSummary(
        id: id,
        monthNumber: monthNumber,
        year: year,
        previousMonthTotal: previousMonthTotal,
        categories: categories ?? createCategorySummaries(),
      );

  static List<MonthSummary> createMonthsSummary() => [
        createSingleMonthSummary(
            id: 'jan2023', monthNumber: 1, year: _defaultYear),
        createSingleMonthSummary(
            id: 'feb2023',
            monthNumber: 2,
            year: _defaultYear,
            previousMonthTotal: 100.0),
      ];

  static List<MonthSummary> createSingleMonthList() => [
        createSingleMonthSummary(
            id: 'jan2023', monthNumber: 1, year: _defaultYear),
      ];

  static List<MonthSummary> createMonthsForSavingsCalculation() {
    const baseExpenses = [
      CategorySummary(
          id: 'cat1',
          name: 'Food',
          iconName: 'food',
          amount: 500.0,
          previousMonthAmount: 450.0),
      CategorySummary(
          id: 'cat2',
          name: 'Transport',
          iconName: 'car',
          amount: 200.0,
          previousMonthAmount: 180.0),
    ];

    return [
      MonthSummary(
          id: 'jan2023',
          monthNumber: 1,
          year: _defaultYear,
          previousMonthTotal: 0.0,
          categories: baseExpenses),
      MonthSummary(
          id: 'feb2023',
          monthNumber: 2,
          year: _defaultYear,
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
          ]),
      MonthSummary(
          id: 'mar2023',
          monthNumber: 3,
          year: _defaultYear,
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
          ]),
    ];
  }

  static Settings createSettings({List<SavingsSettings>? savingsSettings}) =>
      Settings(
        version: settingsCurrentVersion,
        savingsSettings: savingsSettings ??
            [
              createSavingsSettings(
                  month: 1, income: 3000.0, savingsAmount: 500.0),
              createSavingsSettings(
                  month: 2, income: 3200.0, savingsAmount: 600.0),
            ],
      );

  static Settings createEmptySettings() =>
      const Settings(version: settingsCurrentVersion, savingsSettings: []);

  static Settings createSettingsWithNullSavings() =>
      const Settings(version: settingsCurrentVersion, savingsSettings: null);

  static DailyExpense createSingleDailyExpense({
    int day = 1,
    double total = _defaultAmount,
    DateTime? transactionDatetime,
  }) =>
      DailyExpense(
        day: day,
        total: total,
        transactionDatetime:
            transactionDatetime ?? DateTime(_defaultYear, 5, day, 12, 0),
      );

  static List<DailyExpense> createDailyExpenses() => [
        createSingleDailyExpense(
            day: 1,
            total: 45.67,
            transactionDatetime: DateTime(2023, 5, 1, 14, 30)),
        createSingleDailyExpense(
            day: 3,
            total: 23.45,
            transactionDatetime: DateTime(2023, 5, 3, 10, 15)),
        createSingleDailyExpense(
            day: 5,
            total: 78.90,
            transactionDatetime: DateTime(2023, 5, 5, 18, 45)),
        createSingleDailyExpense(
            day: 10,
            total: 156.34,
            transactionDatetime: DateTime(2023, 5, 10, 12, 0)),
        createSingleDailyExpense(
            day: 15,
            total: 89.12,
            transactionDatetime: DateTime(2023, 5, 15, 16, 20)),
      ];

  static CategoryItem createCategoryItem({
    String id = 'test-item',
    String name = 'Test Item',
    double amount = 25.0,
    int count = 1,
  }) =>
      CategoryItem(id: id, name: name, amount: amount, count: count);

  static CategoryWithItems createSingleCategoryWithItems({
    String id = 'test-cat',
    String name = 'Test Category',
    String iconName = 'test_icon',
    List<CategoryItem>? items,
  }) =>
      CategoryWithItems(
        id: id,
        name: name,
        iconName: iconName,
        items: items ??
            [
              createCategoryItem(
                  id: 'test-item1',
                  name: 'Test Item 1',
                  amount: 50.0,
                  count: 2),
              createCategoryItem(
                  id: 'test-item2',
                  name: 'Test Item 2',
                  amount: 30.0,
                  count: 1),
            ],
      );

  static List<CategoryWithItems> createCategoriesWithItems() => [
        CategoryWithItems(
          id: 'cat1',
          name: 'Groceries',
          iconName: 'shopping_cart',
          items: [
            createCategoryItem(
                id: 'item3', name: 'Bakery', amount: 12.20, count: 1),
            createCategoryItem(
                id: 'item1', name: 'Supermarket', amount: 75.50, count: 3),
            createCategoryItem(
                id: 'item2', name: 'Local Store', amount: 45.30, count: 2),
          ],
        ),
        CategoryWithItems(
          id: 'cat2',
          name: 'Entertainment',
          iconName: 'movie',
          items: [
            createCategoryItem(
                id: 'item4', name: 'Cinema', amount: 35.00, count: 1),
            createCategoryItem(
                id: 'item6', name: 'Streaming', amount: 15.99, count: 2),
            createCategoryItem(
                id: 'item5', name: 'Concert', amount: 85.00, count: 1),
          ],
        ),
        CategoryWithItems(
          id: 'cat3',
          name: 'Transportation',
          iconName: 'car',
          items: [
            createCategoryItem(
                id: 'item8',
                name: 'Public Transport',
                amount: 25.50,
                count: 10),
            createCategoryItem(
                id: 'item7', name: 'Gas Station', amount: 60.00, count: 4),
          ],
        ),
      ];

  static List<CategoryWithItems> _sortCategoriesByAmount(
      List<CategoryWithItems> categories) {
    return categories.map((category) {
      final sortedItems = List<CategoryItem>.from(category.items)
        ..sort((a, b) => b.amount.compareTo(a.amount));
      return CategoryWithItems(
        id: category.id,
        name: category.name,
        iconName: category.iconName,
        items: sortedItems,
      );
    }).toList();
  }

  static List<CategoryWithItems> createCategoriesWithItemsSorted() =>
      _sortCategoriesByAmount(createCategoriesWithItems());

  static List<CategoryWithItems> createCategoriesWithUnsortedItems() => [
        CategoryWithItems(
          id: 'cat1',
          name: 'Food',
          iconName: 'restaurant',
          items: [
            createCategoryItem(
                id: 'item1', name: 'Small Purchase', amount: 12.50, count: 1),
            createCategoryItem(
                id: 'item2', name: 'Large Purchase', amount: 89.99, count: 2),
            createCategoryItem(
                id: 'item3', name: 'Medium Purchase', amount: 45.75, count: 1),
          ],
        ),
      ];

  static List<CategoryWithItems> createCategoriesWithSortedItems() =>
      _sortCategoriesByAmount(createCategoriesWithUnsortedItems());
}
