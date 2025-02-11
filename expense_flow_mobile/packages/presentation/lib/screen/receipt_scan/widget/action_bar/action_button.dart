import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ActionButton extends StatelessWidget {
  final int flex;
  final String iconPath;
  final double iconSize;
  final VoidCallback? onTap;

  const ActionButton({
    required this.flex,
    required this.iconPath,
    required this.iconSize,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
              ),
            ),
          ),
        ),
      );
}
