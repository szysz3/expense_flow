import 'package:flutter/material.dart';

class FadingEdge extends StatelessWidget {
  final Widget child;
  final double topFadeSize;
  final double bottomFadeSize;

  const FadingEdge({
    super.key,
    required this.child,
    this.topFadeSize = 20,
    this.bottomFadeSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        final topStop = topFadeSize / bounds.height;
        final bottomStop = 1.0 - (bottomFadeSize / bounds.height);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, topStop, bottomStop, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
