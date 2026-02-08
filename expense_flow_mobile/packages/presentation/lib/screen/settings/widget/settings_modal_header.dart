import 'package:flutter/material.dart';
import 'package:presentation/core/widget/glass_container.dart';

class SettingsModalHeader extends StatelessWidget {
  const SettingsModalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            width: 46,
            height: 6,
            blur: 10,
            tintOpacity: 0.4,
            borderRadius: BorderRadius.circular(10),
            padding: EdgeInsets.zero,
            child: const SizedBox(),
          ),
        ],
      ),
    );
  }
}
