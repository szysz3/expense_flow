import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blur;
  final Color? tint;
  final double tintOpacity;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry alignment;
  final double? width;
  final double? height;
  final bool expand;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.blur = 18,
    this.tint,
    this.tintOpacity = 0.55,
    this.gradient,
    this.border,
    this.boxShadow,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedBorder = border ??
        Border.all(
          color: scheme.outline.withValues(alpha: 0.4),
          width: 1,
        );
    final resolvedShadow = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ];

    final effectiveAlignment = expand ? alignment : null;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          alignment: effectiveAlignment,
          padding: padding,
          decoration: BoxDecoration(
            color: (tint ?? scheme.surface).withValues(alpha: tintOpacity),
            gradient: gradient,
            borderRadius: borderRadius,
            border: resolvedBorder,
            boxShadow: resolvedShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
