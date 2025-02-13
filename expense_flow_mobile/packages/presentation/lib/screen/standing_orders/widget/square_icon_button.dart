import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SquareIconButton extends StatelessWidget {
  static const _buttonAnimationDuration = Duration(milliseconds: 400);

  final bool isProcessing;
  final VoidCallback onPressed;
  final Widget icon;
  final double size;
  final double iconSize;

  const SquareIconButton({
    required this.isProcessing,
    required this.onPressed,
    required this.icon,
    this.size = 48,
    this.iconSize = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
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
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withOpacity(0.4),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isProcessing ? null : onPressed,
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
                  child: SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: icon,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
