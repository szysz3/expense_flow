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
    if (_controller?.value.isInitialized ?? false) {
      print('---> CameraService already initialized');
      return _controller!;
    }

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
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await _controller!.setFocusMode(FocusMode.auto);

      return _controller!;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> setFocusPoint(double x, double y) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      await _controller!.setFocusPoint(Offset(x, y));
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      print('Error setting focus point: $e');
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
