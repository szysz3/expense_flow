import 'package:flutter/material.dart';

import '../model/camera_preview_state.dart';
import 'camera_preview/camera_preview_widget_state.dart';
import 'preview_content.dart';

class PreviewContainer extends StatelessWidget {
  final CameraPreviewWidgetState state;
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
              onTapUp: state.previewState == CameraPreviewState.cameraPreview
                  ? (details) => onFocusTap(details,
                      Size(constraints.maxWidth, constraints.maxHeight))
                  : null,
              child: PreviewContent(state: state),
            ),
          ),
        ),
      );

  BorderRadius _getPreviewBorderRadius() =>
      state.previewState == CameraPreviewState.photoPreview
          ? const BorderRadius.vertical(top: Radius.circular(8))
          : BorderRadius.circular(8);
}
