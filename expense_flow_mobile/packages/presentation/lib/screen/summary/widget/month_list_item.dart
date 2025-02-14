import 'package:flutter/material.dart';
import 'package:presentation/screen/summary/model/category_summary.dart';
import 'package:presentation/screen/summary/model/month_summary.dart';

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
      begin: -0.25,
      end: 0,
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              child: const Icon(Icons.expand_more),
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
    return Container(
      height: 50,
      padding: const EdgeInsets.fromLTRB(56, 0, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '\$${category.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
