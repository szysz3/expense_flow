import 'package:camera/camera.dart';
import 'package:presentation/screen/receipt_scan/bloc/receipt_scan_state.dart';

class CameraPreviewWidgetState {
  // TODO: bloc state should NOT be tightly coupled with widget state
  final CameraPreviewState previewState;
  final String? photoPath;
  final CameraController cameraController;

  const CameraPreviewWidgetState({
    required this.previewState,
    this.photoPath,
    required this.cameraController,
  });
}
