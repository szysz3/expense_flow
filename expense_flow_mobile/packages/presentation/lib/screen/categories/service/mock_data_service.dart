import 'package:flutter/material.dart';
import 'package:presentation/screen/categories/models/category.dart';
import 'package:presentation/screen/categories/models/category_item.dart';

abstract class CategoriesDataService {
  Future<List<Category>> getCategories();
}

class MockCategoriesDataService implements CategoriesDataService {
  @override
  Future<List<Category>> getCategories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      Category(
        id: 'groceries',
        name: 'Groceries',
        iconName: 'packages/presentation/assets/icon_groceries.svg',
        items: [
          CategoryItem(id: 'groceries_1', name: 'Fruits & Vegetables', amount: 45.99),
          CategoryItem(id: 'groceries_2', name: 'Meat & Fish', amount: 89.99),
          CategoryItem(id: 'groceries_3', name: 'Dairy & Eggs', amount: 23.50),
        ],
      ),
      Category(
        id: 'alcoholic_beverages',
        name: 'Alcoholic Beverages',
        iconName: 'packages/presentation/assets/icon_alcoholic_beverages.svg',
        items: [
          CategoryItem(id: 'alcohol_1', name: 'Wine', amount: 25.99),
          CategoryItem(id: 'alcohol_2', name: 'Beer', amount: 15.99),
          CategoryItem(id: 'alcohol_3', name: 'Spirits', amount: 45.99),
        ],
      ),
      Category(
        id: 'personal_care',
        name: 'Personal Care',
        iconName: 'packages/presentation/assets/icon_personal_care.svg',
        items: [
          CategoryItem(id: 'care_1', name: 'Hygiene Products', amount: 35.50),
          CategoryItem(id: 'care_2', name: 'Cosmetics', amount: 45.99),
          CategoryItem(id: 'care_3', name: 'Hair Care', amount: 28.99),
        ],
      ),
      Category(
        id: 'household',
        name: 'Household',
        iconName: 'packages/presentation/assets/icon_household.svg',
        items: [
          CategoryItem(id: 'house_1', name: 'Cleaning Supplies', amount: 29.99),
          CategoryItem(id: 'house_2', name: 'Laundry', amount: 19.99),
          CategoryItem(id: 'house_3', name: 'Kitchen Items', amount: 39.99),
        ],
      ),
      Category(
        id: 'clothing',
        name: 'Clothing',
        iconName: 'packages/presentation/assets/icon_clothing.svg',
        items: [
          CategoryItem(id: 'clothing_1', name: 'Shirts', amount: 59.99),
          CategoryItem(id: 'clothing_2', name: 'Pants', amount: 79.99),
          CategoryItem(id: 'clothing_3', name: 'Shoes', amount: 99.99),
        ],
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        iconName: 'packages/presentation/assets/icon_entertainment.svg',
        items: [
          CategoryItem(id: 'ent_1', name: 'Movies', amount: 15.99),
          CategoryItem(id: 'ent_2', name: 'Games', amount: 59.99),
          CategoryItem(id: 'ent_3', name: 'Music', amount: 9.99),
        ],
      ),
      Category(
        id: 'transportation',
        name: 'Transportation',
        iconName: 'packages/presentation/assets/icon_transportation.svg',
        items: [
          CategoryItem(id: 'transport_1', name: 'Gas', amount: 55.00),
          CategoryItem(id: 'transport_2', name: 'Public Transit', amount: 45.00),
          CategoryItem(id: 'transport_3', name: 'Car Maintenance', amount: 150.00),
        ],
      ),
      Category(
        id: 'pet',
        name: 'Pet',
        iconName: 'packages/presentation/assets/icon_pet.svg',
        items: [
          CategoryItem(id: 'pet_1', name: 'Pet Food', amount: 49.99),
          CategoryItem(id: 'pet_2', name: 'Vet Care', amount: 120.00),
          CategoryItem(id: 'pet_3', name: 'Supplies', amount: 35.99),
        ],
      ),
      Category(
        id: 'other',
        name: 'Other',
        iconName: 'packages/presentation/assets/icon_other.svg',
        items: [
          CategoryItem(id: 'other_1', name: 'Gifts', amount: 75.00),
          CategoryItem(id: 'other_2', name: 'Donations', amount: 50.00),
          CategoryItem(id: 'other_3', name: 'Miscellaneous', amount: 25.00),
        ],
      ),
    ];
  }
}