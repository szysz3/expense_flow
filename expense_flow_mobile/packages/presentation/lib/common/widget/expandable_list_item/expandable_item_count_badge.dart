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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'x$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
