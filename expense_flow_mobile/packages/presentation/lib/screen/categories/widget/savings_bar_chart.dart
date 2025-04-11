import 'package:domain/model/daily_expense.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../../../theme/expense_flow_colors.dart';

class SavingsBarChart extends StatelessWidget {
  final List<DailyExpense> dailyExpenses;
  final double income;
  final double savingsAmount;
  final List<double> cumulativeExpenses;
  final double totalExpenses;

  const SavingsBarChart({
    super.key,
    required this.dailyExpenses,
    required this.income,
    required this.savingsAmount,
    required this.cumulativeExpenses,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyExpenses.isEmpty) {
      return _buildEmptyState(context);
    }

    final currentDate = DateTime.now();
    final daysInMonth =
        DateTime(currentDate.year, currentDate.month + 1, 0).day;
    final currentDay = currentDate.day;

    final maxAllowedExpenses = income - savingsAmount;
    final currentSavings = income - totalExpenses;
    final isSavingsOnTrack = currentSavings >= savingsAmount;

    return Column(
      children: [
        _buildTitle(context),
        Expanded(
          child: _buildChart(
            context,
            currentDay,
            daysInMonth,
            maxAllowedExpenses,
          ),
        ),
        _buildSummary(
          context,
          totalExpenses,
          currentSavings,
          isSavingsOnTrack,
          maxAllowedExpenses,
        ),
      ],
    );
  }

  Widget _buildChart(
    BuildContext context,
    int currentDay,
    int daysInMonth,
    double maxAllowedExpenses,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          BarChart(
            _createBarChartData(
              cumulativeExpenses,
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
                  cumulativeExpenses,
                  currentDay,
                  maxAllowedExpenses,
                  colorScheme,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        AppLocalizations.of(context).monthlySavingsChart,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context).noDataChartTitle,
        style: Theme.of(context).textTheme.bodyLarge,
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
    final maxY = _calculateMaxY(dailyExpenses, maxAllowedExpenses);

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: _createBarTooltipData(dailyExpenses, colorScheme),
      titlesData: _createAxisTitles(daysInMonth, currentDay),
      gridData: _createGridData(),
      borderData: _createBorderData(),
      barGroups: _createBarGroups(dailyExpenses, currentDay, colorScheme),
    );
  }

  BarTouchData _createBarTooltipData(
    List<double> dailyExpenses,
    ColorScheme colorScheme,
  ) {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => Colors.black.withOpacity(0.6),
        getTooltipItem: (group, _, rod, __) {
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

  List<BarChartGroupData> _createBarGroups(
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

  LineChartData _createLineChartData(
    List<double> dailyExpenses,
    int currentDay,
    double maxAllowedExpenses,
    ColorScheme colorScheme,
  ) {
    final maxY = _calculateMaxY(dailyExpenses, maxAllowedExpenses);

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      maxY: maxY,
      minX: 0,
      maxX: currentDay - 1.0,
      lineBarsData: [
        _createExpensesTrendLine(dailyExpenses, currentDay),
        _createMaxAllowedLine(maxAllowedExpenses, currentDay),
      ],
      lineTouchData: const LineTouchData(enabled: false),
    );
  }

  LineChartBarData _createExpensesTrendLine(
    List<double> dailyExpenses,
    int currentDay,
  ) {
    final spots = <FlSpot>[];
    for (int i = 0; i < currentDay; i++) {
      spots.add(FlSpot(i.toDouble(), dailyExpenses[i]));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: false,
      show: false,
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
    double maxAllowedExpenses,
    int currentDay,
  ) {
    final spots = List.generate(
      currentDay,
      (i) => FlSpot(i.toDouble(), maxAllowedExpenses),
    );

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

  FlTitlesData _createAxisTitles(int daysInMonth, int currentDay) {
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
          getTitlesWidget: (value, _) {
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
          getTitlesWidget: (value, _) {
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
        return FlLine(color: Colors.transparent);
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
        return FlLine(color: Colors.transparent);
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

  Widget _buildSummary(
    BuildContext context,
    double totalExpenses,
    double currentSavings,
    bool isSavingsOnTrack,
    double maxAllowedExpenses,
  ) {
    final savingsColor = isSavingsOnTrack
        ? ExpenseFlowColors.chartMutedGreen
        : ExpenseFlowColors.chartMutedRed;
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryRow(
            localizations.totalChartData,
            totalExpenses.toStringAsFixed(2),
            Theme.of(context).colorScheme.primary,
            isBold: true,
            textTheme: textTheme,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            localizations.maxAllowedExpenses,
            maxAllowedExpenses.toStringAsFixed(2),
            Colors.white,
            textTheme: textTheme,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            localizations.balance,
            (maxAllowedExpenses - totalExpenses).toStringAsFixed(2),
            savingsColor,
            textTheme: textTheme,
          ),
          const SizedBox(height: 12),
          _buildSavingsRow(
            localizations.currentSavings,
            currentSavings.toStringAsFixed(2),
            savingsColor,
            isSavingsOnTrack,
            textTheme,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _calculateSavingsProgress(currentSavings),
            minHeight: 6,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(savingsColor),
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
    required TextTheme textTheme,
  }) {
    final labelStyle = textTheme.bodyMedium?.copyWith(
      color: Colors.white.withOpacity(0.9),
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );

    final valueStyle = textTheme.bodyMedium?.copyWith(
      color: valueColor,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _buildSavingsRow(
    String label,
    String value,
    Color valueColor,
    bool isSavingsOnTrack,
    TextTheme textTheme,
  ) {
    final labelStyle = textTheme.bodyMedium?.copyWith(
      color: Colors.white.withOpacity(0.9),
      fontWeight: FontWeight.bold,
    );

    final valueStyle = textTheme.bodyMedium?.copyWith(
      color: valueColor,
      fontWeight: FontWeight.bold,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Row(
          children: [
            Text(value, style: valueStyle),
            const SizedBox(width: 4),
            Icon(
              isSavingsOnTrack ? Icons.trending_up : Icons.trending_down,
              color: valueColor,
              size: 16,
            ),
          ],
        ),
      ],
    );
  }

  double _calculateSavingsProgress(double currentSavings) {
    if (savingsAmount <= 0) return 1.0;
    final progress = currentSavings / savingsAmount;
    return progress.clamp(0.0, 1.0);
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
