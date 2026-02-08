import 'package:flutter/material.dart';

/// Displays a visual boundary (line + shadow) at the top or bottom of a scrollable area.
/// Used to indicate that more content is available in that direction.
class ScrollBoundaryIndicator extends StatelessWidget {
  final bool isTop;

  const ScrollBoundaryIndicator.top({super.key}) : isTop = true;
  const ScrollBoundaryIndicator.bottom({super.key}) : isTop = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: isTop
          ? [
              _buildBorder(context),
              _buildShadow(context, isDownward: true),
            ]
          : [
              _buildShadow(context, isDownward: false),
              _buildBorder(context),
            ],
    );
  }

  Widget _buildBorder(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? BorderSide.none
              : BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                  width: 1,
                ),
          bottom: isTop
              ? BorderSide(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                  width: 1,
                )
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildShadow(BuildContext context, {required bool isDownward}) {
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .colorScheme
                .shadow
                .withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, isDownward ? 2 : -2),
          ),
        ],
      ),
    );
  }
}
