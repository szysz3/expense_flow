import 'package:flutter/material.dart';
import 'package:presentation/core/widget/glass_container.dart';

class SettingsValidationBanner extends StatelessWidget {
  final String message;

  const SettingsValidationBanner({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: GlassContainer(
        blur: 14,
        tint: Theme.of(context).colorScheme.error,
        tintOpacity: 0.2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
