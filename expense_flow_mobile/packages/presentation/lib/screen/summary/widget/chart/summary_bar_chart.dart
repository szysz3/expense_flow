import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:localization/app_localizations.dart';

import '../../model/month_summary.dart';

class SummaryBarChart extends StatelessWidget {
  final List<MonthSummary> months;

  const SummaryBarChart({super.key, required this.months});

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return _buildEmptyState(context);
    }

    // Take only the most recent 12 months for display
    final displayMonths = months.take(12).toList().reversed.toList();
    final colorScheme = Theme.of(context).colorScheme;
    final maxY = _calculateMaxY(displayMonths);

    return Column(
      children: [
        _buildTitle(context),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 96),
            child: Column(
              children: [
                Expanded(
                  child: BarChart(
                    _createChartData(displayMonths, colorScheme, maxY),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        AppLocalizations.of(context).monthlySummaryChartTitle,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  BarChartData _createChartData(
    List<MonthSummary> displayMonths,
    ColorScheme colorScheme,
    double maxY,
  ) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: _createTooltipData(displayMonths, colorScheme),
      titlesData: _createTitlesData(displayMonths),
      gridData: _createGridData(colorScheme),
      borderData: _createBorderData(colorScheme),
      barGroups: _generateBarGroups(displayMonths, colorScheme),
    );
  }

  BarTouchData _createTooltipData(
    List<MonthSummary> displayMonths,
    ColorScheme colorScheme,
  ) {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (touchedSpot) =>
            colorScheme.surface.withValues(alpha: 0.85),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            '${displayMonths[groupIndex].monthName}\n',
            TextStyle(
              color: colorScheme.onSurface,
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
        fitInsideHorizontally: true,
        fitInsideVertically: true,
      ),
    );
  }

  FlTitlesData _createTitlesData(List<MonthSummary> displayMonths) {
    return FlTitlesData(
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
                _shortenMonthName(displayMonths[value.toInt()].monthName),
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
            // Important: Don't show the max value to prevent overlap
            double maxValue = _calculateMaxY(months);
            if (value == maxValue) {
              return const SizedBox.shrink();
            }

            if (value % 100 == 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          reservedSize: 40,
        ),
      ),
    );
  }

  FlGridData _createGridData(ColorScheme colorScheme) {
    return FlGridData(
      show: true,
      getDrawingHorizontalLine: (value) {
        if (value % 100 == 0) {
          return FlLine(
            color: colorScheme.outline.withValues(alpha: 0.4),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        }
        return FlLine(
          color: Colors.transparent,
        );
      },
      drawVerticalLine: false,
    );
  }

  FlBorderData _createBorderData(ColorScheme colorScheme) {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5), width: 1),
        left: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5), width: 1),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(
    List<MonthSummary> displayMonths,
    ColorScheme colorScheme,
  ) {
    return List.generate(displayMonths.length, (i) {
      final month = displayMonths[i];
      final totalExpenses = _calculateMonthTotal(month);

      return BarChartGroupData(
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
            backDrawRodData: BackgroundBarChartRodData(
              show: false,
            ),
          ),
        ],
        showingTooltipIndicators: [],
      );
    });
  }

  double _calculateMonthTotal(MonthSummary month) {
    return month.categories
        .fold<double>(0, (sum, category) => sum + category.amount);
  }

  double _calculateMaxY(List<MonthSummary> months) {
    if (months.isEmpty) return 100;

    double maxValue = 0;
    for (final month in months) {
      final totalExpenses = _calculateMonthTotal(month);
      maxValue = maxValue < totalExpenses ? totalExpenses : maxValue;
    }

    return ((maxValue ~/ 100) + 2) * 100.0;
  }

  String _shortenMonthName(String fullMonth) {
    return fullMonth.length > 3 ? fullMonth.substring(0, 3) : fullMonth;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context).noDataChartTitle,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
