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
        id: '1',
        name: 'Groceries',
        iconName: Icons.shopping_basket.codePoint.toString(),
        items: [
          CategoryItem(id: '1_1', name: 'Milk', amount: 2.99),
          CategoryItem(id: '1_2', name: 'Bread', amount: 1.99),
          CategoryItem(id: '1_3', name: 'Eggs', amount: 3.99),
        ],
      ),
      Category(
        id: '2',
        name: 'Transportation',
        iconName: Icons.directions_car.codePoint.toString(),
        items: [
          CategoryItem(id: '2_1', name: 'Gas', amount: 45.00),
          CategoryItem(id: '2_2', name: 'Bus Ticket', amount: 2.50),
          CategoryItem(id: '2_3', name: 'Train Pass', amount: 75.00),
        ],
      ),
      Category(
        id: '3',
        name: 'Entertainment',
        iconName: Icons.movie.codePoint.toString(),
        items: [
          CategoryItem(id: '3_1', name: 'Netflix', amount: 15.99),
          CategoryItem(id: '3_2', name: 'Cinema', amount: 12.00),
          CategoryItem(id: '3_3', name: 'Books', amount: 24.99),
        ],
      ),
      Category(
        id: '4',
        name: 'Household',
        iconName: Icons.movie.codePoint.toString(),
        items: [
          CategoryItem(id: '3_1', name: 'Netflix', amount: 15.99),
          CategoryItem(id: '3_2', name: 'Cinema', amount: 12.00),
          CategoryItem(id: '3_3', name: 'Books', amount: 24.99),
        ],
      ),
      Category(
        id: '5',
        name: 'Personal care',
        iconName: Icons.movie.codePoint.toString(),
        items: [
          CategoryItem(id: '3_1', name: 'Netflix', amount: 15.99),
          CategoryItem(id: '3_2', name: 'Cinema', amount: 12.00),
          CategoryItem(id: '3_3', name: 'Books', amount: 24.99),
        ],
      ),
      Category(
        id: '6',
        name: 'Alcoholic beverages',
        iconName: Icons.movie.codePoint.toString(),
        items: [
          CategoryItem(id: '3_1', name: 'Netflix', amount: 15.99),
          CategoryItem(id: '3_2', name: 'Cinema', amount: 12.00),
          CategoryItem(id: '3_3', name: 'Books', amount: 24.99),
        ],
      ),
    ];
  }
}
