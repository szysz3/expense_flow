import 'package:camera/camera.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/app_error.dart';

part 'receipt_scan_state.freezed.dart';

abstract class BaseReceiptScanState {}

class ReceiptScanInitState extends BaseReceiptScanState {}

@freezed
class ReceiptScanState extends BaseReceiptScanState with _$ReceiptScanState {
  factory ReceiptScanState({
    required CameraController? controller,
    String? photoPath,
    @Default(CameraPreviewState.idle) CameraPreviewState cameraPreviewState,
    AppError? error,
  }) = _ReceiptScanState;
}

enum CameraPreviewState {
  idle,
  cameraPreview,
  photoPreview,
  photoProcessing,
  loading,
  uploadSuccess,
  uploadFailure,
}
