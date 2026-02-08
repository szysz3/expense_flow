import 'package:flutter/material.dart';
import 'package:presentation/core/widget/glass_container.dart';

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
            child: GlassContainer(
              width: double.infinity,
              blur: 14,
              tintOpacity: enabled ? 0.45 : 0.25,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline
                    .withValues(alpha: enabled ? 0.7 : 0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
