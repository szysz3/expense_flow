import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

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

    // Generate colors based on the theme
    final colorScheme = Theme.of(context).colorScheme;
    final baseColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.amber,
      Colors.teal,
      Colors.purple,
      Colors.green,
      Colors.indigo,
    ];

    // Create sections for the pie chart
    for (int i = 0; i < displayMonths.length; i++) {
      final month = displayMonths[i];
      final monthTotal = _calculateMonthTotal(month);
      final percentage =
          totalExpenses > 0 ? (monthTotal / totalExpenses) * 100 : 0;
      final color = baseColors[i % baseColors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: monthTotal,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Monthly expenses distribution",
            // AppLocalizations.of(context).monthlyExpensesDistribution,
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
                          color: baseColors[i % baseColors.length],
                        ),
                        const SizedBox(width: 8),
                        Text(displayMonths[i].month),
                        const Spacer(),
                        Text(
                          '${_calculateMonthTotal(displayMonths[i]).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                // Total row
                if (displayMonths.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        const Text('Total',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(
                          '${totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
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
      child: Text(
        "No data to display",
        // AppLocalizations.of(context).noDataToDisplay,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
