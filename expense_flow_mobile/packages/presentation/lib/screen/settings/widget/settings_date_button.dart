import 'package:flutter/material.dart';

class SettingsDateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onPressed;

  const SettingsDateButton({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    final borderColor = enabled
        ? Colors.grey.withValues(alpha: 0.7)
        : Colors.grey.withValues(alpha: 0.3);
    final backgroundColor =
        Colors.black.withValues(alpha: enabled ? 0.28 : 0.16);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: enabled
          ? theme.colorScheme.onSurface.withValues(alpha: 0.9)
          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(12),
                color: backgroundColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: textStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.calendar_month,
                    size: 20,
                    color: enabled
                        ? theme.colorScheme.primary.withValues(alpha: 0.9)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
