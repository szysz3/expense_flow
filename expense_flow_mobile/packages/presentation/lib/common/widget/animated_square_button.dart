import 'package:flutter/material.dart';

class AnimatedSquareButton extends StatelessWidget {
  static const _buttonAnimationDuration = Duration(milliseconds: 400);

  final bool isProcessing;
  final VoidCallback onPressed;
  final Widget icon;
  final double size;
  final double iconSize;
  final Color borderColor;
  final Color backgroundColor;

  const AnimatedSquareButton({
    required this.isProcessing,
    required this.onPressed,
    required this.icon,
    this.size = 64,
    this.iconSize = 40,
    this.borderColor = Colors.white,
    this.backgroundColor = Colors.black,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Center(
        // Moved Center to root level
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: _buttonAnimationDuration,
          curve: Curves.elasticOut,
          builder: (_, value, child) => Transform.scale(
            scale: value,
            child: child,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
              color: backgroundColor.withOpacity(0.4),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isProcessing ? null : onPressed,
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (child, animation) {
                      final scaleCurve = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      );
                      final scaleValue = Tween<double>(
                        begin: 0.8,
                        end: 1.0,
                      ).animate(scaleCurve);
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: scaleValue,
                          child: child,
                        ),
                      );
                    },
                    child:
                        icon, // Removed SizedBox wrapper since icon already has size
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
