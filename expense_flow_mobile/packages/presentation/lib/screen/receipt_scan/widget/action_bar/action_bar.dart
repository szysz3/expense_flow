import 'package:flutter/widgets.dart';
import 'package:presentation/screen/receipt_scan/widget/action_bar/action_bar_content.dart';

class ActionBar extends StatelessWidget {
  static const _animationDuration = Duration(milliseconds: 300);
  static const _previewSlideAnimationDuration = Duration(milliseconds: 600);

  final bool isPhotoPreviewActive;
  final VoidCallback onBackPressed;
  final VoidCallback onConfirmPressed;

  const ActionBar({
    required this.isPhotoPreviewActive,
    required this.onBackPressed,
    required this.onConfirmPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: isPhotoPreviewActive ? 1.0 : 0.0,
        duration: _animationDuration,
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: isPhotoPreviewActive ? 1 : 0,
          duration: _previewSlideAnimationDuration,
          curve: Curves.easeInOut,
          child: ActionBarContent(
            onBackPressed: onBackPressed,
            onConfirmPressed: onConfirmPressed,
          ),
        ),
      );
}
