// add_item/widgets/category_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CategoryButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const CategoryButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    icon,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                      BlendMode.srcIn,
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.all(4),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )),
                ],
              ),
            ),
          ),
        ),
      );
}
