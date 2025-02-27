import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:presentation/screen/summary/model/summary_item_data.dart';
import 'package:presentation/screen/summary/model/summary_item_header_data.dart';

import '../../../common/widget/expandable_list_item/expandable_list_item.dart';
import '../model/category_summary.dart';
import '../model/month_summary.dart';

class SummaryItemWidget extends StatelessWidget {
  final MonthSummary month;
  final VoidCallback onToggle;

  const SummaryItemWidget({
    super.key,
    required this.month,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ExpandableListItem<SummaryItemHeaderData, SummaryItemData>(
      headerData: SummaryItemHeaderData(month),
      items: month.categories.map((c) => SummaryItemData(c)).toList(),
      onToggle: onToggle,
      headerTrailing: (data) => _buildChangeIndicator(month),
      itemLeading: (item) => SvgPicture.asset(
        item.category.iconName,
        width: 24,
        height: 24,
      ),
      itemTrailing: (item) => _buildCategoryChangeIndicator(item.category),
    );
  }

  Widget _buildChangeIndicator(MonthSummary month) {
    if (month.previousMonthAmount <= 0) return const SizedBox.shrink();

    final changePercentage = month.changePercentage.abs().toStringAsFixed(1);
    final changeColor = month.isIncrease ? Colors.red : Colors.green;
    final changeIcon =
        month.isIncrease ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(changeIcon, color: changeColor, size: 16),
        const SizedBox(width: 4),
        Text(
          '$changePercentage%',
          style: TextStyle(
            color: changeColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCategoryChangeIndicator(CategorySummary category) {
    if (category.changePercentage == 0) {
      return const SizedBox.shrink();
    }

    final changePercentage = category.changePercentage.abs().toStringAsFixed(1);
    final changeColor =
        (category.isIncrease ? Colors.red : Colors.green).withAlpha(150);
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
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
