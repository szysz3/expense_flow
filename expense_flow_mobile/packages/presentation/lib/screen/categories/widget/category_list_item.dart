// categories/widgets/category_list_item.dart
import 'package:flutter/material.dart';
import 'package:presentation/screen/categories/models/category.dart';
import 'package:presentation/screen/categories/models/category_item.dart';

class CategoryListItem extends StatefulWidget {
  final Category category;
  final VoidCallback onToggle;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.onToggle,
  });

  @override
  State<CategoryListItem> createState() => _CategoryListItemState();
}

class _CategoryListItemState extends State<CategoryListItem>
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
  void didUpdateWidget(CategoryListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.category.isExpanded) {
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
        _buildCategoryHeader(),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildItemsList(),
          crossFadeState: widget.category.isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader() {
    return InkWell(
      onTap: widget.onToggle,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(IconData(int.parse(widget.category.iconName))),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '\$${widget.category.totalAmount.toStringAsFixed(2)}',
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

  Widget _buildItemsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: widget.category.items.length,
      itemBuilder: (context, index) {
        final item = widget.category.items[index];
        return _buildItemRow(item);
      },
    );
  }

  Widget _buildItemRow(CategoryItem item) {
    return Container(
      height: 50,
      padding: const EdgeInsets.fromLTRB(56, 0, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '\$${item.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
