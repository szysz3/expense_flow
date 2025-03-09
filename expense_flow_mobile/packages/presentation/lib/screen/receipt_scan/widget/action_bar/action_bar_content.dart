import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          color: Colors.black.withOpacity(0.4),
        ),
        transform: Matrix4.translationValues(0, -1, 0),
        height: 64,
        child: Row(
          children: [
            ActionButton(
              flex: 1,
              iconPath: 'packages/presentation/assets/icon_back.svg',
              iconSize: 24,
              onTap: onBackPressed,
            ),
            Container(width: 1, color: Colors.white),
            ActionButton(
              flex: 3,
              iconPath: 'packages/presentation/assets/icon_tick.svg',
              iconSize: 40,
              onTap: onConfirmPressed,
            ),
          ],
        ),
      );
}
