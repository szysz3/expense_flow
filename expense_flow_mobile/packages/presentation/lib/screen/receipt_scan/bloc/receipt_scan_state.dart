import 'package:camera/camera.dart';

abstract class ReceiptScanState {}

class ReceiptScanInitial extends ReceiptScanState {}

class CameraInitialized extends ReceiptScanState {
  final CameraController controller;
  final bool isBlurred;

  CameraInitialized(this.controller, {this.isBlurred = true});
}

class PhotoTaken extends ReceiptScanState {
  final String imagePath;
  PhotoTaken(this.imagePath);
}

class ReceiptScanError extends ReceiptScanState {
  final String message;
  ReceiptScanError(this.message);
}
