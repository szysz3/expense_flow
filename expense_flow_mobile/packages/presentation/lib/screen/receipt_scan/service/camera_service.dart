import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class CameraService {
  CameraController? _controller;
  bool _isInitializing = false;

  static CameraService? _instance;

  CameraService._();

  factory CameraService() {
    _instance ??= CameraService._();
    return _instance!;
  }

  Future<CameraController> initialize() async {
    // If controller is already initialized, return it
    if (_controller?.value.isInitialized ?? false) {
      print('---> CameraService already initialized');
      return _controller!;
    }

    // If initialization is in progress, wait for it
    if (_isInitializing) {
      print('---> CameraService initialization in progress');
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _controller!;
    }

    try {
      _isInitializing = true;
      print('---> CameraService init');

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      await _controller?.dispose();

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
      );

      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      return _controller!;
    } finally {
      _isInitializing = false;
    }
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
    _controller = null;
  }
}
