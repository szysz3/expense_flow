import 'package:flutter/material.dart';
import 'package:presentation/core/widget/glass_container.dart';

import 'action_button.dart';

class ActionBarContent extends StatelessWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onConfirmPressed;

  const ActionBarContent({
    required this.onBackPressed,
    required this.onConfirmPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Transform.translate(
        offset: const Offset(0, -1),
        child: GlassContainer(
          height: 64,
          blur: 18,
          tintOpacity: 0.55,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              ActionButton(
                flex: 1,
                iconPath: 'packages/presentation/assets/icon_back.svg',
                iconSize: 24,
                onTap: onBackPressed,
              ),
              Container(
                width: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.5),
              ),
              ActionButton(
                flex: 3,
                iconPath: 'packages/presentation/assets/icon_tick.svg',
                iconSize: 40,
                onTap: onConfirmPressed,
              ),
            ],
          ),
        ),
      );
}
