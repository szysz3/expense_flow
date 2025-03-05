import 'package:camera/camera.dart';

abstract class CameraService {
  Future<CameraController> initialize();
  Future<void> setFocusPoint(double x, double y);
  Future<String> takePhoto();
  void dispose();
}
