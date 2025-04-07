import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:presentation/screen/summary/widget/speed_dial/speed_dial_menu_data.dart';
import 'package:presentation/screen/summary/widget/speed_dial/speed_dial_option.dart';

import '../../../../core/widget/animated_square_button.dart';

class SpeedDialMenu extends StatefulWidget {
  final List<SpeedDialMenuData> options;

  const SpeedDialMenu({
    super.key,
    required this.options,
  });

  @override
  State<SpeedDialMenu> createState() => _SpeedDialMenuState();
}

class _SpeedDialMenuState extends State<SpeedDialMenu> {
  bool _isDialOpen = false;

  void _toggleDial() {
    setState(() {
      _isDialOpen = !_isDialOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isDialOpen) ...[
          ...widget.options.map((option) => SpeedDialOption(
                svgPath: option.svgPath,
                label: option.label,
                onPressed: () {
                  _toggleDial();
                  option.onPressed();
                },
              )),
        ],
        AnimatedSquareButton.square(
          isProcessing: false,
          onPressed: _toggleDial,
          borderColor: Colors.white,
          backgroundColor: Colors.black,
          opacity:
              _isDialOpen ? 1 : AnimatedSquareButtonConstants.defaultOpacity,
          icon: SvgPicture.asset(
            _isDialOpen
                ? 'packages/presentation/assets/icon_close.svg'
                : 'packages/presentation/assets/icon_menu.svg',
            width: 40,
            height: 40,
          ),
          size: 64,
          iconSize: 40,
        ),
      ],
    );
  }
}
