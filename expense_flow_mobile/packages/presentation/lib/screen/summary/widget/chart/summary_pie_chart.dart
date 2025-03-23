import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../../../../theme/expense_flow_colors.dart';
import '../../model/month_summary.dart';

class SummaryPieChart extends StatelessWidget {
  final List<MonthSummary> months;

  const SummaryPieChart({super.key, required this.months});

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return _buildEmptyChart(context);
    }

    final displayMonths = months.take(12).toList();
    final sections = <PieChartSectionData>[];
    final totalExpenses = displayMonths.fold<double>(
        0, (sum, month) => sum + _calculateMonthTotal(month));

    final chartColors = ExpenseFlowColors.chartColorsList;

    for (int i = 0; i < displayMonths.length; i++) {
      final month = displayMonths[i];
      final monthTotal = _calculateMonthTotal(month);
      final percentage =
          totalExpenses > 0 ? (monthTotal / totalExpenses) * 100 : 0;
      final color = chartColors[i % chartColors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: monthTotal,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ExpenseFlowColors.darkOnPrimary,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            AppLocalizations.of(context).monthlySummaryChartTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16.0),
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              startDegreeOffset: 270,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (int i = 0; i < displayMonths.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          color: chartColors[i % chartColors.length],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayMonths[i].month,
                          style: const TextStyle(
                              color: Colors
                                  .white), // Ensure text is visible on dark theme
                        ),
                        const Spacer(),
                        Text(
                          '${_calculateMonthTotal(displayMonths[i]).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Total row
                if (displayMonths.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: ExpenseFlowColors.darkSurface,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Row(
                        children: [
                          Text(
                            AppLocalizations.of(context).totalChartData,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${totalExpenses.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ExpenseFlowColors.darkPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _calculateMonthTotal(MonthSummary month) {
    return month.categories
        .fold<double>(0, (sum, category) => sum + category.amount);
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: ExpenseFlowColors.darkSurface,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          AppLocalizations.of(context).noDataChartTitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ExpenseFlowColors.darkPrimary,
              ),
        ),
      ),
    );
  }
}
