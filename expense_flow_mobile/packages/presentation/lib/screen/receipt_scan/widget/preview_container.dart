import 'package:flutter/material.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_preview_state.dart';
import 'package:presentation/screen/receipt_scan/widget/preview_content.dart';

class PreviewContainer extends StatelessWidget {
  final CameraPreviewState state;
  final void Function(TapUpDetails, Size) onFocusTap;

  const PreviewContainer({
    required this.state,
    required this.onFocusTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: _getPreviewBorderRadius(),
          ),
          child: ClipRRect(
            borderRadius: _getPreviewBorderRadius(),
            child: GestureDetector(
              onTapUp: state.isCameraPreviewActive
                  ? (details) => onFocusTap(details,
                      Size(constraints.maxWidth, constraints.maxHeight))
                  : null,
              child: PreviewContent(state: state),
            ),
          ),
        ),
      );

  BorderRadius _getPreviewBorderRadius() => state.isPhotoPreviewActive
      ? const BorderRadius.vertical(top: Radius.circular(8))
      : BorderRadius.circular(8);
}
