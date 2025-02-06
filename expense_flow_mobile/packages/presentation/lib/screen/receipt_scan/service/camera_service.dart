import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class CameraService {
  CameraController? _controller;

  Future<CameraController> initialize() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    if (_controller?.value.isInitialized ?? false) {
      await _controller?.dispose();
    }

    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
      enableAudio: false,
    );

    await _controller!.initialize();
    await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

    return _controller!;
  }

  Future<String> takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    final photo = await _controller!.takePicture();
    return photo.path;
  }

  void dispose() {
    _controller?.dispose();
  }
}
