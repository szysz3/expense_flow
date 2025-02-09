import 'dart:ui';

abstract class ReceiptScanEvent {}

class InitializeCameraEvent extends ReceiptScanEvent {}

class TakePhotoEvent extends ReceiptScanEvent {}

class CameraButtonPressedEvent extends ReceiptScanEvent {}

class SetFocusPointEvent extends ReceiptScanEvent {
  final Offset point;

  SetFocusPointEvent(this.point);
}

class BackButtonPressedEvent extends ReceiptScanEvent {}
