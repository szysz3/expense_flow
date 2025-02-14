import 'package:camera/camera.dart';

abstract class CameraPreviewState {}

class CameraPreviewInit extends CameraPreviewState {}

class CameraPreviewInitialized extends CameraPreviewState {
  final CameraController controller;

  CameraPreviewInitialized(this.controller);
}

class CameraInitError extends CameraPreviewState {
  final String message;
  CameraInitError(this.message);
}
