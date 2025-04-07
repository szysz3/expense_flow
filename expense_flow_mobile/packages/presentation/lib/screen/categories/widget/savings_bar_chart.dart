import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../../../theme/expense_flow_colors.dart';
import '../models/category.dart';

// TODO: needs to be refactored
class SavingsBarChart extends StatelessWidget {
  final List<Category> categories;
  final double income;
  final double savingsAmount;

  const SavingsBarChart({
    super.key,
    required this.categories,
    required this.income,
    required this.savingsAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return _buildEmptyState(context);
    }

    final currentDate = DateTime.now();
    final daysInMonth =
        DateTime(currentDate.year, currentDate.month + 1, 0).day;
    final currentDay = currentDate.day;

    final totalExpenses = _calculateTotalExpenses();
    final List<double> dailyExpenses =
        _simulateDailyExpenses(totalExpenses, currentDay, daysInMonth);

    final maxAllowedExpenses = income - savingsAmount;

    final currentSavings = income - totalExpenses;
    final isSavingsOnTrack = currentSavings >= savingsAmount;

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _buildTitle(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack(
              children: [
                BarChart(
                  _createBarChartData(
                    dailyExpenses,
                    daysInMonth,
                    currentDay,
                    maxAllowedExpenses,
                    colorScheme,
                  ),
                ),
                Positioned.fill(
                  left: 40,
                  bottom: 30,
                  child: IgnorePointer(
                    child: LineChart(
                      _createLineChartData(
                        dailyExpenses,
                        daysInMonth,
                        currentDay,
                        maxAllowedExpenses,
                        colorScheme,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildSummary(context, totalExpenses, currentSavings, isSavingsOnTrack,
            maxAllowedExpenses),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Monthly Savings Chart',
        // Would use AppLocalizations.of(context).monthlySavingsChartTitle
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  BarChartData _createBarChartData(
    List<double> dailyExpenses,
    int daysInMonth,
    int currentDay,
    double maxAllowedExpenses,
    ColorScheme colorScheme,
  ) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _calculateMaxY(dailyExpenses, maxAllowedExpenses),
      barTouchData: _createTooltipData(dailyExpenses, colorScheme),
      titlesData: _createTitlesData(daysInMonth, currentDay),
      gridData: _createGridData(),
      borderData: _createBorderData(),
      barGroups: _generateBarGroups(dailyExpenses, currentDay, colorScheme),
    );
  }

  LineChartData _createLineChartData(
    List<double> dailyExpenses,
    int daysInMonth,
    int currentDay,
    double maxAllowedExpenses,
    ColorScheme colorScheme,
  ) {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      maxY: _calculateMaxY(dailyExpenses, maxAllowedExpenses),
      minX: 0,
      maxX: currentDay - 1.0,
      lineBarsData: [
        // Trend line for expenses
        _createTrendLine(dailyExpenses, currentDay, colorScheme),
        // Maximum allowed expenses line
        _createMaxAllowedLine(maxAllowedExpenses, currentDay),
      ],
      lineTouchData: const LineTouchData(enabled: false),
    );
  }

  BarTouchData _createTooltipData(
    List<double> dailyExpenses,
    ColorScheme colorScheme,
  ) {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.6),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final dayIndex = group.x;
          if (dayIndex >= dailyExpenses.length) return null;

          return BarTooltipItem(
            'Day ${dayIndex + 1}\n',
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            children: <TextSpan>[
              TextSpan(
                text: dailyExpenses[dayIndex].toStringAsFixed(2),
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

  FlTitlesData _createTitlesData(int daysInMonth, int currentDay) {
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
            // Show every 5th day and the current day
            if (value % 5 == 0 || value == currentDay - 1) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${value.toInt() + 1}',
                  style: const TextStyle(fontSize: 10),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          reservedSize: 30,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value % 500 == 0) {
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

  FlGridData _createGridData() {
    return FlGridData(
      show: true,
      getDrawingHorizontalLine: (value) {
        if (value % 500 == 0) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        }
        return FlLine(
          color: Colors.transparent,
        );
      },
      drawVerticalLine: true,
      getDrawingVerticalLine: (value) {
        if (value % 5 == 0) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 0.5,
            dashArray: [5, 5],
          );
        }
        return FlLine(
          color: Colors.transparent,
        );
      },
    );
  }

  FlBorderData _createBorderData() {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        left: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(
    List<double> dailyExpenses,
    int currentDay,
    ColorScheme colorScheme,
  ) {
    return List.generate(currentDay, (i) {
      final barColor = i == currentDay - 1
          ? colorScheme.primary
          : colorScheme.primary.withOpacity(0.7);

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: dailyExpenses[i],
            color: barColor,
            width: 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  LineChartBarData _createTrendLine(
    List<double> dailyExpenses,
    int currentDay,
    ColorScheme colorScheme,
  ) {
    final spots = <FlSpot>[];

    for (int i = 0; i < currentDay; i++) {
      spots.add(FlSpot(i.toDouble(), dailyExpenses[i]));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: ExpenseFlowColors.chartYellow,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: false,
        color: ExpenseFlowColors.chartYellow.withOpacity(0.15),
      ),
    );
  }

  LineChartBarData _createMaxAllowedLine(
      double maxAllowedExpenses, int currentDay) {
    final spots = <FlSpot>[];

    for (int i = 0; i < currentDay; i++) {
      spots.add(FlSpot(i.toDouble(), maxAllowedExpenses));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: ExpenseFlowColors.chartRed.withOpacity(0.8),
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      dashArray: [5, 5],
    );
  }

  Widget _buildSummary(
    BuildContext context,
    double totalExpenses,
    double currentSavings,
    bool isSavingsOnTrack,
    double maxAllowedExpenses,
  ) {
    final savingsColor = isSavingsOnTrack ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ExpenseFlowColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).totalChartData,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                totalExpenses.toStringAsFixed(2),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Max Allowed Expenses',
                // Would use AppLocalizations.of(context).maxAllowedExpenses
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              Text(
                maxAllowedExpenses.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Balance',
                // Would use AppLocalizations.of(context).currentSavings
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              Text(
                (maxAllowedExpenses - totalExpenses).toStringAsFixed(2),
                style: TextStyle(
                  color: savingsColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Savings',
                // Would use AppLocalizations.of(context).currentSavings
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    currentSavings.toStringAsFixed(2),
                    style: TextStyle(
                      color: savingsColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isSavingsOnTrack ? Icons.trending_up : Icons.trending_down,
                    color: savingsColor,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _calculateSavingsProgress(currentSavings),
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(savingsColor),
          ),
        ],
      ),
    );
  }

  double _calculateSavingsProgress(double currentSavings) {
    if (savingsAmount <= 0) return 1.0;
    final progress = currentSavings / savingsAmount;
    return progress.clamp(0.0, 1.0);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context).noDataChartTitle,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  double _calculateTotalExpenses() {
    return categories.fold<double>(
        0, (sum, category) => sum + category.totalAmount);
  }

  // TODO: extend with real data from backend once we have transaction_datetime in place
  List<double> _simulateDailyExpenses(
      double totalExpenses, int currentDay, int daysInMonth) {
    // Simulates cumulative daily expenses up to the current day
    // Normally this would come from actual daily data
    final List<double> dailyCumulative = List.filled(daysInMonth, 0);

    // Simple distribution - more realistic data would come from actual spending patterns
    double runningTotal = 0;
    for (int i = 0; i < currentDay; i++) {
      // On early days, spend less, then increase over time
      // This creates a somewhat realistic curve
      final dayFactor = (i + 1) / currentDay;
      final adjustedFactor =
          0.5 + (dayFactor * 0.5); // Starts at 0.5, grows to 1.0

      // Add some daily spending
      final dailyAmount = totalExpenses * adjustedFactor * 1.5 / currentDay;
      runningTotal += dailyAmount;

      // Ensure we don't exceed the total (adjust the last day if needed)
      if (i == currentDay - 1) {
        dailyCumulative[i] = totalExpenses;
      } else {
        dailyCumulative[i] =
            runningTotal > totalExpenses ? totalExpenses : runningTotal;
      }
    }

    return dailyCumulative;
  }

  double _calculateMaxY(List<double> dailyExpenses, double maxAllowedExpenses) {
    final maxExpense = dailyExpenses.isEmpty
        ? 0
        : dailyExpenses.reduce((a, b) => a > b ? a : b);
    final maxValue =
        maxExpense > maxAllowedExpenses ? maxExpense : maxAllowedExpenses;
    return ((maxValue ~/ 500) + 1) * 500.0;
  }
}
