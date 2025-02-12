import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:camera/camera.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_state.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_preview_state.dart';

class PreviewContent extends StatelessWidget {
  static const _animationDuration = Duration(milliseconds: 300);

  final CameraPreviewWidgetState state;

  const PreviewContent({required this.state, super.key});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: _animationDuration,
        transitionBuilder: _buildTransition,
        child: _getContent(),
      );

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final scaleCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    );
    final scaleValue = Tween<double>(begin: 0.9, end: 1.0).animate(scaleCurve);

    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: scaleValue,
        child: child,
      ),
    );
  }

  Widget _getContent() {
    print('------> state: ${state.previewState}, file: ${state.photoPath}');

    if (state.previewState == CameraPreviewState.photoPreview &&
        state.photoPath != null) {
      return Image.file(File(state.photoPath!), fit: BoxFit.cover);
    }
    if ([CameraPreviewState.photoProcessing, CameraPreviewState.cameraPreview]
        .contains(state.previewState)) {
      return CameraPreview(state.cameraController);
    }

    return const SizedBox.expand();
  }
}
