import 'package:flutter/material.dart';

class ReceiptDetailsInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const ReceiptDetailsInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: isHighlighted
              ? theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
