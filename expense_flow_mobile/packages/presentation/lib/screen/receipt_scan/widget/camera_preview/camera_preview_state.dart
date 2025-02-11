import 'package:camera/camera.dart';

class CameraPreviewState {
  final bool isCameraPreviewActive;
  final bool isPhotoPreviewActive;
  final bool isProcessing;
  final String? photoPath;
  final CameraController cameraController;

  const CameraPreviewState({
    this.isCameraPreviewActive = false,
    this.isPhotoPreviewActive = false,
    this.isProcessing = false,
    this.photoPath,
    required this.cameraController,
  });
}
