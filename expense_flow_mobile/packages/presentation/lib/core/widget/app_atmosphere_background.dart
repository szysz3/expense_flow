import 'package:flutter/material.dart';

class AppAtmosphereBackground extends StatelessWidget {
  const AppAtmosphereBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.surface,
                    scheme.surface.withValues(alpha: 0.9),
                    scheme.background,
                  ],
                ),
              ),
            ),
          ),
          _GlowOrb(
            alignment: const Alignment(-1.1, -0.9),
            color: scheme.primary,
            size: 280,
            intensity: 0.22,
          ),
          _GlowOrb(
            alignment: const Alignment(1.1, 0.6),
            color: scheme.secondary,
            size: 320,
            intensity: 0.18,
          ),
          _GlowOrb(
            alignment: const Alignment(0.2, -0.2),
            color: scheme.tertiary,
            size: 220,
            intensity: 0.16,
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;
  final double intensity;

  const _GlowOrb({
    required this.alignment,
    required this.color,
    required this.size,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: intensity),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
