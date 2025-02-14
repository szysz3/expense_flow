import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../model/category_summary.dart';
import '../model/month_summary.dart';

class MonthListItem extends StatefulWidget {
  final MonthSummary month;
  final VoidCallback onToggle;

  const MonthListItem({
    super.key,
    required this.month,
    required this.onToggle,
  });

  @override
  State<MonthListItem> createState() => _MonthListItemState();
}

class _MonthListItemState extends State<MonthListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(MonthListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.month.isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMonthHeader(),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildCategoriesList(),
          crossFadeState: widget.month.isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    final changePercentage =
        widget.month.changePercentage.abs().toStringAsFixed(1);
    final changeColor = widget.month.isIncrease ? Colors.red : Colors.green;
    final changeIcon =
        widget.month.isIncrease ? Icons.arrow_upward : Icons.arrow_downward;

    return InkWell(
      onTap: widget.onToggle,
      child: Container(
        height: 60,
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.month.month,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.month.previousMonthTotal > 0) ...[
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
            Text(
              '\$${widget.month.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            RotationTransition(
              turns: _rotationAnimation,
              child: SvgPicture.asset(
                'packages/presentation/assets/icon_right_chevron.svg',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: widget.month.categories.length,
      itemBuilder: (context, index) {
        final category = widget.month.categories[index];
        return _buildCategoryRow(category);
      },
    );
  }

  Widget _buildCategoryRow(CategorySummary category) {
    final changePercentage = category.changePercentage.abs().toStringAsFixed(1);
    final changeColor =
        (category.isIncrease ? Colors.red : Colors.green).withAlpha(150);
    final changeIcon =
        category.isIncrease ? Icons.arrow_upward : Icons.arrow_downward;
    final textColor = Theme.of(context).colorScheme.onSurface.withAlpha(150);

    return Container(
      height: 50,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          SvgPicture.asset(
            category.iconName,
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              category.name,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ),
          if (category.previousMonthAmount > 0 &&
              category.changePercentage != 0) ...[
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
          Text(
            '\$${category.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
