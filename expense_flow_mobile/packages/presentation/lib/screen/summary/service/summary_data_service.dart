import '../model/category_summary.dart';
import '../model/month_summary.dart';

abstract class SummaryDataService {
  Future<List<MonthSummary>> getMonthsSummary();
}

class MockSummaryDataService implements SummaryDataService {
  @override
  Future<List<MonthSummary>> getMonthsSummary() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      MonthSummary(
        id: '3',
        month: 'March 2024',
        previousMonthTotal: 775.50,
        categories: [
          CategorySummary(
            id: 'groceries',
            name: 'Groceries',
            iconName: 'packages/presentation/assets/icon_groceries.svg',
            amount: 159.48,
            previousMonthAmount: 145.20,
          ),
          CategorySummary(
            id: 'alcoholic_beverages',
            name: 'Alcoholic Beverages',
            iconName:
                'packages/presentation/assets/icon_alcoholic_beverages.svg',
            amount: 87.97,
            previousMonthAmount: 95.50,
          ),
          CategorySummary(
            id: 'personal_care',
            name: 'Personal Care',
            iconName: 'packages/presentation/assets/icon_personal_care.svg',
            amount: 110.48,
            previousMonthAmount: 98.75,
          ),
          CategorySummary(
            id: 'household',
            name: 'Household',
            iconName: 'packages/presentation/assets/icon_household.svg',
            amount: 89.97,
            previousMonthAmount: 82.50,
          ),
          CategorySummary(
            id: 'clothing',
            name: 'Clothing',
            iconName: 'packages/presentation/assets/icon_clothing.svg',
            amount: 239.97,
            previousMonthAmount: 210.00,
          ),
          CategorySummary(
            id: 'entertainment',
            name: 'Entertainment',
            iconName: 'packages/presentation/assets/icon_entertainment.svg',
            amount: 85.97,
            previousMonthAmount: 75.50,
          ),
          CategorySummary(
            id: 'transportation',
            name: 'Transportation',
            iconName: 'packages/presentation/assets/icon_transportation.svg',
            amount: 250.00,
            previousMonthAmount: 235.00,
          ),
          CategorySummary(
            id: 'pet',
            name: 'Pet',
            iconName: 'packages/presentation/assets/icon_pet.svg',
            amount: 205.98,
            previousMonthAmount: 189.50,
          ),
          CategorySummary(
            id: 'other',
            name: 'Other',
            iconName: 'packages/presentation/assets/icon_other.svg',
            amount: 150.00,
            previousMonthAmount: 142.50,
          ),
        ],
      ),
      MonthSummary(
        id: '2',
        month: 'February 2024',
        previousMonthTotal: 850.50,
        categories: [
          CategorySummary(
            id: 'groceries',
            name: 'Groceries',
            iconName: 'packages/presentation/assets/icon_groceries.svg',
            amount: 145.20,
            previousMonthAmount: 159.48,
          ),
          CategorySummary(
            id: 'alcoholic_beverages',
            name: 'Alcoholic Beverages',
            iconName:
                'packages/presentation/assets/icon_alcoholic_beverages.svg',
            amount: 95.50,
            previousMonthAmount: 87.97,
          ),
          CategorySummary(
            id: 'personal_care',
            name: 'Personal Care',
            iconName: 'packages/presentation/assets/icon_personal_care.svg',
            amount: 98.75,
            previousMonthAmount: 110.48,
          ),
          CategorySummary(
            id: 'household',
            name: 'Household',
            iconName: 'packages/presentation/assets/icon_household.svg',
            amount: 82.50,
            previousMonthAmount: 89.97,
          ),
          CategorySummary(
            id: 'clothing',
            name: 'Clothing',
            iconName: 'packages/presentation/assets/icon_clothing.svg',
            amount: 210.00,
            previousMonthAmount: 239.97,
          ),
          CategorySummary(
            id: 'entertainment',
            name: 'Entertainment',
            iconName: 'packages/presentation/assets/icon_entertainment.svg',
            amount: 75.50,
            previousMonthAmount: 85.97,
          ),
          CategorySummary(
            id: 'transportation',
            name: 'Transportation',
            iconName: 'packages/presentation/assets/icon_transportation.svg',
            amount: 235.00,
            previousMonthAmount: 250.00,
          ),
          CategorySummary(
            id: 'pet',
            name: 'Pet',
            iconName: 'packages/presentation/assets/icon_pet.svg',
            amount: 189.50,
            previousMonthAmount: 205.98,
          ),
          CategorySummary(
            id: 'other',
            name: 'Other',
            iconName: 'packages/presentation/assets/icon_other.svg',
            amount: 142.50,
            previousMonthAmount: 150.00,
          ),
        ],
      ),
      MonthSummary(
        id: '1',
        month: 'January 2024',
        previousMonthTotal: 820.00,
        categories: [
          CategorySummary(
            id: 'groceries',
            name: 'Groceries',
            iconName: 'packages/presentation/assets/icon_groceries.svg',
            amount: 159.48,
            previousMonthAmount: 145.20,
          ),
          CategorySummary(
            id: 'alcoholic_beverages',
            name: 'Alcoholic Beverages',
            iconName:
                'packages/presentation/assets/icon_alcoholic_beverages.svg',
            amount: 87.97,
            previousMonthAmount: 95.50,
          ),
          CategorySummary(
            id: 'personal_care',
            name: 'Personal Care',
            iconName: 'packages/presentation/assets/icon_personal_care.svg',
            amount: 110.48,
            previousMonthAmount: 98.75,
          ),
          CategorySummary(
            id: 'household',
            name: 'Household',
            iconName: 'packages/presentation/assets/icon_household.svg',
            amount: 89.97,
            previousMonthAmount: 82.50,
          ),
          CategorySummary(
            id: 'clothing',
            name: 'Clothing',
            iconName: 'packages/presentation/assets/icon_clothing.svg',
            amount: 239.97,
            previousMonthAmount: 210.00,
          ),
          CategorySummary(
            id: 'entertainment',
            name: 'Entertainment',
            iconName: 'packages/presentation/assets/icon_entertainment.svg',
            amount: 85.97,
            previousMonthAmount: 75.50,
          ),
          CategorySummary(
            id: 'transportation',
            name: 'Transportation',
            iconName: 'packages/presentation/assets/icon_transportation.svg',
            amount: 250.00,
            previousMonthAmount: 235.00,
          ),
          CategorySummary(
            id: 'pet',
            name: 'Pet',
            iconName: 'packages/presentation/assets/icon_pet.svg',
            amount: 205.98,
            previousMonthAmount: 189.50,
          ),
          CategorySummary(
            id: 'other',
            name: 'Other',
            iconName: 'packages/presentation/assets/icon_other.svg',
            amount: 150.00,
            previousMonthAmount: 142.50,
          ),
        ],
      ),
    ];
  }
}
