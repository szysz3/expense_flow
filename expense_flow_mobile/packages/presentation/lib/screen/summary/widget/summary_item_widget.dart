import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:presentation/theme/expense_flow_colors.dart';

import '../../../core/widget/expandable_list_item/expandable_list_item.dart';
import '../model/category_summary.dart';
import '../model/month_summary.dart';
import '../model/summary_item_data.dart';
import '../model/summary_item_header_data.dart';

class SummaryItemWidget extends StatelessWidget {
  final MonthSummary month;
  final VoidCallback onToggle;

  const SummaryItemWidget(
      {super.key, required this.month, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ExpandableListItem<SummaryItemHeaderData, SummaryItemData>(
      headerData: SummaryItemHeaderData(month),
      items: month.categories.map((c) => SummaryItemData(c)).toList(),
      onToggle: onToggle,
      headerTrailing: (data) => _buildTotalColumn(month),
      headerColumns: (data) => [
        _buildSavingsColumn(month),
        _buildChangeIndicator(month),
      ],
      itemLeading: (item) => SvgPicture.asset(
        item.category.iconName,
        width: 24,
        height: 24,
      ),
      itemTrailing: (item) => _buildCategoryChangeIndicator(item.category),
    );
  }

  Widget _buildTotalColumn(MonthSummary month) {
    return Expanded(
      flex: 3,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            "Total",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            month.totalAmount.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsColumn(MonthSummary month) {
    final double? savings = month.calculateSavings();
    final savingsColor = month.savingsOnTrack
        ? ExpenseFlowColors.chartMutedGreen
        : ExpenseFlowColors.chartMutedRed;

    if (savings == null || savings == 0) {
      return const SizedBox.shrink();
    }

    return Expanded(
      flex: 3,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Savings",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            savings.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: savingsColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChangeIndicator(MonthSummary month) {
    final changePercentage = month.changePercentage.abs().toStringAsFixed(1);
    final changeColor = month.isIncrease
        ? ExpenseFlowColors.chartMutedRed
        : ExpenseFlowColors.chartMutedGreen;
    final changeIcon =
        month.isIncrease ? Icons.arrow_upward : Icons.arrow_downward;

    return Expanded(
        flex: 2,
        child: Opacity(
          opacity: month.previousMonthAmount <= 0 ? 0 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(changeIcon, color: changeColor, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '$changePercentage%',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildCategoryChangeIndicator(CategorySummary category) {
    final changePercentage = category.changePercentage.abs().toStringAsFixed(1);
    final changeColor = (category.isIncrease
        ? ExpenseFlowColors.chartMutedRed
        : ExpenseFlowColors.chartMutedGreen);
    final changeIcon =
        category.isIncrease ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(changeIcon, color: changeColor, size: 14),
        const SizedBox(width: 4),
        Text(
          '$changePercentage%',
          style: TextStyle(
            color: changeColor,
            fontSize: 10,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
