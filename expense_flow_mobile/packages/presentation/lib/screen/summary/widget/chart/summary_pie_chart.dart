import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:localization/gen_l10n/app_localizations.dart';

import '../../../../core/utils/currency_text_formatter.dart';
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

    // Take only the most recent 12 months for display
    final displayMonths = months.take(12).toList();
    final totalExpenses = _calculateTotalExpenses(displayMonths);
    final chartColors = ExpenseFlowColors.chartColorsList;

    return Column(
      children: [
        _buildChartTitle(context),
        _buildPieChart(displayMonths, totalExpenses, chartColors),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ..._buildLegendItems(displayMonths, chartColors, context),
                if (displayMonths.isNotEmpty)
                  _buildTotalRow(context, totalExpenses),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        AppLocalizations.of(context).monthlySummaryChartTitle,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  Widget _buildPieChart(
    List<MonthSummary> months,
    double totalExpenses,
    List<Color> chartColors,
  ) {
    final sections =
        _createPieChartSections(months, totalExpenses, chartColors);

    return Container(
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
    );
  }

  List<PieChartSectionData> _createPieChartSections(
    List<MonthSummary> months,
    double totalExpenses,
    List<Color> chartColors,
  ) {
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < months.length; i++) {
      final month = months[i];
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

    return sections;
  }

  List<Widget> _buildLegendItems(List<MonthSummary> months,
      List<Color> chartColors, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    var currencyFormatter = CurrencyTextFormatter(locale: locale);

    return [
      for (int i = 0; i < months.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: chartColors[i % chartColors.length],
              ),
              const SizedBox(width: 8),
              Text(
                months[i].monthName,
                style: const TextStyle(color: Colors.white),
              ),
              const Spacer(),
              Text(
                currencyFormatter
                    .formatCurrency(_calculateMonthTotal(months[i])),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _buildTotalRow(BuildContext context, double totalExpenses) {
    final locale = Localizations.localeOf(context).toString();
    var currencyFormatter = CurrencyTextFormatter(locale: locale);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              currencyFormatter.formatCurrency(totalExpenses),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: ExpenseFlowColors.darkPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMonthTotal(MonthSummary month) {
    return month.categories
        .fold<double>(0, (sum, category) => sum + category.amount);
  }

  double _calculateTotalExpenses(List<MonthSummary> months) {
    return months.fold<double>(
        0, (sum, month) => sum + _calculateMonthTotal(month));
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
