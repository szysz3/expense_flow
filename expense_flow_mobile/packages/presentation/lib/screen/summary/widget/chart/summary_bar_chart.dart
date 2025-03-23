import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../../model/month_summary.dart';

class SummaryBarChart extends StatelessWidget {
  final List<MonthSummary> months;

  const SummaryBarChart({super.key, required this.months});

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return _buildEmptyChart(context);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final displayMonths = months.take(12).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            AppLocalizations.of(context).monthlySummaryChartTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(displayMonths),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${displayMonths[groupIndex].month}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: rod.toY.toStringAsFixed(2),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= displayMonths.length) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _getShortMonthName(
                                displayMonths[value.toInt()].month),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                barGroups: _generateBarGroups(displayMonths, colorScheme),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateBarGroups(
      List<MonthSummary> displayMonths, ColorScheme colorScheme) {
    final groups = <BarChartGroupData>[];

    for (int i = 0; i < displayMonths.length; i++) {
      final month = displayMonths[i];

      final totalExpenses = month.categories
          .fold<double>(0, (sum, category) => sum + category.amount);

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: totalExpenses,
              color: colorScheme.primary,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  double _calculateMaxY(List<MonthSummary> months) {
    if (months.isEmpty) return 100;

    double maxValue = 0;
    for (final month in months) {
      final totalExpenses = month.categories
          .fold<double>(0, (sum, category) => sum + category.amount);
      maxValue = maxValue < totalExpenses ? totalExpenses : maxValue;
    }

    return ((maxValue ~/ 100) + 1) * 100.0;
  }

  String _getShortMonthName(String fullMonth) {
    return fullMonth.length > 3 ? fullMonth.substring(0, 3) : fullMonth;
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context).noDataChartTitle,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
