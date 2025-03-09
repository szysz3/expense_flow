import 'package:camera/camera.dart';

import '../../model/camera_preview_state.dart';

class CameraPreviewWidgetState {
  final CameraPreviewState previewState;
  final String? photoPath;
  final CameraController cameraController;

  const CameraPreviewWidgetState({
    required this.previewState,
    this.photoPath,
    required this.cameraController,
  });
}
