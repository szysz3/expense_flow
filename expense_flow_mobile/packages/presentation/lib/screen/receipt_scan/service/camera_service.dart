import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class CameraService {
  CameraController? _controller;
  bool _isInitializing = false;
  static CameraService? _instance;

  CameraService._();

  factory CameraService() {
    _instance ??= CameraService._();
    return _instance ?? CameraService._();
  }

  Future<CameraController> initialize() async {
    if (_controller?.value.isInitialized ?? false) {
      return _controller ?? await _initializeNewController();
    }

    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _controller ?? await _initializeNewController();
    }

    return await _initializeNewController();
  }

  Future<CameraController> _initializeNewController() async {
    try {
      _isInitializing = true;
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      await _controller?.dispose();

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await controller.setFocusMode(FocusMode.auto);
      await controller.setFlashMode(FlashMode.off);

      _controller = controller;
      return controller;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> setFocusPoint(double x, double y) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      await controller.setFocusPoint(Offset(x, y));
      await controller.setFocusMode(FocusMode.auto);
    } catch (e) {}
  }

  Future<String> takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    final photo = await controller.takePicture();
    return photo.path;
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
