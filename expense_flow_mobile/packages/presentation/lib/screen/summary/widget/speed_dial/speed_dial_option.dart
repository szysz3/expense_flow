import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/widget/animated_square_button.dart';

class SpeedDialOption extends StatelessWidget {
  final String svgPath;
  final String label;
  final VoidCallback onPressed;
  final double iconSize;

  const SpeedDialOption({
    super.key,
    required this.svgPath,
    required this.label,
    required this.onPressed,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          // Button
          AnimatedSquareButton(
            isProcessing: false,
            onPressed: onPressed,
            width: 48.0,
            height: 48.0,
            iconSize: iconSize,
            borderColor: Colors.white,
            backgroundColor: Colors.black,
            icon: SvgPicture.asset(
              svgPath,
              width: iconSize,
              height: iconSize,
            ),
          ),
        ],
      ),
    );
  }
}
