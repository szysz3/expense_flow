import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_scan_events.freezed.dart';

@freezed
class ReceiptScanEvent with _$ReceiptScanEvent {
  const factory ReceiptScanEvent.initializeCamera() = InitializeCameraEvent;

  const factory ReceiptScanEvent.takePhoto() = TakePhotoEvent;

  const factory ReceiptScanEvent.cameraButtonPressed() =
      CameraButtonPressedEvent;

  const factory ReceiptScanEvent.setFocusPoint(Offset point) =
      SetFocusPointEvent;

  const factory ReceiptScanEvent.photoRejected() = PhotoRejectedEvent;

  const factory ReceiptScanEvent.photoAccepted() = PhotoAcceptedEvent;

  const factory ReceiptScanEvent.dismissError() = DismissErrorEvent;
}
