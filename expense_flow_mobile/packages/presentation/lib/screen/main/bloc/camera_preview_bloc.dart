import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/service/camera/camera_service.dart';
import 'camera_preview_event.dart';
import 'camera_preview_state.dart';

class CameraPreviewBloc extends Bloc<CameraPreviewEvent, CameraPreviewState> {
  final CameraService _cameraService;

  CameraPreviewBloc(this._cameraService) : super(CameraPreviewInit()) {
    on<InitializeCameraEvent>(_initializeCamera);
  }

  Future<void> _initializeCamera(
    InitializeCameraEvent event,
    Emitter<CameraPreviewState> emit,
  ) async {
    try {
      final controller = await _cameraService.initialize();
      emit(CameraPreviewInitialized(controller));
    } catch (e) {
      emit(CameraInitError('Failed to initialize camera: $e'));
    }
  }

  @override
  Future<void> close() {
    _cameraService.dispose();
    return super.close();
  }
}
