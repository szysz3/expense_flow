import 'package:camera/camera.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_scan_state.freezed.dart';

abstract class BaseReceiptScanState {}

class ReceiptScanInitState extends BaseReceiptScanState {}

@freezed
class ReceiptScanState extends BaseReceiptScanState with _$ReceiptScanState {
  factory ReceiptScanState(
      {required CameraController controller,
      String? photoPath,
      @Default(CameraPreviewState.idle)
      CameraPreviewState cameraPreviewState}) = _ReceiptScanState;
}

@freezed
class ReceiptScanErrorState extends BaseReceiptScanState
    with _$ReceiptScanErrorState {
  factory ReceiptScanErrorState({required String message}) =
      _ReceiptScanErrorState;
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
