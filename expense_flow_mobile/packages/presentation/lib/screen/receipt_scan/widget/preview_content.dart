import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:camera/camera.dart';
import 'package:presentation/screen/receipt_scan/widget/camera_preview/camera_preview_state.dart';

class PreviewContent extends StatelessWidget {
  static const _animationDuration = Duration(milliseconds: 300);

  final CameraPreviewState state;

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
    if (state.isCameraPreviewActive) {
      return CameraPreview(state.cameraController);
    }
    if (state.isPhotoPreviewActive && state.photoPath != null) {
      return Image.file(File(state.photoPath!), fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }
}
