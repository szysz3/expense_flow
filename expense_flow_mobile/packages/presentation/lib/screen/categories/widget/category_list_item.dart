import 'package:flutter/material.dart';
import 'package:presentation/screen/categories/models/category.dart';
import 'package:presentation/screen/categories/models/category_item.dart';

class CategoryListItem extends StatelessWidget {
  final Category category;
  final VoidCallback onToggle;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCategoryHeader(),
        if (category.isExpanded) _buildItemsList(),
      ],
    );
  }

  Widget _buildCategoryHeader() {
    return InkWell(
      onTap: onToggle,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(IconData(int.parse(category.iconName))),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '\$${category.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            RotatedBox(
              quarterTurns: category.isExpanded ? 1 : 3,
              child: const Icon(Icons.chevron_right),
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
      itemCount: category.items.length,
      itemBuilder: (context, index) {
        final item = category.items[index];
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
