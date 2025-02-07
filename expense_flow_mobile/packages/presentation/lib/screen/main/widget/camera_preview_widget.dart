import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:presentation/theme/expense_flow_color_scheme.dart';

class CameraPreview extends StatelessWidget {
  final CameraController controller;

  const CameraPreview(this.controller);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBlurredBackgroundPreview(context),
      ],
    );
  }

  Widget _buildBlurredBackgroundPreview(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final data = MediaQuery.of(context);
    final aspectRatio = controller.value.aspectRatio;
    final deviceRatio = size.width / size.height + data.padding.bottom;

    return Center(
      child: Transform.scale(
        scale: controller.value.aspectRatio / deviceRatio,
        child: AspectRatio(
            aspectRatio: aspectRatio,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.accentDelicate,
                  BlendMode.modulate,
                ),
                child: Transform.rotate(
                  angle: _getCameraRotation(),
                  child: CameraPreview(controller),
                ),
              ),
            )),
      ),
    );
  }

  double _getCameraRotation() {
    final sensorOrientation = controller.description.sensorOrientation;
    return sensorOrientation * pi / 180;
  }
}
