import 'package:flutter/material.dart';
import 'package:presentation/core/widget/glass_container.dart';

class BaseReceiptDetailScreen extends StatelessWidget {
  final Widget content;
  final Widget actionButtons;

  const BaseReceiptDetailScreen({
    super.key,
    required this.content,
    required this.actionButtons,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: GlassContainer(
        height: MediaQuery.of(context).size.height * 0.90,
        width: double.infinity,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        tintOpacity: 0.65,
        blur: 22,
        child: Stack(
          children: [
            Column(
              children: [
                _buildDragHandle(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: content,
                  ),
                ),
              ],
            ),
            actionButtons,
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
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
