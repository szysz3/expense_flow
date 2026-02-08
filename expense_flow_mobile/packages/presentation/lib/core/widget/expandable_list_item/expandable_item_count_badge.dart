import 'package:flutter/material.dart';

class ExpandableItemCountBadge extends StatelessWidget {
  final int count;

  const ExpandableItemCountBadge({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'x$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          overflow: TextOverflow.ellipsis,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
