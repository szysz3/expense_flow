import 'package:camera/camera.dart';

abstract class CamerawPreviewState {}

class CameraPreviewInit extends CamerawPreviewState {}

class CameraPreviewInitialized extends CamerawPreviewState {
  final CameraController controller;

  CameraPreviewInitialized(this.controller);
}

class CameraInitError extends CamerawPreviewState {
  final String message;
  CameraInitError(this.message);
}
