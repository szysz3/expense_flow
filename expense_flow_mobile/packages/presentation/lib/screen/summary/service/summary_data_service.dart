import 'package:flutter/material.dart';

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
            id: '1',
            name: 'Groceries',
            iconName: Icons.shopping_basket.codePoint.toString(),
            amount: 350.50,
            previousMonthAmount: 290.50, // Feb amount
          ),
          CategorySummary(
            id: '2',
            name: 'Transportation',
            iconName: Icons.directions_car.codePoint.toString(),
            amount: 180.00,
            previousMonthAmount: 120.00,
          ),
          CategorySummary(
            id: '3',
            name: 'Entertainment',
            iconName: Icons.movie.codePoint.toString(),
            amount: 220.00,
            previousMonthAmount: 180.00,
          ),
          CategorySummary(
            id: '4',
            name: 'Utilities',
            iconName: Icons.lightbulb.codePoint.toString(),
            amount: 190.00,
            previousMonthAmount: 185.00,
          ),
        ],
      ),
      MonthSummary(
        id: '2',
        month: 'February 2024',
        previousMonthTotal: 850.50,
        categories: [
          CategorySummary(
            id: '1',
            name: 'Groceries',
            iconName: Icons.shopping_basket.codePoint.toString(),
            amount: 290.50,
            previousMonthAmount: 320.50, // Jan amount
          ),
          CategorySummary(
            id: '2',
            name: 'Transportation',
            iconName: Icons.directions_car.codePoint.toString(),
            amount: 120.00,
            previousMonthAmount: 150.00,
          ),
          CategorySummary(
            id: '3',
            name: 'Entertainment',
            iconName: Icons.movie.codePoint.toString(),
            amount: 180.00,
            previousMonthAmount: 200.00,
          ),
          CategorySummary(
            id: '4',
            name: 'Utilities',
            iconName: Icons.lightbulb.codePoint.toString(),
            amount: 185.00,
            previousMonthAmount: 180.00,
          ),
        ],
      ),
      MonthSummary(
        id: '1',
        month: 'January 2024',
        previousMonthTotal: 820.00, // December 2023
        categories: [
          CategorySummary(
            id: '1',
            name: 'Groceries',
            iconName: Icons.shopping_basket.codePoint.toString(),
            amount: 320.50,
            previousMonthAmount: 300.00, // Dec amount
          ),
          CategorySummary(
            id: '2',
            name: 'Transportation',
            iconName: Icons.directions_car.codePoint.toString(),
            amount: 150.00,
            previousMonthAmount: 145.00,
          ),
          CategorySummary(
            id: '3',
            name: 'Entertainment',
            iconName: Icons.movie.codePoint.toString(),
            amount: 200.00,
            previousMonthAmount: 195.00,
          ),
          CategorySummary(
            id: '4',
            name: 'Utilities',
            iconName: Icons.lightbulb.codePoint.toString(),
            amount: 180.00,
            previousMonthAmount: 180.00,
          ),
        ],
      ),
    ];
  }
}