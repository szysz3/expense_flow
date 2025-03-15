import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:localization/gen_l10n/app_localizations.dart';
import 'package:presentation/screen/summary/widget/speed_dial/speed_dial_option.dart';

import '../../../../core/widget/animated_square_button.dart';

class SpeedDialMenu extends StatefulWidget {
  final VoidCallback? onBarChartSelected;
  final VoidCallback? onPieChartSelected;
  final VoidCallback? onSummarySelected;

  const SpeedDialMenu({
    super.key,
    this.onBarChartSelected,
    this.onPieChartSelected,
    this.onSummarySelected,
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
          SpeedDialOption(
            svgPath: 'packages/presentation/assets/icon_bar_chart.svg',
            label: AppLocalizations.of(context).barChart,
            onPressed: () {
              _toggleDial();
              if (widget.onBarChartSelected != null) {
                widget.onBarChartSelected!();
              }
            },
          ),
          SpeedDialOption(
            svgPath: 'packages/presentation/assets/icon_pie_chart.svg',
            label: AppLocalizations.of(context).pieChart,
            onPressed: () {
              _toggleDial();
              if (widget.onPieChartSelected != null) {
                widget.onPieChartSelected!();
              }
            },
          ),
          SpeedDialOption(
            svgPath: 'packages/presentation/assets/icon_summary.svg',
            label: AppLocalizations.of(context).summary,
            onPressed: () {
              _toggleDial();
              if (widget.onSummarySelected != null) {
                widget.onSummarySelected!();
              }
            },
          ),
        ],
        AnimatedSquareButton.square(
          isProcessing: false,
          onPressed: _toggleDial,
          borderColor: Colors.white,
          backgroundColor: Colors.black,
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
